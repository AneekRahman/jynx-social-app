import 'package:cloud_firestore/cloud_firestore.dart';

class UserChatsSnapshot {
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

  UserChatsSnapshot({
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

  UserChatsSnapshot.fromSnapshot(QueryDocumentSnapshot snapshot) {
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
