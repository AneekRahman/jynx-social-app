import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream<Event> getAllChatHisoryStream() {
    return _firebaseDatabase
        .reference()
        .child("userChats/---userUid1")
        .orderByChild("lastMsgSentTime")
        .limitToLast(10)
        .onValue;
  }
}
