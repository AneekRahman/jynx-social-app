import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream<Event> get getAllChatHisoryStream => _firebaseDatabase
      .reference()
      .child("userChats/---userUid1")
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

  Future sendMessageInRoom(String chatRoomUid, dynamic msgJson) {
    _firebaseDatabase
        .reference()
        .child('chatRooms/$chatRoomUid')
        .push()
        .set(msgJson);
  }

  Future<Map<String, String>> createRequestedUserChats(
      {String currentUsersUid,
      String otherUsersUid,
      String currentUsersName,
      String currentUsersPic}) async {
    try {
      final DatabaseReference newDocumentRef = _firebaseDatabase
          .reference()
          .child('requestedUserChats/$otherUsersUid')
          .push();
      await newDocumentRef.set({
        "lastMsgSentTime": '${new DateTime.now().millisecondsSinceEpoch}',
        "otherUsersUid": currentUsersUid,
        "otherUsersName": currentUsersName,
        "otherUsersPic": currentUsersPic,
        "seen": 0
      });
      return {"status": "success", "chatRoomUid": newDocumentRef.key};
    } catch (e) {
      return {"status": "error", "errorMsg": e.toString()};
    }
  }
}
