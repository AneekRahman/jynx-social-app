import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class VideosCommentsModal extends StatefulWidget {
  const VideosCommentsModal({super.key});

  @override
  State<VideosCommentsModal> createState() => _VideosCommentsModalState();
}

class _VideosCommentsModalState extends State<VideosCommentsModal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          VideosCommentsModalAppBar(),
        ],
      ),
    );
  }
}

class VideosCommentsModalAppBar extends StatelessWidget {
  const VideosCommentsModalAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}
