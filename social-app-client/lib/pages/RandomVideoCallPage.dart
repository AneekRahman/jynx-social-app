import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
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
