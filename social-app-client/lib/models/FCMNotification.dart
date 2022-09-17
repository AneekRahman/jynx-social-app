class FCMNotifcation {
  String? notiType, chatRoomUid, usersName, usersPhotoURL;
  // When notiType = MESSAGE_ADDED
  String? msg, msgUid;
  FCMNotifcation({
    this.chatRoomUid,
    this.usersName,
    this.usersPhotoURL,
  });

  FCMNotifcation.fromJson(Map<dynamic, dynamic> json) {
    this.notiType = json['notiType'];
    this.usersName = json['usersName'];
    this.usersPhotoURL = json['usersPhotoURL'];
    this.chatRoomUid = json['chatRoomUid'];
    this.msg = json['msg'];
    this.msgUid = json['msgUid'];
  }
}

class NotificationType {
  static const String INCOMING_CALL = "INCOMING_CALL";
  static const String MESSAGE_ADDED = "MESSAGE_ADDED";
}
