class ChatRow {
  String chatRoomUid;
  String otherUsersUid;
  String otherUsersName;
  String otherUsersPic;
  int lastMsgSentTime;
  int status;

  ChatRow({
    this.chatRoomUid,
    this.otherUsersUid,
    this.otherUsersName,
    this.otherUsersPic,
    this.lastMsgSentTime,
    this.status,
  });

  ChatRow.fromJson(Map<dynamic, dynamic> json) {
    chatRoomUid = json['chatRoomUid'];
    otherUsersUid = json['otherUsersUid'];
    otherUsersName = json['otherUsersName'];
    otherUsersPic = json['otherUsersPic'];
    lastMsgSentTime = json['lastMsgSentTime'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatRoomUid'] = this.chatRoomUid;
    data['otherUsersUid'] = this.otherUsersUid;
    data['otherUsersName'] = this.otherUsersName;
    data['otherUsersPic'] = this.otherUsersPic;
    data['lastMsgSentTime'] = this.lastMsgSentTime;
    data['status'] = this.status;
    return data;
  }
}
