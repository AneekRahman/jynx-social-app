class MyUserObject {
  String userUid;
  String displayName;
  String userName;
  String profilePic;

  MyUserObject({
    this.userUid,
    this.displayName,
    this.userName,
    this.profilePic,
  });

  MyUserObject.fromJson(Map<dynamic, dynamic> json) {
    userUid = json['userUid'];
    displayName = json['displayName'];
    userName = json['userName'];
    profilePic = json['profilePic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userUid'] = this.userUid;
    data['displayName'] = this.displayName;
    data['userName'] = this.userName;
    data['profilePic'] = this.profilePic;
    return data;
  }
}
