import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/modules/WebRTCSignaling.dart';
import 'package:wakelock/wakelock.dart';
import '../models/FCMNotification.dart';
import '../modules/PermissionRequiredMsg.dart';
import '../modules/constants.dart';
import '../services/rtd_service.dart';

class VideoCallPage extends StatefulWidget {
  /// [chatRoomsInfos] is available when the currentUser creates a call
  ChatRoomsInfos? chatRoomsInfos;

  /// [notificationChatRoomUid] is available when the user opened an /incomingCall/ notification
  FCMNotifcation? fcmNotifcation;
  final bool shouldCreateOffer;

  /// Either [chatRoomsInfos] or [notificationChatRoomUid] must be present
  VideoCallPage({super.key, this.chatRoomsInfos, this.fcmNotifcation, required this.shouldCreateOffer});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late WebRTCSignaling webRTCSignaling;

  late final _currentUser;
  late final FCMNotifcation _otherUser;
  StreamSubscription<DatabaseEvent>? _incomingCallListener;

  late String _chatRoomUid;
  bool? _createdIncomingNode;
  bool _startedOrAccepted = false;

  // For UX updates
  bool _callEnded = false;

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

  void initCallRoom() {
    // Keep screen awake while on VideoCallPage
    Wakelock.enable();

    _chatRoomUid = widget.chatRoomsInfos != null ? widget.chatRoomsInfos!.chatRoomUid : widget.fcmNotifcation!.chatRoomUid!;

    // If [fcmNotifcation] is null, get the otherUsers info from [chatRoomsInfos] to display it
    if (widget.fcmNotifcation == null && widget.chatRoomsInfos != null) {
      widget.chatRoomsInfos!.mems.forEach((element) {
        if (element.userUid != _currentUser.uid)
          _otherUser = FCMNotifcation(
            chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
            usersName: element.name,
            usersPhotoURL: element.url,
          );
      });
    }

    // Either [chatRoomsInfos] or [notificationChatRoomUid] will always be present
    webRTCSignaling = WebRTCSignaling(
      rootContext: context,
      chatRoomUid: _chatRoomUid,
      currentUser: _currentUser,
    );

    // Listen to webRTC peerConnection state changes
    webRTCSignaling.onPeerConnectionStateCallback = ((RTCPeerConnectionState state) {
      print("GOT: new change in peer connection: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        webRTCSignaling.hangUp(_localVideoRenderer);
        setState(() {
          _callEnded = true;
        });
      }
    });

    // Listen to /incomingCall/ node
    _incomingCallListener = context.read<RealtimeDatabaseService>().getIncomingCallStream(chatRoomUid: _chatRoomUid).listen((event) {
      if (event.snapshot.exists) {
        _createdIncomingNode = true;
      } else {
        _createdIncomingNode = false;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    _currentUser = context.read<User>();
    initCallRoom();
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
    webRTCSignaling.hangUp(_localVideoRenderer);
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
              // otherUsers video
              _startedOrAccepted
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: RTCVideoView(
                        _remoteVideoRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    )
                  : SizedBox(),
              // currentUsers video
              !_callEnded && _startedOrAccepted
                  ? Positioned(
                      top: 16,
                      right: 16,
                      height: 130,
                      width: 80,
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
                    )
                  : SizedBox(),
              // Other users info
              !_startedOrAccepted ? _buildOtherUsersInfo() : SizedBox(),
              _callEnded ? _buildCallEndedBox() : SizedBox(),
              // Permission messages
              Center(
                child: PermissionRequiredMsg(
                  onChange: (bool) async {
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
              // Bottom buttons
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _startedOrAccepted ? _buildInCallActionsBar(context) : _buildBottomButtons(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallEndedBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Text(
              "Call ended...",
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 20),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
              backgroundColor: MaterialStateProperty.all(Colors.yellow),
              padding: MaterialStateProperty.all(EdgeInsets.all(14)),
            ),
            onPressed: () async {
              await context.read<RealtimeDatabaseService>().deleteIncomingCallNode(chatRoomUid: _chatRoomUid);
              Navigator.pop(context);
            },
            child: Text(
              "Go back",
              style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Roman, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherUsersInfo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _otherUser.usersPhotoURL != null && _otherUser.usersPhotoURL!.isNotEmpty
              ? Image.network(_otherUser.usersPhotoURL!, width: double.infinity)
              : Image.asset(
                  "assets/user.png",
                  height: 120,
                  width: 120,
                ),
          SizedBox(height: 20),
          Text(
            _otherUser.usersName!,
            style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 20),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_createdIncomingNode == null) return SizedBox();
    if (_createdIncomingNode!) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                backgroundColor: MaterialStateProperty.all(Colors.green),
                padding: MaterialStateProperty.all(EdgeInsets.all(14)),
              ),
              onPressed: () async {
                if (!await Constants.checkCamMicPermission()) return;

                setState(() {
                  _startedOrAccepted = true;
                });
                webRTCSignaling.joinRoom(_remoteVideoRenderer).catchError((e) {
                  // On error
                  setState(() {
                    _startedOrAccepted = false;
                  });
                });
              },
              child: Text(
                "Answer Call",
                style: TextStyle(color: Colors.white, fontFamily: HelveticaFont.Roman, fontSize: 18),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                backgroundColor: MaterialStateProperty.all(Colors.red),
                padding: MaterialStateProperty.all(EdgeInsets.all(14)),
              ),
              onPressed: () async {
                await context.read<RealtimeDatabaseService>().deleteIncomingCallNode(chatRoomUid: _chatRoomUid);
                Navigator.pop(context);
              },
              child: Text(
                "Hang up",
                style: TextStyle(color: Colors.white, fontFamily: HelveticaFont.Roman, fontSize: 18),
              ),
            ),
          ),
        ],
      );
    } else {
      return TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
          backgroundColor: MaterialStateProperty.all(Colors.yellow),
          padding: MaterialStateProperty.all(EdgeInsets.all(14)),
        ),
        onPressed: () async {
          if (!await Constants.checkCamMicPermission()) return;
          setState(() {
            _startedOrAccepted = true;
          });
          await webRTCSignaling.createRoom(_remoteVideoRenderer).catchError((e) {
            // On error
            setState(() {
              _startedOrAccepted = false;
            });
          });
        },
        child: Text(
          "Make a Call",
          style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Roman, fontSize: 20),
        ),
      );
    }
  }

  Widget _buildInCallActionsBar(BuildContext context) {
    if (_callEnded) return SizedBox();

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
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    // IconButton(
                    //   onPressed: () async {
                    //     await webRTCSignaling.joinRoom(_remoteVideoRenderer);
                    //     setState(() {
                    //       _startedOrAccepted = true;
                    //     });
                    //   },
                    //   icon: Icon(
                    //     Icons.check,
                    //     color: Colors.white,
                    //     size: 30,
                    //   ),
                    // ),
                    // IconButton(
                    //   onPressed: () async {
                    //     await webRTCSignaling.createRoom(_remoteVideoRenderer);
                    //     setState(() {
                    //       _startedOrAccepted = true;
                    //     });
                    //   },
                    //   icon: Icon(
                    //     Icons.add,
                    //     color: Colors.white,
                    //     size: 30,
                    //   ),
                    // ),
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
