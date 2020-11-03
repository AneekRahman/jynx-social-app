class MyUserObject {
  String userUid;
  String userDisplayName;
  String userPic;

  MyUserObject({
    this.userUid,
    this.userDisplayName,
    this.userPic,
  });

  MyUserObject.fromJson(Map<dynamic, dynamic> json) {
    userUid = json['userUid'];
    userDisplayName = json['userDisplayName'];
    userPic = json['userPic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userUid'] = this.userUid;
    data['userDisplayName'] = this.userDisplayName;
    data['userPic'] = this.userPic;
    return data;
  }
}
