import 'dart:convert';

import 'package:social_app/models/UserProfileObject.dart';

class ChatRow {
  late String chatRoomUid;
  late UserProfileObject otherUser;
  String? lastMsgSentTime;
  bool? seen;
  bool? requested;
  // status:
  //   : 0 means not seen by the user
  //   : 1 means seen

  ChatRow({
    required this.chatRoomUid,
    required this.otherUser,
    this.lastMsgSentTime,
    this.seen,
    this.requested,
  });

  ChatRow.fromJson(Map<String, dynamic> map, String chatRoomUid) {
    chatRoomUid = map['chatRoomUid'];
    otherUser = UserProfileObject.fromJson(map["otherUser"], map["userUid"]);
    lastMsgSentTime = map['lastMsgSentTime'];
    seen = map['seen'];
    requested = map['requested'];
  }
}

class ChatType {
  static final String PRIVATE = "PRIVATE";
  static final String GROUP = "GROUP";
}
