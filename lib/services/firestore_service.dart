import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/modules/constants.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestoreInstance;
  const FirestoreService(this._firestoreInstance);

  Stream<QuerySnapshot> getUserChatsStream(
      String currentUserUid, requestedChats) {
    return _firestoreInstance
        .collection("userChats")
        .where("members", arrayContains: currentUserUid)
        .orderBy("lastMsgSentTime", descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChatsRequestedStream(
      String currentUserUid, requestedChats) {
    return _firestoreInstance
        .collection("userChats")
        .where("requestedMembers", arrayContains: currentUserUid)
        .orderBy("lastMsgSentTime", descending: true)
        .limit(10)
        .snapshots();
  }

  Future<ChatRow> findPrivateChatWithUser(
      String currentUserUid, String otherUserUid) async {
    try {
      QuerySnapshot snapshots = await _firestoreInstance
          .collection("userChats")
          .where("memberInfo.$currentUserUid.searchable", isEqualTo: true)
          .where("memberInfo.$otherUserUid.searchable", isEqualTo: true)
          .where("type", isEqualTo: "PRIVATE")
          .get();
      if (snapshots.docs.length == 0) return null;
      QueryDocumentSnapshot snapshot = snapshots.docs[0];
      ChatRow chatrow = getChatRowFromDocSnapshot(snapshot, currentUserUid);
      return chatrow;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, String>> createRequestedUserChats({
    MyUserObject otherUserObject,
    User currentUser,
  }) async {
    try {
      CustomClaims claims = await CustomClaims.getClaims(false);
      // Create a new UID
      String chatRoomUid = FirebaseDatabase.instance.reference().push().key;
      // Create a Firestore document
      await _firestoreInstance.collection("userChats").doc(chatRoomUid).set({
        "allMembers": [otherUserObject.userUid, currentUser.uid],
        "members": [currentUser.uid],
        "lastMsgSeenBy": [currentUser.uid],
        "requestedMembers": [otherUserObject.userUid],
        "chatRoomUid": chatRoomUid,
        "lastMsgSentTime": new DateTime.now().millisecondsSinceEpoch.toString(),
        "memberInfo": {
          currentUser.uid: {
            "userName": claims.userName,
            "displayName": currentUser.displayName,
            "profilePic": currentUser.photoURL ?? "",
            "userDeleted": false,
          },
          otherUserObject.userUid: {
            "userName": otherUserObject.userName,
            "displayName": otherUserObject.displayName,
            "profilePic": otherUserObject.profilePic ?? "",
            "userDeleted": false,
          }
        },
        "type": "PRIVATE"
      });

      return {"status": "success", "chatRoomUid": chatRoomUid};
    } catch (e) {
      return {"status": "error", "errorMsg": e.toString()};
    }
  }

  Future setNewMsgUserChatsSeenReset(String userChatsDocumentUid,
      String currentUserUid, String lastMsgSentTime) async {
    await _firestoreInstance
        .collection("userChats")
        .doc(userChatsDocumentUid)
        .update({
      "lastMsgSeenBy": [currentUserUid],
      "lastMsgSentTime": lastMsgSentTime
    });
  }

  Future setSeenUserChatsDocument(
      String userChatsDocumentUid, String currentUserUid) async {
    print("Should fire seen chat on chatroom open");
    await _firestoreInstance
        .collection("userChats")
        .doc(userChatsDocumentUid)
        .update({
      "lastMsgSeenBy": FieldValue.arrayUnion([currentUserUid]),
    });
  }

  Future acceptChatUserRequest(
      String userChatsDocumentUid, String currentUserUid) async {
    await _firestoreInstance
        .collection("userChats")
        .doc(userChatsDocumentUid)
        .update({
      "members": FieldValue.arrayUnion([currentUserUid]),
      "requestedMembers": FieldValue.arrayRemove([currentUserUid]),
    });
  }

  Future blockUser({
    String userChatsDocumentUid,
    String currentUserUid,
    String blockedUserUid,
  }) async {
    await _firestoreInstance
        .collection("users")
        .doc(currentUserUid)
        .collection("blockedUsers")
        .add({
      "blockedUserUid": blockedUserUid,
      "time": new DateTime.now().millisecondsSinceEpoch.toString(),
    });

    if (userChatsDocumentUid != null) {
      // Remove from members or requestedMembers and add a list of users who have blocked this chat
      await _firestoreInstance
          .collection("userChats")
          .doc(userChatsDocumentUid)
          .update({
        "members": FieldValue.arrayRemove([currentUserUid]),
        "requestedMembers": FieldValue.arrayRemove([currentUserUid]),
        "chatBlockedByUsers": [currentUserUid]
      });
    }
  }
}
