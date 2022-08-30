class ChatRow {
  String? userChatsDocUid;
  String? chatRoomUid;
  String? otherUsersUid;
  String? otherUsersName;
  String? otherUsersUserName;
  String? otherUsersPic;
  String? lastMsgSentTime;
  bool? seen;
  bool? requested;
  // status:
  //   : 0 means not seen by the user
  //   : 1 means seen

  ChatRow({
    this.userChatsDocUid,
    this.chatRoomUid,
    this.otherUsersUid,
    this.otherUsersName,
    this.otherUsersPic,
    this.lastMsgSentTime,
    this.otherUsersUserName,
    this.seen,
    this.requested,
  });

  ChatRow.fromJson(Map<dynamic, dynamic> json) {
    userChatsDocUid = json['userChatsDocUid'];
    chatRoomUid = json['chatRoomUid'];
    otherUsersUid = json['otherUsersUid'];
    otherUsersName = json['otherUsersName'];
    otherUsersPic = json['otherUsersPic'];
    otherUsersUserName = json['otherUsersUserName'];
    lastMsgSentTime = json['lastMsgSentTime'];
    seen = json['seen'];
    requested = json['requested'];
  }
}
