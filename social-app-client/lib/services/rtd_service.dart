import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream getAllChatHisoryStream(String userUid) =>
      _firebaseDatabase.ref().child("userChats/$userUid").orderByChild("lastMsgSentTime").limitToLast(10).onValue;

  Stream getChatRoomStream(String chatRoomUid) {
    return _firebaseDatabase.ref().child('chatRooms/$chatRoomUid').orderByChild("sentTime").limitToLast(10).onValue;
  }

  Future sendMessageInRoom(String chatRoomUid, dynamic msgJson) async {
    await _firebaseDatabase.ref().child('chatRooms/$chatRoomUid').push().set(msgJson);
  }
}
