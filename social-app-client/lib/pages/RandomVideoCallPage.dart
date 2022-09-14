import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_app/modules/constants.dart';

class RandomVideoCallPage extends StatefulWidget {
  const RandomVideoCallPage({super.key});

  @override
  State<RandomVideoCallPage> createState() => _RandomVideoCallPageState();
}

class _RandomVideoCallPageState extends State<RandomVideoCallPage> {
  bool _initiatingCall = false;
  bool _stoppedCall = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(),
          ),
          PermissionRequiredMsg(),
          Expanded(
            child: Column(
              children: [
                WebRTCChatBox(),
                ContolsBar(
                    initiatingCall: _initiatingCall,
                    stoppedCall: _stoppedCall,
                    onNextPressed: () {
                      setState(() {
                        _initiatingCall = !_initiatingCall;
                      });
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionRequiredMsg extends StatefulWidget {
  const PermissionRequiredMsg({
    Key? key,
  }) : super(key: key);

  @override
  State<PermissionRequiredMsg> createState() => _PermissionRequiredMsgState();
}

class _PermissionRequiredMsgState extends State<PermissionRequiredMsg> with WidgetsBindingObserver {
  PermissionStatus _micAndCamPermStatus = PermissionStatus.granted;
  String? _permissionStatusMsg = null;
  bool _comingBackFromSettings = false;

  Future getPermissionStatus(bool requestPermission) async {
    if (requestPermission) {
      await Permission.camera.request();
      await Permission.microphone.request();
    }
    final _camPermStatus = await Permission.camera.status;
    final _micPermStatus = await Permission.microphone.status;

    print("GOT: _camPermStatus: $_camPermStatus and _micPermStatus: $_micPermStatus");

    if (_camPermStatus.isGranted && _micPermStatus.isGranted) {
      _micAndCamPermStatus = PermissionStatus.granted;
    } else if (_camPermStatus.isDenied || _micPermStatus.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      _permissionStatusMsg = "Permission for camera or audio was denied. These are required if you want to video chat with others.";
      _micAndCamPermStatus = PermissionStatus.denied;
    } else if (_camPermStatus.isPermanentlyDenied || _micPermStatus.isPermanentlyDenied) {
      _permissionStatusMsg =
          "Permission for camera or audio was permenantly denied. Please open the settings and allow these permissions to video chat with others.";
      _micAndCamPermStatus = PermissionStatus.permanentlyDenied;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    getPermissionStatus(true);
    super.initState();
  }

  @override
  void activate() {
    print("GOT activate");
    super.activate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _comingBackFromSettings) {
      getPermissionStatus(false);
      print("GOT AppLifecycleState.resumed");
      _comingBackFromSettings = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_micAndCamPermStatus.isGranted
        ? Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Permission required:",
                  style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  _permissionStatusMsg != null ? _permissionStatusMsg! : "Allow the permissions to chat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 18)),
                      ),
                      onPressed: () async {
                        getPermissionStatus(true);
                      },
                      child: Text("Allow Permissions", style: TextStyle(color: Colors.black)),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 18)),
                      ),
                      onPressed: () async {
                        _comingBackFromSettings = true;
                        openAppSettings();
                      },
                      child: Text("Open Settings", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          )
        : SizedBox();
  }
}

class WebRTCChatBox extends StatelessWidget {
  const WebRTCChatBox({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Theme(
        data: ThemeData.light(),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                color: Colors.black.withOpacity(.05),
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16),
                        maxLength: 200,
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                          hintText: 'Say hi...',
                          hintStyle: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16),
                          border: InputBorder.none,
                        ),
                        onChanged: ((value) {}),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {},
                      icon: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: double.infinity),
                      Text("Connected to someone from...", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContolsBar extends StatelessWidget {
  final bool initiatingCall;
  final bool stoppedCall;
  final Function onNextPressed;
  const ContolsBar({super.key, required this.initiatingCall, required this.stoppedCall, required this.onNextPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          backgroundColor: MaterialStateProperty.all(Colors.pink),
          padding: MaterialStateProperty.all(EdgeInsets.all(18)),
        ),
        onPressed: () {
          onNextPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            initiatingCall
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(stoppedCall ? Icons.video_label_rounded : Icons.chevron_right_sharp, size: 24, color: Colors.white),
            SizedBox(width: 16),
            Text(
              initiatingCall
                  ? "Finding..."
                  : stoppedCall
                      ? "Start VidChatting"
                      : "Shuffle to Next",
              style: TextStyle(color: Colors.white, fontFamily: HelveticaFont.Medium, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
