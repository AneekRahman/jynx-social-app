class IncomingCall {
  String chatRoomUid;
  String? callerUid, offer, answer;
  IncomingCall({
    required this.chatRoomUid,
    this.callerUid,
    this.offer,
    this.answer,
  });

  IncomingCall.fromMap({required Map<dynamic, dynamic> map, required String this.chatRoomUid}) {
    this.callerUid = map['callerUid'];
    this.offer = map['offer'];
    this.answer = map['answer'];
  }
}

class FCMNotifcation {
  String? notiType, chatRoomUid, callerName, callerPhotoURL;
  FCMNotifcation({
    this.chatRoomUid,
  });

  FCMNotifcation.fromJson(Map<dynamic, dynamic> json) {
    this.notiType = json['notiType'];
    this.callerName = json['callerName'];
    this.callerPhotoURL = json['callerPhotoURL'];
    this.chatRoomUid = json['chatRoomUid'];
  }
}

class NotificationType {
  static const String INCOMING_CALL = "INCOMING_CALL";
  static const String MESSAGE_ADDED = "MESSAGE_ADDED";
}
