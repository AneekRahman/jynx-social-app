import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import './MyVideoPlayer.dart';

class MyVideoPlayerController {
  void Function()? play;
}

class VideosList extends StatefulWidget {
  const VideosList({super.key});

  @override
  State<VideosList> createState() => _VideosListState();
}

class _VideosListState extends State<VideosList> {
  PageController controller = PageController();
  int _currentPage = 0;

  List<MyVideoPlayerController> myVideosStateControllers = [
    MyVideoPlayerController(),
    MyVideoPlayerController(),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PageView(
        allowImplicitScrolling: true,
        scrollDirection: Axis.vertical,
        controller: controller,
        onPageChanged: (num) {
          setState(() {
            _currentPage = num;
            print(num);
            if (myVideosStateControllers[_currentPage].play != null) {
              myVideosStateControllers[_currentPage].play!();
            }
          });
        },
        children: [
          MyVideoPlayer(myStateController: myVideosStateControllers[0], firstIntializedVideo: true),
          MyVideoPlayer(myStateController: myVideosStateControllers[1]),
        ],
      ),
    );
  }
}
