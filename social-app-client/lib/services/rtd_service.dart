import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';

import '../models/CustomClaims.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _firebaseDatabase;

  const RealtimeDatabaseService(this._firebaseDatabase);

  /// Using [userUid] listen to the changes of currentUsers /usersChatRooms/ stream to get the newest [10] entries onChildChanged
  Stream<DatabaseEvent> getUsersChatsStream({required String userUid}) {
    return _firebaseDatabase.ref("usersChatRooms/$userUid/chatRooms").orderByChild("lTime").limitToLast(10).onChildChanged;
  }

  /// Using [userUid] listen to the changes of currentUsers /requestedUsersChatRooms/ stream to get the newest [10] entries onChildChanged
  Stream<DatabaseEvent> getUsersRequestedChatsStream({required String userUid}) {
    return _firebaseDatabase.ref("requestedUsersChatRooms/$userUid/chatRooms").orderByChild("lTime").limitToLast(10).onChildChanged;
  }

  /// Get [10] of the currentUsers /usersChatRooms/ or /requestedUsersChatRooms/ nodes depending on [fromRequestList]
  /// If [lastChatRoomLTime] is 0 then the newest entries will be fetched
  Future<DataSnapshot> getMoreUsersChats({required String userUid, required int lastChatRoomLTime, required bool fromRequestList}) {
    if (lastChatRoomLTime == 0) {
      return _firebaseDatabase
          .ref("${fromRequestList ? 'requestedUsersChatRooms' : 'usersChatRooms'}/$userUid/chatRooms")
          .orderByChild("lTime")
          .limitToLast(10)
          .get();
    } else {
      return _firebaseDatabase
          .ref("${fromRequestList ? 'requestedUsersChatRooms' : 'usersChatRooms'}/$userUid/chatRooms")
          .orderByChild("lTime")
          .limitToLast(10)
          .endBefore(lastChatRoomLTime)
          .get();
    }
  }

  /// Using [userUid] and [chatRoomUid] get [1] of the currentUsers /usersChatRooms/ node
  Future<DataSnapshot> getUsersChatRoom({required String userUid, required String chatRoomUid}) {
    return _firebaseDatabase.ref("usersChatRooms/$userUid/chatRooms/$chatRoomUid").get();
  }

  /// Using [chatRoomUid] get[1] of the /chatRoomsInfos/ node. This is primarily used after /usersChatRooms/ retrives a [chatRoomUid]
  Future<DataSnapshot> getChatRoomsInfo({required String chatRoomUid}) {
    return _firebaseDatabase.ref("chatRoomsInfos/$chatRoomUid").get();
  }

  /// Listen to the newest [17] messages sent to /chatRooms/---[chatRoomUid]/messages
  Stream<DatabaseEvent> getChatRoomMessagesStream(String chatRoomUid) {
    return _firebaseDatabase.ref('chatRooms/$chatRoomUid/messages').orderByChild("sentTime").limitToLast(17).onValue;
  }

  /// Listen to the changes in /chatRooms/---[chatRoomUid]/members/ node to check if the otherUser was blocked
  Stream<DatabaseEvent> getChatRoomsMembersStream(String chatRoomUid) {
    return _firebaseDatabase.ref('chatRooms/$chatRoomUid/members').onValue;
  }

  /// Called when a new request is needed to be created because the [ChatRoomsInfos] object is null.
  Future createNewRequest({required User currentUser, required ChatRoomsInfosMem otherUser, required String msg}) async {
    // Get [CustomClaims] for userName
    CustomClaims claims = await CustomClaims.getClaims(false);
    String? newChatRoomUid = FirebaseDatabase.instance.ref('chatRooms').push().key;
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

  /// When [ChatRoomsInfos] is not null then push a new message to /chatRooms/---[chatRoomUid]/messages.
  /// Also, update the [lTime] for this users /usersChatRooms/---[userUid]/chatRooms/---[chatRoomUid] node and
  /// update the [lTime] and [lMsg] for this chatRooms /chatRoomsInfos/---[chatRoomUid] node
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

  /// When the [fromRequestList] is true in [RTDUsersChatsList] accept the request
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

  /// When [seen] for a /userChatRooms/ or /requestedUsersChatRooms/ node is 0 (meaning false), call this method to set that
  /// nodes seen child as 1 (meaing true) depending on [fromRequestList]
  Future setMessageAsSeen({required String chatRoomUid, required String userUid, required bool fromRequestList}) async {
    final Map<String, dynamic> updates = {};
    if (fromRequestList)
      updates["requestedUsersChatRooms/$userUid/chatRooms/$chatRoomUid/seen"] = 1;
    else
      updates["usersChatRooms/$userUid/chatRooms/$chatRoomUid/seen"] = 1;
    await _firebaseDatabase.ref().update(updates);
  }

  /// When currentUsers /chatRooms/---[chatRoomUid]/members/---currentUserUid/ == true (meaning is not blocked) then the user can user
  /// this method to block the otherUser using [blockedUserUid]
  Future blockInRTDatabase(String chatRoomUid, String blockedUserUid) async {
    final Map<String, dynamic> updates = {};

    /// When /chatRooms/ record is set as FALSE, users will not be able to create new messages in /messages/
    updates['chatRooms/$chatRoomUid/members/$blockedUserUid'] = false;
    await _firebaseDatabase.ref().update(updates);
  }

  /// If the currentUser has blocked the otherUser using [blockedUserUid], then use this method to set the otherUsers blocked/unblocked
  /// value to chatRooms/---[chatRoomUid]/members/---[blockedUserUid] == true (meaning is not blocked)
  Future unBlockInRTDatabase(String chatRoomUid, String blockedUserUid) async {
    final Map<String, dynamic> updates = {};
    updates['chatRooms/$chatRoomUid/members/$blockedUserUid'] = true;
    await _firebaseDatabase.ref().update(updates);
  }
}
