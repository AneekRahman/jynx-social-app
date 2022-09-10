import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdDatabase;
import 'package:flutter/material.dart';

import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/rtd_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestoreInstance;
  const FirestoreService(this._firestoreInstance);

  Stream<DocumentSnapshot> getUserDocumentStream(String userUid) {
    return _firestoreInstance.collection("users").doc(userUid).snapshots();
    // return MyUserObject.fromJson(snapshot.data());
  }

  Future<QuerySnapshot> getNewChatListChats({QueryDocumentSnapshot? lastDocument, required String currentUserUid}) {
    Query query;
    // If searchKey is empty, serially get the products
    query = _firestoreInstance
        .collection("userChats")
        .where("members", arrayContains: currentUserUid)
        .orderBy("lastMsgSentTime", descending: true)
        .limit(Constants.CHAT_LIST_READ_LIMIT);

    if (lastDocument != null) {
      query = _firestoreInstance
          .collection("userChats")
          .where("members", arrayContains: currentUserUid)
          .orderBy("lastMsgSentTime", descending: true)
          .limit(Constants.CHAT_LIST_READ_LIMIT)
          .startAfterDocument(lastDocument);
    }

    return query.get();
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomUid) {
    return _firestoreInstance.collection("userChats").doc(chatRoomUid).snapshots();
  }

  Stream<QuerySnapshot> getUserChatsStream(String currentUserUid, requestedChats) {
    return _firestoreInstance
        .collection("userChats")
        .where("members", arrayContains: currentUserUid)
        .orderBy("lastMsgSentTime", descending: true)
        .limit(Constants.CHAT_LIST_READ_LIMIT)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChatsRequestedStream(String currentUserUid, requestedChats) {
    return _firestoreInstance
        .collection("userChats")
        .where("requestedMembers", arrayContains: currentUserUid)
        .orderBy("lastMsgSentTime", descending: true)
        .limit(Constants.CHAT_LIST_READ_LIMIT)
        .snapshots();
  }

  /// Use the [currentUserUid] and [otherUserUid] to find a commonly shared private message in Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> findPrivateChatWithUser(String currentUserUid, String otherUserUid) async {
    return _firestoreInstance
        .collection("chatRoomRecords")
        .where("isGroup", isEqualTo: false)
        .where("members", whereIn: [currentUserUid, otherUserUid]).get();
  }

  Future createRequestedUserChats({
    required UserFirestore otherUserObject,
    required User currentUser,
    required String lastMsg,
  }) async {
    CustomClaims claims = await CustomClaims.getClaims(false);

    String? chatRoomUid = rtdDatabase.FirebaseDatabase.instance.ref().push().key;
    await _firestoreInstance.collection("userChats").doc(chatRoomUid).set({
      "allMembers": [otherUserObject.userUid, currentUser.uid], // Requested + Accepted members
      "requestedMembers": [otherUserObject.userUid], // Requested members
      "members": [currentUser.uid], // Accepted members
      "blockedMembers": [],
      "lastMsgSeenBy": [currentUser.uid], // Last msg seen by which of the users
      "lastMsgSentTime": new DateTime.now().millisecondsSinceEpoch.toString(),
      "lastMsg": lastMsg,
      "type": ChatType.PRIVATE, // PRIVATE or GROUP
      "memberInfo": {
        currentUser.uid: {
          "userName": claims.userName,
          "displayName": currentUser.displayName,
          "photoURL": currentUser.photoURL ?? "",
          "searchable": true,
        },
        otherUserObject.userUid: {
          "userName": otherUserObject.userName,
          "displayName": otherUserObject.displayName,
          "photoURL": otherUserObject.photoURL ?? "",
          "searchable": true,
        }
      },
    });
    return chatRoomUid;
  }

  Future createNewChatRoomRecords({required String chatRoomUid, required bool isGroup, required List<String> members}) async {
    await _firestoreInstance.collection("chatRoomRecords").doc(chatRoomUid).set({
      "isGroup": isGroup,
      "members": members,
    });
  }

  Future setNewMsgUserChatsSeenReset(
    String userChatsDocumentUid,
    String currentUserUid,
    String lastMsgSentTime,
    String lastMsg,
  ) async {
    await _firestoreInstance.collection("userChats").doc(userChatsDocumentUid).update({
      "lastMsgSeenBy": [currentUserUid],
      "lastMsgSentTime": lastMsgSentTime,
      "lastMsg": lastMsg
    });
  }

  Future setSeenUserChatsDocument(String userChatsDocumentUid, String currentUserUid) async {
    print("Should fire seen chat on chatroom open");
    await _firestoreInstance.collection("userChats").doc(userChatsDocumentUid).update({
      "lastMsgSeenBy": FieldValue.arrayUnion([currentUserUid]),
    });
  }

  Future acceptChatUserRequest(
      RealtimeDatabaseService rtdDatabase, String userChatsDocumentUid, String currentUserUid, String otherUserUid) async {
    await _firestoreInstance.collection("userChats").doc(userChatsDocumentUid).update({
      "members": FieldValue.arrayUnion([currentUserUid, otherUserUid]),
      "blockedMembers": FieldValue.arrayRemove([otherUserUid]),
      "requestedMembers": FieldValue.arrayRemove([currentUserUid]),
    });
    // In Unblock in Database just in case
    await rtdDatabase.unBlockInRTDatabase(userChatsDocumentUid, otherUserUid);
  }

  Future blockUser({required String userChatsDocumentUid, required String blockedUserUid}) async {
    await _firestoreInstance.collection("userChats").doc(userChatsDocumentUid).update({
      "blockedMembers": FieldValue.arrayUnion([blockedUserUid]),
    });
  }

  Future unblockUser({required String userChatsDocumentUid, required String blockedUserUid}) async {
    await _firestoreInstance.collection("userChats").doc(userChatsDocumentUid).update({
      "blockedMembers": FieldValue.arrayRemove([blockedUserUid]),
    });
  }

  Future updateUser(User user, newValues) async {
    // Try to Save the /users/ and /takenUserNames/ documents
    await _firestoreInstance.collection("users").doc(user.uid).update(newValues);
  }
}
