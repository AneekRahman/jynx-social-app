import 'dart:convert';

import 'package:social_app/models/UserProfileObject.dart';

class ChatRow {
  late String chatRoomUid;
  late UserProfileObject otherUser;
  String? lastMsgSentTime;
  String? lastMsg;
  bool? seen;
  // status:
  //   : 0 means not seen by the user
  //   : 1 means seen
  bool? requestedByOtherUser;
  bool? blockedByThisUser;

  ChatRow({
    required this.chatRoomUid,
    required this.otherUser,
    this.lastMsgSentTime,
    this.lastMsg,
    this.seen,
    this.requestedByOtherUser,
    this.blockedByThisUser,
  });

  ChatRow.fromJson(Map<String, dynamic> map, String chatRoomUid) {
    chatRoomUid = chatRoomUid;
    otherUser = UserProfileObject.fromJson(map["otherUser"], map["userUid"]);
    lastMsgSentTime = map['lastMsgSentTime'];
    lastMsg = map['lastMsg'];
    seen = map['seen'];
    requestedByOtherUser = map['requestedByOtherUser'];
    blockedByThisUser = map['blockedByThisUser'];
  }
}

class ChatType {
  static final String PRIVATE = "PRIVATE";
  static final String GROUP = "GROUP";
}
