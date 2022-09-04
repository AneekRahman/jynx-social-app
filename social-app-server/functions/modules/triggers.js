const functions = require("firebase-functions");
const admin = require("firebase-admin");
const _ = require("lodash");

/* ------------ FIRESTORE TRIGGERS ------------ */

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

/* ------------- PUBSUB CRON JOBS ------------- */

// ---------- (Upto 3 Pub/Sub jobs are free on Google Cloud) ----------

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
  .schedule("every 7 minutes")
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

// const compressProfilePictureHandler = async (object) => {
//   // Once the thumbnail has been uploaded delete the local file to free up disk space.
//   const filePath = object.name; // File path in the bucket.
//   const fileName = path.basename(filePath); // Get the file name.
//   const fileBucket = object.bucket; // The Storage bucket that contains the file.
//   const contentType = object.contentType; // File content type.
//   const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.

//   // Exit if this is triggered on a file that is not an image.
//   if (!contentType.startsWith("image/")) return;

//   // Exit if the image file is not a profile picture image or if it was already compressed
//   if (
//     !fileName.startsWith("profile-picture") ||
//     fileName.startsWith("compressed_profile-picture")
//   )
//     return;

//   const bucket = admin.storage().bucket(fileBucket);
//   const tempFilePath = path.join(os.tmpdir(), fileName);
//   const metadata = {
//     contentType: contentType,
//     cacheControl: "public,max-age=31535000",
//   };

//   try {
//     // Make a small dp for the users uploaded image
//     // Download file from bucket.
//     await bucket.file(filePath).download({ destination: tempFilePath });

//     // Generate a compressed image using ImageMagick.
//     await spawn("convert", [tempFilePath, "-resize", "600x600>", tempFilePath]);

//     // We add a 'compressed_' prefix to profile picture file name. That's where we'll upload the new image.
//     const finalProPicName = `compressed_${fileName}`;
//     const finalProPicPath = path.join(path.dirname(filePath), finalProPicName);
//     // Uploading the thumbnail.
//     await bucket.upload(tempFilePath, {
//       destination: finalProPicPath,
//       metadata: metadata,
//     });
//   } catch (error) {
//     throw error;
//   }

//   // Once the thumbnail has been uploaded delete the local file to free up disk space.
//   fs.unlinkSync(tempFilePath);
// };

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
