import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

import '../modules/constants.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();

  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Future initRenderers() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  Future _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    setState(() {
      _localVideoRenderer.srcObject = stream;
    });
    return stream;
  }

  Future _createPeerConnecion() async {
    await initRenderers();

    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);

    _localStream!.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
    };

    return pc;
  }

  // Step 1 (for User 1): Create an offer
  // Create an offer. User 1 first creates this offer and send it to User 2 so that he can accept it
  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));

    // Set the current local description for this _peerConnection as an "offer"
    _offer = true;
    _peerConnection!.setLocalDescription(description);
  }

  // Step 2 (for User 2): take the "offer" from User 1 and set it as the remote description
  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);

    String sdp = write(session, null);

    // If the local description for the currentUser is "offer", the remote description for the otherUser will be an "answer". And vice-versa
    RTCSessionDescription description = RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());

    // After getting either the "answer" or "offer" set it as the remote description for this _peerConnection
    await _peerConnection!.setRemoteDescription(description);
  }

  // Step 3 (for User 2): Create an answer
  // Generates an answer after the [_setRemoteDescription] has set an "offer" from User 1.  and send it to User 1 so that he can accept it.
  void _createAnswer() async {
    RTCSessionDescription description = await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));

    // Set the current local description for this _peerConnection as an "answer"
    _offer = false;
    _peerConnection!.setLocalDescription(description);
  }

  // Step 4 (for User 1): take the "answer" from User 2 and set it as the candidate
  void _setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);

    // Set the candidate as User 2 since we already got the "answer" from him.
    dynamic candidate = RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  void _cleanSessions() async {
    sdpController.dispose();
    _localVideoRenderer.dispose();

    if (_localStream != null) {
      _localStream!.getTracks().forEach((element) async {
        await element.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }
    await _peerConnection?.close();
  }

  @override
  void initState() {
    // _createPeerConnecion().then((pc) {
    //   _peerConnection = pc;
    // });

    // String encrypted = MyEncryption.getEncryptedString(
    //     mainString: "Hello ami aneek", password: MyEncryption.CHAT_ROOM_MESSAGES_PASSWORD, uid: "dawjdowjdoa");
    // String decrypted =
    //     MyEncryption.getDecryptedString(encryptedString: encrypted, password: MyEncryption.CHAT_ROOM_MESSAGES_PASSWORD, uid: "dawjdowjdoa");

    super.initState();
  }

  @override
  void dispose() {
    // _cleanSessions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: SafeArea(
          child: Stack(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Container(
                  color: Colors.yellow,
                  child: RTCVideoView(
                    _remoteVideoRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
              Positioned(
                bottom: 90 + 30,
                left: 30,
                height: 160,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: Container(
                    color: Colors.black26,
                    child: RTCVideoView(
                      _localVideoRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildBottomActionsBar(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container _buildBottomActionsBar(BuildContext context) {
    return Container(
      height: 70,
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(100)),
        child: BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: new BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _createOffer, // Step 1
                  icon: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                  onPressed: _setRemoteDescription, // Step 2
                  icon: Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                  onPressed: _createAnswer, // Step 3
                  icon: Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                IconButton(
                  onPressed: _setCandidate, // Step 4
                  icon: Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
