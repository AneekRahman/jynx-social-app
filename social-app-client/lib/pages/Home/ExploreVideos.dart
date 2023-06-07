import 'package:flutter/material.dart';

class ExploreVideos extends StatefulWidget {
  const ExploreVideos({super.key});

  @override
  State<ExploreVideos> createState() => _ExploreVideosState();
}

class _ExploreVideosState extends State<ExploreVideos> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text("This is ExploreVideos"),
        ],
      ),
    );
  }
}
