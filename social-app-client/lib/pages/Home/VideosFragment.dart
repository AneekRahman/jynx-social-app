import 'package:flutter/material.dart';

import 'ExploreVideos.dart';

class VideosFragment extends StatefulWidget {
  const VideosFragment({super.key});

  @override
  State<VideosFragment> createState() => _VideosFragmentState();
}

class _VideosFragmentState extends State<VideosFragment> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExploreVideos(),
        VideosPagesAppBar(),
      ],
    );
  }
}

class VideosPagesAppBar extends StatelessWidget {
  final double _padding = 20;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_padding, _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {},
            child: Text("Explore"),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: () {},
            child: Text("For you"),
          ),
        ],
      ),
    );
  }
}
