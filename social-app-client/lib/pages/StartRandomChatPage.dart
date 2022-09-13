import 'package:flutter/material.dart';

class StartRandomChatPage extends StatefulWidget {
  const StartRandomChatPage({super.key});

  @override
  State<StartRandomChatPage> createState() => _StartRandomChatPageState();
}

class _StartRandomChatPageState extends State<StartRandomChatPage> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Center(
            child: Text("StartRandomChatPage"),
          ),
        ],
      ),
    );
  }
}
