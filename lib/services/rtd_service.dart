import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/modules/constants.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream<Event> getAllChatHisoryStream(String userUid) => _firebaseDatabase
      .reference()
      .child("userChats/$userUid")
      .orderByChild("lastMsgSentTime")
      .limitToLast(10)
      .onValue;

  Stream<Event> getChatRoomStream(String chatRoomUid) {
    return _firebaseDatabase
        .reference()
        .child('chatRooms/$chatRoomUid')
        .orderByChild("sentTime")
        .limitToLast(15)
        .onValue;
  }

  Future sendMessageInRoom(String chatRoomUid, dynamic msgJson) async {
    await _firebaseDatabase
        .reference()
        .child('chatRooms/$chatRoomUid')
        .push()
        .set(msgJson);
  }

  Future<Map<String, String>> createRequestedUserChats({
    MyUserObject otherUserObject,
    User currentUser,
  }) async {
    try {
      final DatabaseReference otherUsersRequestedChats = _firebaseDatabase
          .reference()
          .child('requestedUserChats/${otherUserObject.userUid}')
          .push();
      // Create a document in the requestedUserChats for the user that the first msg is sent to
      await otherUsersRequestedChats.set({
        "lastMsgSentTime": new DateTime.now().millisecondsSinceEpoch,
        "otherUsersUid": currentUser.uid,
        "otherUsersName": currentUser.displayName,
        "otherUsersPic": currentUser.photoURL,
        "roomType": 0,
        "seen": 0
      });
      // Create a document in the main chats for the current user
      final DatabaseReference currentUsersChat = _firebaseDatabase
          .reference()
          .child('userChats/${currentUser.uid}')
          .push();
      // Create a document in the requestedUserChats for the user that the first msg is sent to
      await currentUsersChat.set({
        "lastMsgSentTime": new DateTime.now().millisecondsSinceEpoch,
        "otherUsersUid": otherUserObject.userUid,
        "otherUsersName": otherUserObject.displayName,
        "otherUsersPic": otherUserObject.profilePic,
        "roomType": 0,
        "seen": 1
      });
      // Lastly create a oneOnOneChats record so that on search the chatRoomUid is found
      String chatRoomUid =
          getOneOnOneChatUid(currentUser.uid, otherUserObject.userUid);
      await _firebaseDatabase
          .reference()
          .child('oneOnOneChats/$chatRoomUid')
          .set({"chatRoomUid": currentUsersChat.key});
      return {"status": "success", "chatRoomUid": currentUsersChat.key};
    } catch (e) {
      return {"status": "error", "errorMsg": e.toString()};
    }
  }

  Future searchForOneOnOneChatRoom(userUid1, userUid2) async {
    String chatRoomUid = getOneOnOneChatUid(userUid1, userUid2);
    DataSnapshot snapshot = await _firebaseDatabase
        .reference()
        .child("oneOnOneChats/$chatRoomUid")
        .once();
    if (snapshot.value != null) {
      return snapshot.value["chatRoomUid"];
    } else {
      return null;
    }
  }
}
