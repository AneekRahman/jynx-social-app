import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserFirestore.dart';

class UserChatsObject {
  String? chatRoomUid;
  List? members;
  List? allMembers;
  List? lastMsgSeenBy;
  String? lastMsg;
  List? requestedMembers;
  List? blockedMembers;
  String? lastMsgSentTime;
  Map? memberInfo;
  String? type; // PRIVATE, GROUP

  UserChatsObject({
    this.chatRoomUid,
    this.members,
    this.allMembers,
    this.requestedMembers,
    this.blockedMembers,
    this.lastMsgSeenBy,
    this.lastMsg,
    this.lastMsgSentTime,
    this.memberInfo,
    this.type,
  });

  UserChatsObject.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    chatRoomUid = snapshot.id;
    members = snapshot.get("members");
    allMembers = snapshot.get("allMembers");
    requestedMembers = snapshot.get("requestedMembers");
    blockedMembers = snapshot.get("blockedMembers");
    lastMsgSeenBy = snapshot.get("lastMsgSeenBy");
    lastMsg = snapshot.get("lastMsg") ?? "";
    lastMsgSentTime = snapshot.get("lastMsgSentTime");
    memberInfo = snapshot.get("memberInfo");
    type = snapshot.get("type");
  }

  UserChatsObject.fromQuerySnapshot(QueryDocumentSnapshot snapshot) {
    chatRoomUid = snapshot.id;
    members = snapshot.get("members");
    allMembers = snapshot.get("allMembers");
    requestedMembers = snapshot.get("requestedMembers");
    blockedMembers = snapshot.get("blockedMembers");
    lastMsgSeenBy = snapshot.get("lastMsgSeenBy");
    lastMsg = snapshot.get("lastMsg") ?? "";
    lastMsgSentTime = snapshot.get("lastMsgSentTime");
    memberInfo = snapshot.get("memberInfo");
    type = snapshot.get("type");
  }
}

class ChatRow {
  late String chatRoomUid;
  late UserFirestore otherUser;
  String? lastMsgSentTime;
  String? lastMsg;
  bool? seen;
  // status:
  //   : 0 means not seen by the user
  //   : 1 means seen
  bool? requestedByThisUser;
  bool? requestedByOtherUser;
  bool? blockedByThisUser;

  ChatRow({
    required this.chatRoomUid,
    required this.otherUser,
    this.lastMsgSentTime,
    this.lastMsg,
    this.seen,
    this.requestedByThisUser,
    this.requestedByOtherUser,
    this.blockedByThisUser,
  });

  ChatRow.fromJson(Map<String, dynamic> map, String chatRoomUid) {
    chatRoomUid = chatRoomUid;
    otherUser = UserFirestore.fromMap(map["otherUser"], map["userUid"]);
    lastMsgSentTime = map['lastMsgSentTime'];
    lastMsg = map['lastMsg'];
    seen = map['seen'];
    requestedByThisUser = map['requestedByThisUser'];
    requestedByOtherUser = map['requestedByOtherUser'];
    blockedByThisUser = map['blockedByThisUser'];
  }
}

class ChatType {
  static final String PRIVATE = "PRIVATE";
  static final String GROUP = "GROUP";
}
