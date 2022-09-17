import 'dart:convert';

class IncomingCall {
  String chatRoomUid;
  IncomingCallOffer? callerOffer;
  IncomingCallAnswer? calleeAnswer;
  IncomingCallIceCandidates? callerIceCandidates, calleeIceCandidates;

  IncomingCall.fromMap({required Map<dynamic, dynamic> map, required String this.chatRoomUid}) {
    // [caller] will always have an [offer] and [callee] will have the [answer]
    if (map["caller"] != null) {
      this.callerOffer = IncomingCallOffer.fromEncodedString(encodedString: map["caller"]['offer']);
      this.callerIceCandidates = IncomingCallIceCandidates.fromMap(map: map["caller"]['iceCandidates']);
    }
    if (map["callee"] != null) {
      this.calleeAnswer = IncomingCallAnswer.fromEncodedString(encodedString: map["callee"]['answer']);
      this.calleeIceCandidates = IncomingCallIceCandidates.fromMap(map: map["callee"]['iceCandidates']);
    }
  }
}

class IncomingCallOffer {
  String? sdp, type;

  IncomingCallOffer.fromEncodedString({required encodedString}) {
    Map map = jsonDecode(encodedString);
    this.sdp = map["sdp"];
    this.type = map["type"];
  }
}

class IncomingCallAnswer {
  String? sdp, type;

  IncomingCallAnswer.fromEncodedString({required encodedString}) {
    Map map = jsonDecode(encodedString);
    this.sdp = map["sdp"];
    this.type = map["type"];
  }
}

class IncomingCallIceCandidates {
  List<IncomingCallIceCandidate> iceCandidates = [];

  IncomingCallIceCandidates.fromMap({required Map<String, dynamic> map}) {
    map.forEach((key, value) {
      iceCandidates.add(IncomingCallIceCandidate.fromEncodedString(encodedString: value));
    });
  }
}

class IncomingCallIceCandidate {
  String? candidate, sdpMid;
  int? sdpMLineIndex;

  IncomingCallIceCandidate.fromEncodedString({required encodedString}) {
    final Map<dynamic, dynamic> map = jsonDecode(encodedString);
    this.candidate = map["candidate"];
    this.sdpMid = map["sdpMid"];
    this.sdpMLineIndex = map["sdpMLineIndex"];
  }
}
