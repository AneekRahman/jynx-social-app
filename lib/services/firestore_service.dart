import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:uuid/uuid.dart';

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

  Future<String> findPrivateChatWithUser(
      String currentUserUid, String otherUserUid) async {
    try {
      print("Array contains: $currentUserUid and $otherUserUid");
      QuerySnapshot snapshot = await _firestoreInstance
          .collection("userChats")
          .where("memberInfo.$currentUserUid.userDeleted", isEqualTo: false)
          .where("memberInfo.$otherUserUid.userDeleted", isEqualTo: false)
          .where("type", isEqualTo: "PRIVATE")
          .get();
      if (snapshot.docs.length > 0) return snapshot.docs[0].get("chatRoomUid");
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, String>> createRequestedUserChats({
    MyUserObject otherUserObject,
    User currentUser,
  }) async {
    try {
      Map claims = await AuthenticationService.currentUserClaims(false);
      String chatRoomUid = Uuid().v1();
      // Create a Firestore document
      await FirebaseFirestore.instance.collection("userChats").add({
        "allMembers": [otherUserObject.userUid, currentUser.uid],
        "members": [currentUser.uid],
        "lastMsgSeenBy": [currentUser.uid],
        "requestedMembers": [otherUserObject.userUid],
        "chatRoomUid": chatRoomUid,
        "lastMsgSentTime": new DateTime.now().millisecondsSinceEpoch.toString(),
        "memberInfo": {
          currentUser.uid: {
            "userName": claims["userName"],
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
}
