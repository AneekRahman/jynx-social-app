import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_app/modules/constants.dart';

class PermissionRequiredMsg extends StatefulWidget {
  final Function(bool) onChange;
  const PermissionRequiredMsg({
    Key? key,
    required this.onChange,
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

    if (_camPermStatus.isGranted && _micPermStatus.isGranted) {
      _micAndCamPermStatus = PermissionStatus.granted;
      widget.onChange(true);
      if (mounted) setState(() {});
      return;
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
    widget.onChange(false);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    getPermissionStatus(true);
    super.initState();
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
              mainAxisSize: MainAxisSize.min,
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
