class MyUserObject {
  String userUid;
  String displayName;
  String userName;
  String profilePic;
  Map<String, String> userMeta = {};

  MyUserObject({
    this.userUid,
    this.displayName,
    this.userName,
    this.profilePic,
    this.userMeta,
  });

  MyUserObject.fromJson(Map<dynamic, dynamic> json) {
    userUid = json['userUid'];
    displayName = json['displayName'];
    userName = json['userName'];
    profilePic = json['profilePic'];
    Map metaMap = json["userMeta"];
    if (metaMap != null) {
      userMeta["bio"] = metaMap["bio"];
      userMeta["website"] = metaMap["website"];
      userMeta["location"] = metaMap["location"];
    }
  }
}
