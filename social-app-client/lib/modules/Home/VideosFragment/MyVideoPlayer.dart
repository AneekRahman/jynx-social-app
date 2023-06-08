import 'package:flutter/material.dart';
import 'package:cached_video_player/cached_video_player.dart';

import 'VideosList.dart';

/// Stateful widget to fetch and then display video content.
class MyVideoPlayer extends StatefulWidget {
  final myStateController;
  final firstIntializedVideo;
  const MyVideoPlayer({super.key, required this.myStateController, this.firstIntializedVideo = false});

  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState(myStateController);
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  _MyVideoPlayerState(MyVideoPlayerController myStateController) {
    myStateController.play = startVideoFromParent;
  }

  late CachedVideoPlayerController _controller;

  void startVideoFromParent() {
    _controller.play();
  }

  @override
  void initState() {
    super.initState();
    _controller = CachedVideoPlayerController.network('https://www.pexels.com/download/video/4434242/?fps=23.976&h=1280&w=720');
    _controller.setLooping(true);
    _controller.initialize().then((value) {
      setState(() {});
      if (widget.firstIntializedVideo) _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CachedVideoPlayer(_controller),
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 100,
          child: AbsorbPointer(
            absorbing: false,
            child: PostButtons(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class PostButtons extends StatelessWidget {
  const PostButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          iconSize: 40,
          onPressed: () {
            print("HELLO");
          },
          icon: Image.asset("assets/profile-user.png"),
        ),
        SizedBox(height: 6),
        IconButton(
          iconSize: 40,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Like-icon.png"),
            opacity: .7,
          ),
        ),
        SizedBox(height: 6),
        IconButton(
          iconSize: 40,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Dislike-icon.png"),
            opacity: .7,
          ),
        ),
        SizedBox(height: 6),
        IconButton(
          iconSize: 30,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Message-icon.png"),
            opacity: .7,
          ),
        ),
      ],
    );
  }
}
