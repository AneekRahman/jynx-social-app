import 'package:flutter/material.dart';

import '../../modules/VideosList.dart';

class ExploreVideos extends StatefulWidget {
  const ExploreVideos({super.key});

  @override
  State<ExploreVideos> createState() => _ExploreVideosState();
}

class _ExploreVideosState extends State<ExploreVideos> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VideosList(),
      ],
    );
  }
}
