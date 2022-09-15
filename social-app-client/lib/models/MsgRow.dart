class MsgRow {
  String? msgUid;
  String? msg;
  String? userUid;
  int? sentTime;
  int? type; // 0 = normal msg, 1 = info msg from server

  MsgRow({
    this.msg,
    this.userUid,
    this.sentTime,
  });

  MsgRow.fromJson(Map<dynamic, dynamic> json) {
    msgUid = json['msgUid'];
    msg = json['msg'];
    userUid = json['userUid'];
    sentTime = json['sentTime'];
    type = json['type'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['msgUid'] = this.msgUid;
    data['msg'] = this.msg;
    data['userUid'] = this.userUid;
    data['sentTime'] = this.sentTime;
    data['type'] = this.type ?? 0;
    return data;
  }
}
