import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestoreInstance;
  const FirestoreService(this._firestoreInstance);

  Stream<DocumentSnapshot> getUserDocumentStream(String userUid) {
    return _firestoreInstance.collection("users").doc(userUid).snapshots();
  }

  Future<DocumentSnapshot> getUserDocument(String userUid) {
    return _firestoreInstance.collection("users").doc(userUid).get();
  }

  Future updateUser(User user, newValues) async {
    // Try to Save the /users/ and /takenUserNames/ documents
    await _firestoreInstance.collection("users").doc(user.uid).update(newValues);
  }

  /// Use the [currentUserUid] and [otherUserUid] to find a commonly shared private message in Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> findPrivateChatWithUser(String currentUserUid, String otherUserUid) async {
    return _firestoreInstance
        .collection("chatRoomRecords")
        .where("members.$currentUserUid", isEqualTo: true)
        .where("members.$otherUserUid", isEqualTo: true)
        .where("isGroup", isEqualTo: false)
        .get();
  }

  Future createNewChatRoomRecords({
    required String chatRoomUid,
    required bool isGroup,
    required String currentUserUid,
    required String otherUserUid,
  }) async {
    /// Create a chatRoomRecord so that the Private [chatRoomUid] for 2 users can be found after querying
    /// after [ChatMessageRoom] is initializaed with [chatRoomsInfos]
    await _firestoreInstance.collection("chatRoomRecords").doc(chatRoomUid).set({
      "isGroup": isGroup,
      "members": {
        currentUserUid: true, // True means this user is not blocked by the other user
        otherUserUid: true, // False means this user is blocked by the other user
      },
    });
  }
}
