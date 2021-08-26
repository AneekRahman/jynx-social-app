import 'package:cloud_firestore/cloud_firestore.dart';

class UserChatsSnapshot {
  String userChatsDocUid;
  String chatRoomUid;
  List members;
  List allMembers;
  List lastMsgSeenBy;
  List requestedMembers;
  String lastMsgSentTime;
  Map memberInfo;
  String type; // PRIVATE, GROUP

  UserChatsSnapshot({
    this.userChatsDocUid,
    this.chatRoomUid,
    this.members,
    this.allMembers,
    this.requestedMembers,
    this.lastMsgSeenBy,
    this.lastMsgSentTime,
    this.memberInfo,
    this.type,
  });

  UserChatsSnapshot.fromSnapshot(QueryDocumentSnapshot snapshot) {
    userChatsDocUid = snapshot.id;
    chatRoomUid = snapshot.get("chatRoomUid");
    members = snapshot.get("members");
    allMembers = snapshot.get("allMembers");
    requestedMembers = snapshot.get("requestedMembers");
    lastMsgSeenBy = snapshot.get("lastMsgSeenBy");
    lastMsgSentTime = snapshot.get("lastMsgSentTime");
    memberInfo = snapshot.get("memberInfo");
    type = snapshot.get("type");
  }
}
