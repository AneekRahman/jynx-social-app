class ChatRow {
  String chatRoomUid;

  String otherUsersUid;
  String otherUsersName;
  String otherUsersPic;
  int lastMsgSentTime;
  int roomType;
  // roomType:
  //   : 0 means oneOnOne
  //   : 1 means group
  //   : -1 means blocked (TODO implement security rules)
  int status;
  // status:
  //   : 0 means not seen by the user
  //   : 1 means seen

  ChatRow({
    this.chatRoomUid,
    this.otherUsersUid,
    this.otherUsersName,
    this.otherUsersPic,
    this.lastMsgSentTime,
    this.roomType,
    this.status,
  });

  ChatRow.fromJson(Map<dynamic, dynamic> json) {
    chatRoomUid = json['chatRoomUid'];
    otherUsersUid = json['otherUsersUid'];
    otherUsersName = json['otherUsersName'];
    otherUsersPic = json['otherUsersPic'];
    lastMsgSentTime = json['lastMsgSentTime'];
    roomType = json['roomType'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatRoomUid'] = this.chatRoomUid;
    data['otherUsersUid'] = this.otherUsersUid;
    data['otherUsersName'] = this.otherUsersName;
    data['otherUsersPic'] = this.otherUsersPic;
    data['lastMsgSentTime'] = this.lastMsgSentTime;
    data['roomType'] = this.roomType;
    data['status'] = this.status;
    return data;
  }
}
