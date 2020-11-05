import 'package:firebase_database/firebase_database.dart';

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
}
