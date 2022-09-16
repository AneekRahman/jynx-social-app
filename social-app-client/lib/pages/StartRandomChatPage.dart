import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/RandomVideoCallPage.dart';
import 'package:video_player/video_player.dart';

GlobalKey<_VideoBannerState> _videoBannerGlobalKey = GlobalKey<_VideoBannerState>();

class StartRandomChatPage extends StatefulWidget {
  final User currentUser;
  const StartRandomChatPage({super.key, required this.currentUser});

  @override
  State<StartRandomChatPage> createState() => _StartRandomChatPageState();
}

class _StartRandomChatPageState extends State<StartRandomChatPage> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Random VidChatting",
                style: TextStyle(fontSize: 18, fontFamily: HelveticaFont.Medium),
              ),
              SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                child: VideoBanner(key: _videoBannerGlobalKey),
              ),
              SizedBox(height: 30),
              Text(
                "How does this work?",
                style: TextStyle(fontSize: 14, fontFamily: HelveticaFont.Medium),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3BDDFA),
                      const Color(0xFF3EC2F9),
                    ],
                    begin: const FractionalOffset(0.0, 1.0),
                    end: const FractionalOffset(1.0, 0.0),
                    stops: [0.0, 1.0],
                    tileMode: TileMode.clamp,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. You can video chat anonymously.",
                      style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "2. You can keep shuffling through random people and talk to them.",
                      style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white),
                    ),
                    // SizedBox(height: 8),
                    // Text(
                    //   "3. Your indentity will remain anonymous.",
                    //   style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white),
                    // ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                "By tapping the button below you agree to adhere to our rules while calling other people.",
                style: TextStyle(fontSize: 12, fontFamily: HelveticaFont.Roman, color: Colors.white.withOpacity(.6)),
              ),
              SizedBox(height: 20),
              buildYellowButton(
                child: Text(
                  "Start random video call",
                  style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Bold, color: Colors.black),
                ),
                onTap: () {
                  if (!_videoBannerGlobalKey.currentState!.paused) {
                    _videoBannerGlobalKey.currentState!.paused = false;
                    _videoBannerGlobalKey.currentState!.controller.pause();
                  }
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => RandomVideoCallPage(currentUser: widget.currentUser)));
                },
                loading: false,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoBanner extends StatefulWidget {
  const VideoBanner({super.key});

  @override
  State<VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<VideoBanner> {
  late VideoPlayerController controller;
  bool paused = false;
  double animationOpacity = 0;

  loadVideoPlayer() {
    controller = VideoPlayerController.asset('assets/banner-video1.mp4');
    controller.setLooping(true);
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    controller.initialize().then((value) {
      animationOpacity = 1;
      controller.play();
    });
  }

  @override
  void initState() {
    loadVideoPlayer();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: animationOpacity,
          duration: Duration(milliseconds: 400),
          child: SizedBox(
            height: (MediaQuery.of(context).size.width - 40) * .6025,
            width: MediaQuery.of(context).size.width - 40,
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        Positioned.fill(
            child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(.3),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        )),
        Positioned(
          top: 6,
          right: 14,
          child: IconButton(
            onPressed: () {
              if (paused) {
                paused = !paused;
                controller.play();
              } else {
                paused = !paused;
                controller.pause();
              }
            },
            icon: Icon(paused ? Icons.play_circle_rounded : Icons.pause_circle_rounded, size: 40),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Text(
            "Video chat with people all around the world.",
            style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 24),
          ),
        )
      ],
    );
  }
}
