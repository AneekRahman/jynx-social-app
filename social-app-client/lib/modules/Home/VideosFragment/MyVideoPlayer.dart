import 'package:flutter/material.dart';
import 'package:cached_video_player/cached_video_player.dart';

import '../../constants.dart';
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
    _controller = CachedVideoPlayerController.network('https://www.pexels.com/download/video/4434286/?fps=30.0&h=1280&w=720');
    _controller.setLooping(true);
    _controller.initialize().then((value) {
      setState(() {});
      if (widget.firstIntializedVideo) _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
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
            child: SizedBox(
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CachedVideoPlayer(_controller),
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          left: 20,
          bottom: 100,
          child: PostInfoBox(),
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

class PostInfoBox extends StatelessWidget {
  const PostInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AbsorbPointer(
          absorbing: false,
          child: PostButtons(),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "As a beauty editor, I’ve jumped on many skincare trends. Some have been more helpful than others, I’ll admit. But over the years",
                style: TextStyle(fontFamily: HelveticaFont.Roman),
              ),
              SizedBox(height: 16),
              Text(
                "Aneek Rahman",
                style: TextStyle(fontFamily: HelveticaFont.Bold),
              ),
              Text(
                "@mr_rahman",
                style: TextStyle(fontFamily: HelveticaFont.Roman),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class PostButtons extends StatelessWidget {
  const PostButtons({super.key});

  Container _buildOtherUsersProfilePic() {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10000),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child:
          // otherPrivateChatRoomUser.url.isNotEmpty
          //     ? ClipRRect(
          //         child: Image.network(
          //           otherPrivateChatRoomUser.url,
          //           height: 45,
          //           width: 45,
          //           fit: BoxFit.cover,
          //         ),
          //         borderRadius: BorderRadius.all(Radius.circular(100)),
          //       ):
          Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.4),
          borderRadius: BorderRadius.circular(10000),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          iconSize: 40,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Like-icon.png"),
            opacity: .8,
          ),
        ),
        SizedBox(height: 6),
        IconButton(
          iconSize: 40,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Dislike-icon.png"),
            opacity: .8,
          ),
        ),
        SizedBox(height: 6),
        IconButton(
          iconSize: 30,
          onPressed: () {},
          icon: Opacity(
            child: Image.asset("assets/icons/Message-icon.png"),
            opacity: .8,
          ),
        ),
        SizedBox(height: 10),
        IconButton(
          iconSize: 40,
          onPressed: () {
            print("HELLO");
          },
          icon: _buildOtherUsersProfilePic(),
        ),
      ],
    );
  }
}
