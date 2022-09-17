import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/IncomingCall.dart';
import 'package:social_app/modules/WebRTCSignaling.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:wakelock/wakelock.dart';

import '../modules/PermissionRequiredMsg.dart';
import '../modules/constants.dart';

class VideoCallPage extends StatefulWidget {
  /// [chatRoomsInfos] is available when the currentUser creates a call
  ChatRoomsInfos? chatRoomsInfos;

  /// [notificationChatRoomUid] is available when the user opened an /incomingCall/ notification
  String? notificationChatRoomUid;
  final bool shouldCreateOffer;

  /// Either [chatRoomsInfos] or [notificationChatRoomUid] must be present
  VideoCallPage({super.key, this.chatRoomsInfos, this.notificationChatRoomUid, required this.shouldCreateOffer});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final _currentUser;
  StreamSubscription<DatabaseEvent>? _incomingCallListener;
  late WebRTCSignaling webRTCSignaling;

  // The states below are for WebRTC
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();

  Future initRenderers() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  void disposeRenderers() async {
    if (_localVideoRenderer.srcObject != null) _localVideoRenderer.dispose();
    if (_remoteVideoRenderer.srcObject != null) _remoteVideoRenderer.dispose();
  }
  ////////////////////////////////////////////////////////////////////////////////////////////////

  // Future<String> createAndSetOfferFromPeerConnection() async {
  //   // Create the offer from [_peerConnection]
  //   RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
  //   // Set the current local description for this _peerConnection as an [offer]
  //   _peerConnection!.setLocalDescription(description);

  //   var session = parse(description.sdp.toString());
  //   return json.encode(session);
  // }

  // Future setRemoteDescription(String offer, bool isOffer) async {
  //   dynamic session = await jsonDecode(offer);
  //   String sdp = write(session, null);

  //   // TODO check if its !isOffer or just isOffer
  //   RTCSessionDescription description = RTCSessionDescription(sdp, isOffer ? 'offer' : "answer");

  //   await _peerConnection!.setRemoteDescription(description);
  // }

  // Future<String> createAndSetAnswerFromPeerConnection() async {
  //   RTCSessionDescription description = await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
  //   // Set the current local description for this _peerConnection as an [answer]
  //   _peerConnection!.setLocalDescription(description);

  //   var session = parse(description.sdp.toString());
  //   return json.encode(session);
  // }

  // /// When [_currentUser] creates the call first.
  // void createCall() async {
  //   _thisIsOffer = true;
  //   // First create and set the offer from [_peerConnection] as localDescription. Then get it.
  //   String offer = await createAndSetOfferFromPeerConnection();
  //   // First create the /incomingCall/ node
  //   await context
  //       .read<RealtimeDatabaseService>()
  //       .setChatRoomsInfosIncomingCall(chatRoomUid: widget.chatRoomsInfos!.chatRoomUid, callerUid: _currentUser.uid, offer: offer);

  //   // Then listen to the /incomingCall/ node for the [answer] of the other party
  //   initIncomingCallListener();
  // }

  // /// If the [_currentUser] created the call [offer], then an [answer] needs to be received for [_setCandidate]
  // void initIncomingCallListener() {
  //   _incomingCallListener = context
  //       .read<RealtimeDatabaseService>()
  //       .getIncomingCallStream(chatRoomUid: widget.chatRoomsInfos!.chatRoomUid)
  //       .listen((event) async {
  //     if (event.snapshot.exists) {
  //       // If currentUser created the [offer], then he must accept the answer
  //       if (widget.shouldCreateOffer) {
  //         final answer = (event.snapshot.value as Map)["answer"];
  //         if (answer != null) {
  //           await setRemoteDescription(answer, false);
  //           // await setCandidateFromAnswer(answer);
  //           setState(() {});
  //         }
  //       }
  //     }
  //   });
  // }

  // /// This is called after [_setRemoteDescription] is set with the [offer] gotten from /incomingCall/ node and then the [answer] created.
  // void answerCall(String notificationChatRoomUid) async {
  //   _thisIsOffer = false;
  //   final DataSnapshot incomingCallSnapshot =
  //       await context.read<RealtimeDatabaseService>().getIncomingCallSnaphsot(chatRoomUid: notificationChatRoomUid);

  //   if (incomingCallSnapshot.exists) {
  //     IncomingCall incomingCall = IncomingCall.fromMap(map: incomingCallSnapshot.value as Map, chatRoomUid: notificationChatRoomUid);
  //     // First set the candidate using the [offer]
  //     await setRemoteDescription(incomingCall.offer!, true);
  //     // Next, create an answer and set it in /incomingCall/
  //     final String answer = await createAndSetAnswerFromPeerConnection();
  //     await context.read<RealtimeDatabaseService>().setIncomingCallAnswer(chatRoomUid: notificationChatRoomUid, answer: answer);
  //   }
  // }

  // Future setCandidateFromAnswer(String answer) async {
  //   dynamic session = await jsonDecode(answer);
  //   dynamic candidate = RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
  //   await _peerConnection!.addCandidate(candidate);
  // }

  // void _initCallPage() async {
  //   final allPermGranted = await Constants.checkCamMicPermission();

  //   if (allPermGranted) {
  //     if (widget.shouldCreateOffer) {
  //       createCall();
  //     } else {
  //       if (widget.notificationChatRoomUid != null) {
  //         answerCall(widget.notificationChatRoomUid!);
  //       }
  //     }
  //   }
  // }

  @override
  void initState() {
    _currentUser = context.read<User>();

    // Either [chatRoomsInfos] or [notificationChatRoomUid] will always be present
    webRTCSignaling = WebRTCSignaling(
      rootContext: context,
      chatRoomUid: widget.chatRoomsInfos != null ? widget.chatRoomsInfos!.chatRoomUid : widget.notificationChatRoomUid,
      currentUser: _currentUser,
    );
    // Keep screen awake while on VideoCallPage
    Wakelock.enable();

    // String encrypted = MyEncryption.getEncryptedString(
    //     mainString: "Hello ami aneek", password: MyEncryption.CHAT_ROOM_MESSAGES_PASSWORD, uid: "dawjdowjdoa");
    // String decrypted =
    //     MyEncryption.getDecryptedString(encryptedString: encrypted, password: MyEncryption.CHAT_ROOM_MESSAGES_PASSWORD, uid: "dawjdowjdoa");

    super.initState();
  }

  @override
  void dispose() {
    Wakelock.disable();
    disposeRenderers();
    // webRTCSignaling.hangUp(_localVideoRenderer);
    if (_incomingCallListener != null) _incomingCallListener!.cancel();
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
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: PermissionRequiredMsg(
                  onChange: () async {
                    // This will be called right after permission for camera and microphone is granted
                    await initRenderers();
                    webRTCSignaling.onAddRemoteStream = ((stream) {
                      _remoteVideoRenderer.srcObject = stream;
                      setState(() {});
                    });
                    await webRTCSignaling.openUserMedia(_localVideoRenderer, _remoteVideoRenderer);
                    setState(() {});
                  },
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
                      mirror: true,
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

  Widget _buildBottomActionsBar(BuildContext context) {
    return Column(
      children: [
        Container(
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
                      onPressed: () async {
                        await webRTCSignaling.hangUp(_localVideoRenderer);
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await webRTCSignaling.joinRoom(_remoteVideoRenderer);
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await webRTCSignaling.createRoom(_remoteVideoRenderer);
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    // IconButton(
                    //   onPressed: _setCandidate, // Step 4
                    //   icon: Icon(
                    //     Icons.volume_up,
                    //     color: Colors.white,
                    //     size: 30,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
