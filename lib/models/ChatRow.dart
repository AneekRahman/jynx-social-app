class ChatRow {
  String userChatsDocUid;
  String chatRoomUid;
  String otherUsersUid;
  String otherUsersName;
  String otherUsersPic;
  String lastMsgSentTime;
  bool seen;
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
    this.seen,
  });

  ChatRow.fromJson(Map<dynamic, dynamic> json) {
    userChatsDocUid = json['userChatsDocUid'];
    chatRoomUid = json['chatRoomUid'];
    otherUsersUid = json['otherUsersUid'];
    otherUsersName = json['otherUsersName'];
    otherUsersPic = json['otherUsersPic'];
    lastMsgSentTime = json['lastMsgSentTime'];
    seen = json['seen'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userChatsDocUid'] = this.userChatsDocUid;
    data['chatRoomUid'] = this.chatRoomUid;
    data['otherUsersUid'] = this.otherUsersUid;
    data['otherUsersName'] = this.otherUsersName;
    data['otherUsersPic'] = this.otherUsersPic;
    data['lastMsgSentTime'] = this.lastMsgSentTime;
    data['seen'] = this.seen;
    return data;
  }
}
