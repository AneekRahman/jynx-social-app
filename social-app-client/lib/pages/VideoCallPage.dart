import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/FCMNotification.dart';
import 'package:social_app/models/IncomingCall.dart';
import 'package:social_app/modules/WebRTCSignaling.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:wakelock/wakelock.dart';

import '../modules/PermissionRequiredMsg.dart';
import '../modules/constants.dart';

class VideoCallPage extends StatefulWidget {
  /// [chatRoomsInfos] is available when the currentUser creates a call
  final ChatRoomsInfos? chatRoomsInfos;

  /// [fcmNotifcation] is available when the user opened an /incomingCall/ notification
  FCMNotifcation? fcmNotifcation;
  bool recievedACall;

  /// Either [chatRoomsInfos] or [fcmNotifcation] must be present
  VideoCallPage({super.key, this.chatRoomsInfos, this.fcmNotifcation, required this.recievedACall});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final _currentUser;
  FCMNotifcation? _otherUserInfo;
  late WebRTCSignaling webRTCSignaling;
  bool _inACall = false;

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

  void initCallRoom() async {
    final String? chatRoomUid = widget.chatRoomsInfos != null ? widget.chatRoomsInfos!.chatRoomUid : widget.fcmNotifcation!.chatRoomUid;
    // If [fcmNotifcation] is null, then use [chatRoomsInfos] otherUser to display the name and photoURL
    if (widget.fcmNotifcation == null) {
      widget.chatRoomsInfos!.mems.forEach((element) {
        if (element.userUid != _currentUser.uid) {
          _otherUserInfo = FCMNotifcation(chatRoomUid: chatRoomUid, usersName: element.name, usersPhotoURL: element.url);
        }
      });
    } else {
      _otherUserInfo = widget.fcmNotifcation;
    }

    // Either [chatRoomsInfos] or [fcmNotifcation] will always be present
    webRTCSignaling = WebRTCSignaling(
      rootContext: context,
      chatRoomUid: chatRoomUid,
      currentUser: _currentUser,
    );

    // Init the renderers and listen to [webRTCSignaling] callbacks
    await initRenderers();
    webRTCSignaling.onAddRemoteStream = ((stream) {
      _remoteVideoRenderer.srcObject = stream;
      setState(() {});
    });

    // Listen to the /incomingCall/ node for this chatRoom to confirm otherUser hasn't already made a call
    webRTCSignaling.listenToIncomingCallNode(!widget.recievedACall);
    webRTCSignaling.onIncomingCallNodeStream = ((IncomingCall incomingCall) {
      // Already a [offer] exists means that the otherUser has already called
      if (incomingCall.callerOffer != null) {
        setState(() {
          widget.recievedACall = true;
          _inACall = true;
        });
      }
    });
  }

  @override
  void initState() {
    _currentUser = context.read<User>();

    // Keep screen awake while on VideoCallPage
    Wakelock.enable();

    // Init the room
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
    // webRTCSignaling.hangUp(_localVideoRenderer);
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
              // Other users info
              !_inACall ? _buildOtherUsersInfo() : SizedBox(),
              // Requesting permission column
              Center(
                child: PermissionRequiredMsg(
                  onChange: (allowed) async {
                    // This will be called right after permission for camera and microphone is granted
                    if (allowed) {
                      await webRTCSignaling.openUserMedia(_localVideoRenderer, _remoteVideoRenderer);
                    }
                  },
                ),
              ),
              // Other users camera renderer
              _inACall
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: RTCVideoView(
                        _remoteVideoRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    )
                  : SizedBox(),
              // Current users camera renderer
              _inACall
                  ? Positioned(
                      top: 16,
                      right: 16,
                      height: 140,
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
              // Bottom buttons
              Positioned(
                bottom: _inACall ? 20 : 40,
                left: 20,
                right: 20,
                child: _inACall ? _buildInCallActionsBar(context) : _buildCallButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherUsersInfo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _otherUserInfo!.usersPhotoURL != null && _otherUserInfo!.usersPhotoURL!.isNotEmpty
              ? Image.network(_otherUserInfo!.usersPhotoURL!, width: double.infinity)
              : Image.asset(
                  "assets/user.png",
                  height: 120,
                  width: 120,
                ),
          SizedBox(height: 20),
          Text(
            _otherUserInfo!.usersName!,
            style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 20),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCallButton() {
    if (widget.recievedACall) {
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
                // Add an [answer] to /incomingCall/
                if (await Constants.checkCamMicPermission() && !_inACall && widget.recievedACall) {
                  webRTCSignaling.joinRoom(_remoteVideoRenderer).then((value) {
                    setState(() {
                      _inACall = true;
                    });
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error while connecting, try again!")));
                    throw e;
                  });
                }
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
              onPressed: () {
                // This is shown when user can choose to accept a call or reject it
                webRTCSignaling.hangUp(_localVideoRenderer).then((value) {
                  // Go back
                  Navigator.pop(context);
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error while hanging up!")));
                  throw e;
                });
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
          // Create a /incomingCall/ and make the call
          if (await Constants.checkCamMicPermission() && !_inACall && !widget.recievedACall) {
            webRTCSignaling.createRoom(_remoteVideoRenderer).then((value) {
              setState(() {
                _inACall = true;
              });
            }).catchError((e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error while connecting, try again!")));
              throw e;
            });
          }
        },
        child: Text(
          "Make a Call",
          style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Roman, fontSize: 20),
        ),
      );
    }
  }

  Widget _buildInCallActionsBar(BuildContext context) {
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
                        if (_inACall) {
                          webRTCSignaling.hangUp(_localVideoRenderer).then((value) {
                            setState(() {
                              _inACall = false;
                            });
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was an error while hanging up!")));
                            throw e;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {},
                      icon: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {},
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
