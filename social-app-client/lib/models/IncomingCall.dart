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
