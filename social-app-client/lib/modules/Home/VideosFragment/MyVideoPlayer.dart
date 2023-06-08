import 'package:flutter/material.dart';
import 'package:cached_video_player/cached_video_player.dart';

void main() => runApp(const MyVideoPlayer());

/// Stateful widget to fetch and then display video content.
class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({super.key});

  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late CachedVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CachedVideoPlayerController.network('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
    _controller.setLooping(true);
    _controller.initialize().then((value) {
      _controller.play();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CachedVideoPlayer(_controller),
                )
              : Container(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
