import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream getChatRoomMessagesStream(String chatRoomUid) {
    return _firebaseDatabase.ref().child('chatRooms/$chatRoomUid/messages').orderByChild("sentTime").limitToLast(10).onValue;
  }

  Future sendMessageInRoom(String chatRoomUid, dynamic msgJson, firstMessage, members) async {
    if (firstMessage) {
      String? messageUid = FirebaseDatabase.instance.ref().push().key;
      await _firebaseDatabase.ref().child('chatRooms/$chatRoomUid').set({
        "members": members,
        "messages": {messageUid: msgJson}
      });
    } else {
      await _firebaseDatabase.ref().child('chatRooms/$chatRoomUid/messages').push().set(msgJson);
    }
  }
}
