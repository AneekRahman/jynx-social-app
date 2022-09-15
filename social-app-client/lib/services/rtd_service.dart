import 'dart:math';

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
  Future<DatabaseEvent> getMoreUsersChats({required String userUid, required int lastChatRoomLTime, required bool fromRequestList}) {
    if (lastChatRoomLTime == 0) {
      return _firebaseDatabase
          .ref("${fromRequestList ? 'requestedUsersChatRooms' : 'usersChatRooms'}/$userUid/chatRooms")
          .orderByChild("lTime")
          .limitToLast(10)
          .once(DatabaseEventType.value);
    } else {
      return _firebaseDatabase
          .ref("${fromRequestList ? 'requestedUsersChatRooms' : 'usersChatRooms'}/$userUid/chatRooms")
          .orderByChild("lTime")
          .limitToLast(10)
          .endBefore(lastChatRoomLTime)
          .once(DatabaseEventType.value);
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
    // TODO encrypt the lMsg only

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
      "lMsg": msg,
      "mems": {
        currentUser.uid: {
          "name": currentUser.displayName,
          "uName": claims.userName,
          "url": currentUser.photoURL,
          "acc": 1,
        },
        otherUser.userUid: {
          "name": otherUser.name,
          "uName": otherUser.uName,
          "url": otherUser.url,
          "acc": 0,
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
    // TODO encrypt the msg and the userUid before saving it to the server
    int lTime = new DateTime.now().millisecondsSinceEpoch;
    String? newMsgUid = FirebaseDatabase.instance.ref().child("chatRooms").push().key;
    Map<String, Object?> updates = {};

    // First, show this new chatRoom in the users own chatList
    updates["usersChatRooms/$userUid/chatRooms/$chatRoomUid"] = {
      "lTime": lTime,
      "seen": 1,
    };

    // Update the [lMsg] in the /chatRoomsInfos/ and let the trigger update the /userChatRooms/ or /requestedUsersChatRooms/
    updates["chatRoomsInfos/$chatRoomUid/lMsg"] = msg;

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
    final Map<String, dynamic> updates = {};

    /// Remove from currentUsers /requestedUsersChatRooms/ list
    updates["requestedUsersChatRooms/$currentUserUid/chatRooms/$chatRoomUid"] = null;

    /// Create add to users /usersInfos/contacts/ list
    updates["usersInfos/$currentUserUid/contacts/$otherUserUid"] = chatRoomUid;

    // Set the [acc] = 1 for /chatRoomsInfos/mems/[currentUserUid]/
    updates["chatRoomsInfos/$chatRoomUid/mems/$currentUserUid/acc"] = 1;

    await _firebaseDatabase.ref().update(updates);
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

  Future createOwnP2PQueueNode({required String userUid}) async {
    final Map<String, dynamic> updates = {};
    updates['p2pCallQueue/worldwide/$userUid/'] = {
      "occ": new DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _firebaseDatabase.ref().update(updates);

    // Make sure this queue is deleted when user disconnects (if user closes the app from the RandomVideoCallPage)
    await _firebaseDatabase.ref("p2pCallQueue/worldwide/$userUid").onDisconnect().remove();
  }

  Stream<DatabaseEvent> getOwnP2PQueueStream({required String userUid}) {
    return _firebaseDatabase.ref("p2pCallQueue/worldwide/$userUid").onChildChanged;
  }

  Future acceptOthersP2PQueueNode({required String currentUserUid, required String otherUserUid, required String answer}) async {
    final Map<String, dynamic> updates = {};
    updates['p2pCallQueue/worldwide/$currentUserUid/occ'] = -1;
    updates['p2pCallQueue/worldwide/$currentUserUid/occBy'] = otherUserUid;
    updates['p2pCallQueue/worldwide/$otherUserUid/occ'] = -1;
    updates['p2pCallQueue/worldwide/$otherUserUid/occBy'] = currentUserUid;
    await _firebaseDatabase.ref().update(updates);
  }

  Future deleteP2PQueue({required String currentUserUid}) async {
    await _firebaseDatabase.ref('p2pCallQueue/worldwide/$currentUserUid').remove();
  }

  Future<DataSnapshot> getRandomP2PQueue() async {
    final int min = 1663150753; // Set as the smallest value in /p2pCallQueue/worldwide/
    final int max = new DateTime.now().millisecondsSinceEpoch ~/ 1000; // In seconds
    final int startAt = ((new Random().nextDouble() * (max - min)) + min).toInt();

    // Randomly select limitToFirst or limitToLast
    final bool shouldBeLimitToFirst = new Random().nextInt(2) == 0;

    Future<DataSnapshot> queueQuery1 =
        _firebaseDatabase.ref('p2pCallQueue/worldwide').orderByChild('occ').startAt(startAt).endAt(max).limitToFirst(1).get();
    Future<DataSnapshot> queueQuery2 =
        _firebaseDatabase.ref('p2pCallQueue/worldwide').orderByChild('occ').startAt(min).endAt(startAt).limitToLast(1).get();

    if (shouldBeLimitToFirst) {
      DataSnapshot queueSnapshot1 = await queueQuery1;
      if (queueSnapshot1.exists) {
        return queueSnapshot1;
      } else {
        // If no query exists for queueQuery1, try queueQuery2
        return await queueQuery2;
      }
    } else {
      DataSnapshot queueSnapshot2 = await queueQuery2;
      if (queueSnapshot2.exists) {
        return queueSnapshot2;
      } else {
        // If no query exists for queueQuery2, try queueQuery1
        return await queueQuery1;
      }
    }
  }

  Future transactionP2PAnswer({required DataSnapshot randomQueueSnapshot, required String currentUserUid}) async {
    return randomQueueSnapshot.ref.runTransaction((Object? value) {
      // Ensure a call at the ref exists.
      if (value == null) return Transaction.abort();

      Map<String, dynamic> p2pCallValue = Map<String, dynamic>.from(value as Map);

      // Ensure this call was not already occupied
      if (p2pCallValue["occ"] == -1) {
        // -1 means this call is already occupied by someone else
        return Transaction.abort();
      }

      // Set the new values to occupy this call
      p2pCallValue["occ"] = -1;
      p2pCallValue["occBy"] = currentUserUid;
      p2pCallValue["answer"] = "Answer here from: " + currentUserUid;

      // Return the new data to set it!
      return Transaction.success(p2pCallValue);
    });
  }

  Future setFCMToken({required String token, required String userUid}) async {
    await _firebaseDatabase.ref('usersInfos/$userUid/fcmToken').set({
      "token": token,
      "time": new DateTime.now().millisecondsSinceEpoch,
    });
  }
}
