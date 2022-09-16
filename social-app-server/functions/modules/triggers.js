const functions = require("firebase-functions");
const admin = require("firebase-admin");
const _ = require("lodash");

/* ------------ FIRESTORE TRIGGERS (START) ------------ */

exports.onUserUpdated = functions.firestore
  .document("users/{userUid}")
  .onUpdate(async (change, context) => {
    const userUid = context.params.userUid;
    const userDataBefore = change.before.data();
    const userDataAfter = change.after.data();

    // if photoURL(only if the oldPhotoURL = "") and displayName changes are detected
    if (
      (userDataBefore.photoURL === "" && userDataAfter.photoURL !== "") ||
      userDataBefore.photoURL !== userDataAfter.photoURL ||
      userDataBefore.displayName !== userDataAfter.displayName ||
      userDataBefore.userName !== userDataAfter.userName
    ) {
      // Make updatedInfoUsers cron jobs for
      await admin.firestore().collection("updatedInfoUsers").doc(userUid).set({
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      return await admin
        .firestore()
        .collection("users")
        .doc(userUid)
        .update({
          searchKeywords: [
            ...createKeywords(userDataAfter.userName.toLowerCase()),
            ...createKeywords(userDataAfter.displayName.toLowerCase()),
          ],
        });
    } else {
      return Promise.resolve();
    }
  });

exports.onChatRoomsInfosCreated = functions.database
  .ref("/chatRoomsInfos/{chatRoomUid}")
  .onCreate((snapshot, context) => {
    // Grab the current value of what was written to the Realtime Database.
    const chatRoomsInfosData = snapshot.val();
    const chatRoomUid = context.params.chatRoomUid;

    /// When this [chatRoomsInfos] is a private chat
    if (chatRoomsInfosData.grp === false && chatRoomsInfosData.mems) {
      let _otherUsersUserUid;
      for (const userUid in chatRoomsInfosData.mems) {
        /// Meaning this is not the one that created the new chatRoom
        if (userUid !== context.auth.uid) _otherUsersUserUid = userUid;
      }

      if (_otherUsersUserUid) {
        return admin
          .database()
          .ref(
            `requestedUsersChatRooms/${_otherUsersUserUid}/chatRooms/${chatRoomUid}`
          )
          .set({
            lTime: Date.now(),
            seen: 0,
          });
      }
    }
    return Promise.resolve();
  });

exports.onMessageAdded = functions.database
  .ref("/chatRooms/{chatRoomUid}/messages/{msgUid}")
  .onCreate(async (snapshot, context) => {
    // NOTE: This will work for both Group and Private chats

    // Grab the current value of what was written to the Realtime Database.
    const chatRoomUid = context.params.chatRoomUid;
    const msgData = snapshot.val();

    // First get the other chatRoomsInfosMems from /chatRoomsInfos/ to know who to update the lTime for
    const chatRoomInfosMemsSnapshot = await admin
      .database()
      .ref(`chatRoomsInfos/${chatRoomUid}/mems`)
      .get();

    // Check if the chatRoomsInfos exists
    if (chatRoomInfosMemsSnapshot.exists()) {
      const infosMemsData = chatRoomInfosMemsSnapshot.val();

      // If the other user didn't accept the request this array will be empty and nothing will be updated
      const toBeUpdatedPromises = [];

      // Loop through the chatRoomsInfosMems to get each users userUid
      for (const infoMemsUserUid in infosMemsData) {
        // When this is not the currentUsers userUid, and otherUser has accepted the request [acc] = 1
        // then we have to update these users / usersChatRooms / node
        if (
          infoMemsUserUid !== context.auth.uid &&
          infosMemsData[infoMemsUserUid].acc === 1
        ) {
          const updatePromise = admin
            .database()
            .ref(`usersChatRooms/${infoMemsUserUid}/chatRooms/${chatRoomUid}`)
            .update({
              lTime: msgData.sentTime,
              seen: 0,
            });
          // To Update otherUsers /usersChatRooms/ node
          toBeUpdatedPromises.push(updatePromise);
          // To send the otherUser a push notification
          toBeUpdatedPromises.push(
            sendNewMsgNotification(
              context.auth.uid,
              infoMemsUserUid,
              "New: " + msgData.msg.slice(0, 30)
            )
          );
        }
      }

      // If the /usersChatRooms/ node don't exist, this will be empty
      return Promise.all(toBeUpdatedUsersChatRooms);
    }
  });

const sendNewMsgNotification = async (currentUserUid, otherUserUid, body) => {
  // Get currentUser for displayName
  const currentUser = await admin.auth().getUser(currentUserUid);

  // Get the fcmToken for this user
  const otherUsersInfoSnapshot = await admin
    .database()
    .ref(`usersInfos/${otherUserUid}/fcmToken/token`)
    .get();

  if (otherUsersInfoSnapshot.exists() && currentUser.displayName) {
    const message = {
      token: otherUsersInfoSnapshot.val(),
      notification: {
        title: currentUser.displayName,
        body,
      },
      android: {
        priority: "high",
      },
    };

    await admin
      .messaging()
      .send(message)
      .catch((error) => {
        console.log("Error sending FCM message:", error);
      });
  } else {
    return Promise.resolve();
  }
};

exports.onCallIncoming = functions.database
  .ref("/chatRoomsInfos/{chatRoomUid}/incomingCall")
  .onCreate(async (snapshot, context) => {
    const chatRoomUid = context.params.chatRoomUid;
    const incomingCallData = snapshot.val();

    const chatRoomInfosSnapshot = await admin
      .database()
      .ref(`chatRoomsInfos/${chatRoomUid}`)
      .get();

    // Calls only work if this is a Private chat
    if (
      chatRoomInfosSnapshot.exists() &&
      chatRoomInfosSnapshot.val()["grp"] === false
    ) {
      const chatRoomInfosData = chatRoomInfosSnapshot.val();

      // Look into chatRoomInfoMems for otherUser of this Private chat
      if (chatRoomInfosData.mems !== null) {
        for (const infoMemsUserUid in infosMemsData) {
          // Calls can only go through when the user has accepted the request meaning [acc] = 1
          if (
            infoMemsUserUid !== context.auth.uid &&
            infosMemsData[infoMemsUserUid].acc === 1
          ) {
            // TODO Send the call fcm data payload notifcaiton
          }
        }
      }
    }
  });

/* ------------ FIRESTORE TRIGGERS (END) ------------ */

/* ------------- PUBSUB CRON JOBS (START) ------------- */

// ---------- (Upto 3 Pub/Sub jobs are free on Google Cloud) ----------

// TODO Update this
const updateUsersAllChats = async (userUid) => {
  const userDoc = await admin
    .firestore()
    .collection("users")
    .doc(userUid)
    .get();
  const userData = userDoc.data();

  const usersChats = await admin
    .firestore()
    .collection("userChats")
    .where("allMembers", "array-contains", userUid)
    .get();

  const batches = _.chunk(usersChats.docs, 500).map((chats) => {
    const newValues = {
      memberInfo: {},
    };
    newValues.memberInfo[userUid] = {
      displayName: userData["displayName"],
      photoURL: userData["photoURL"],
      userName: userData["userName"],
    };
    const batch = admin.firestore().batch();
    chats.forEach((doc) => {
      batch.set(doc.ref, newValues, { merge: true });
    });
    return batch.commit();
  });

  await Promise.all(batches);
};

exports.UserChatsInfoUpdateCron = functions.pubsub // .runWith({ memory: "1GB" })
  .schedule("every 10 minutes")
  .onRun(async (context) => {
    // Loop through all documents in the collections (updatedUsers)
    admin
      .firestore()
      .collection("updatedInfoUsers")
      .get()
      // First loop through and update all the users posts in updatedInfoUsers
      .then((snapshot) => {
        return snapshot.forEach((document) => {
          document.ref.delete();
          updateUsersAllChats(document.id);
        });
      })
      .catch((error) => {
        throw error;
      });
  });

/* ------------- PUBSUB CRON JOBS (END) ------------- */

// My Non API Functions -----------------------

const createKeywords = (text) => {
  let keywordsList = [];
  // Split the text into words if there are spaces
  text.split(" ").forEach((word) => {
    let tempWord = "";
    word.split("").forEach((letter) => {
      tempWord += letter;
      if (!keywordsList.includes(tempWord)) keywordsList.push(tempWord);
    });
  });
  return keywordsList;
};
