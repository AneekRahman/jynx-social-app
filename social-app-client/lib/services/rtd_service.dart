import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UserFirestore.dart';

import '../models/CustomClaims.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  Stream<DatabaseEvent> getUsersChatsStream({required userUid}) {
    return _firebaseDatabase.ref("usersChatRooms").child(userUid).child("chatRooms").orderByChild("lTime").limitToLast(10).onValue;
  }

  Stream<DatabaseEvent> getUsersRequestedChatsStream({required userUid}) {
    return _firebaseDatabase.ref("requestedUsersChatRooms").child(userUid).child("chatRooms").orderByChild("lTime").limitToLast(10).onValue;
  }

  Future<DataSnapshot> getChatRoomsInfoPromise({required chatRoomUid}) {
    return _firebaseDatabase.ref("chatRoomsInfos").child(chatRoomUid).get();
  }

  Stream<DatabaseEvent> getChatRoomMessagesStream(String chatRoomUid) {
    return _firebaseDatabase.ref().child('chatRooms/$chatRoomUid/messages').orderByChild("sentTime").limitToLast(10).onValue;
  }

  Stream<DatabaseEvent> getChatRoomsMembersStream(String chatRoomUid) {
    return _firebaseDatabase.ref().child('chatRooms/$chatRoomUid/members').onValue;
  }

  /// Called when a new request is needed to be created because the [ChatRoomsInfos] object is null.
  Future createNewRequest({required User currentUser, required ChatRoomsInfosMem otherUser, required String msg}) async {
    // Get [CustomClaims] for userName
    CustomClaims claims = await CustomClaims.getClaims(false);
    String? newChatRoomUid = FirebaseDatabase.instance.ref().child("chatRooms").push().key;
    int lTime = new DateTime.now().millisecondsSinceEpoch;

    Map<String, Object?> updates = {};

    // Create a /contacts/ record in  currentUsers /usersInfos/ node.
    // If currentUser already has a contact (Private chat) with otherUser, this will be denied
    updates["usersInfos/${currentUser.uid}/contacts/${otherUser.userUid}"] = newChatRoomUid;

    // Create a record for this new chatRoom in the users own chatList
    updates["usersChatRooms/${currentUser.uid}/chatRooms/$newChatRoomUid"] = {
      "lTime": lTime,
      "seen": 1,
    };

    /// Use triggers to add this chatRoom to /requestedUsersChatRooms/ of the other user
    // updates["requestedUsersChatRooms/${otherUser.userUid}/chatRooms/$newChatRoomUid"] = {
    //   "lTime": lTime,
    //   "seen": 0,
    // };
    // Save the information about this chatRoom in Realtime Database
    updates["chatRoomsInfos/$newChatRoomUid"] = {
      "grp": false,
      "lMsg": msg.length > 40 ? msg.substring(0, 40) : msg.substring(0, msg.length),
      "lTime": lTime,
      "mems": {
        currentUser.uid: {
          "name": currentUser.displayName,
          "uName": claims.userName,
          "url": currentUser.photoURL,
        },
        otherUser.userUid: {
          "name": otherUser.name,
          "uName": otherUser.uName,
          "url": otherUser.url,
        }
      }
    };
    // Lastly, push a new message to the chatRooms
    updates["chatRooms/$newChatRoomUid"] = {
      "members": {
        currentUser.uid: true,
        otherUser.userUid: true,
      },
      "messages": {
        FirebaseDatabase.instance.ref().push().key: {
          "msg": msg,
          "sentTime": lTime,
          "userUid": currentUser.uid,
        }
      }
    };

    await _firebaseDatabase.ref().update(updates);

    // Return the [newChatRoomUid] so that it can be updated in the [ChatMessageRoom]
    return newChatRoomUid;
  }

  Future<void> sendMessageInRoom({
    required String chatRoomUid,
    required String msg,
    required String userUid,
  }) async {
    int lTime = new DateTime.now().millisecondsSinceEpoch;
    String? newMsgUid = FirebaseDatabase.instance.ref().child("chatRooms").push().key;
    Map<String, Object?> updates = {};

    // First, show this new chatRoom in the users own chatList
    updates["usersChatRooms/$userUid/chatRooms/$chatRoomUid"] = {
      "lTime": lTime,
      "seen": 1,
    };

    // Update the [lMsg] and [lTime] in the /chatRoomsInfos/ and let the trigger update the /userChatRooms/ or /requestedUsersChatRooms/
    updates["chatRoomsInfos/$chatRoomUid/lMsg"] = msg.length > 40 ? msg.substring(0, 40) : msg.substring(0, msg.length);
    updates["chatRoomsInfos/$chatRoomUid/lTime"] = lTime;

    // Lastly, push a new message to the chatRooms
    updates["chatRooms/$chatRoomUid/messages/$newMsgUid"] = {
      "msg": msg,
      "sentTime": lTime,
      "userUid": userUid,
    };

    await _firebaseDatabase.ref().update(updates);
  }

  Future acceptChatRequest({
    required String chatRoomUid,
    required String currentUserUid,
    required String otherUserUid,
  }) async {
    /// Remove from currentUsers /requestedUsersChatRooms/ list
    await _firebaseDatabase.ref("requestedUsersChatRooms/$currentUserUid/chatRooms/$chatRoomUid").remove();

    /// Create add to users /usersInfos/contacts/ list
    await _firebaseDatabase.ref("usersInfos/$currentUserUid/contacts/$otherUserUid").set(chatRoomUid);
  }

  Future setMessageAsSeen({required String chatRoomUid, required String userUid, required bool fromRequestList}) async {
    final Map<String, dynamic> updates = {};
    if (fromRequestList)
      updates["requestedUsersChatRooms/$userUid/chatRooms/$chatRoomUid/seen"] = 1;
    else
      updates["usersChatRooms/$userUid/chatRooms/$chatRoomUid/seen"] = 1;
    await _firebaseDatabase.ref().update(updates);
  }

  Future blockInRTDatabase(String chatRoomUid, String blockedUserUid) async {
    final Map<String, dynamic> updates = {};

    /// When /chatRooms/ record is set as FALSE, users will not be able to create new messages in /messages/
    updates['/chatRooms/$chatRoomUid/members/$blockedUserUid'] = false;
    await _firebaseDatabase.ref().update(updates);
  }

  Future unBlockInRTDatabase(String chatRoomUid, String blockedUserUid) async {
    final Map<String, dynamic> updates = {};
    updates['/chatRooms/$chatRoomUid/members/$blockedUserUid'] = true;
    await _firebaseDatabase.ref().update(updates);
  }
}
