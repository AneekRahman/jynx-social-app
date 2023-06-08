import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class VideosList extends StatefulWidget {
  const VideosList({super.key});

  @override
  State<VideosList> createState() => _VideosListState();
}

class _VideosListState extends State<VideosList> {
  PageController controller = PageController();
  int _currentPage = 0;

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
          });
        },
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.teal,
            ),
            child: Center(
              child: Text("Page One"),
            ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
            ),
            child: Center(
              child: Text("Page Two"),
            ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey,
            ),
            child: Center(
              child: Text("Page Three"),
            ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
            ),
            child: Center(
              child: Text("Page Four"),
            ),
          ),
        ],
      ),
    );
  }
}
