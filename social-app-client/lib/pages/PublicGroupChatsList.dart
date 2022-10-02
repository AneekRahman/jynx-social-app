import 'package:flutter/material.dart';

class PublicGroupChatsList extends StatefulWidget {
  const PublicGroupChatsList({super.key});

  @override
  State<PublicGroupChatsList> createState() => _PublicGroupChatsListState();
}

class _PublicGroupChatsListState extends State<PublicGroupChatsList> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text("This is PublicGroupChatsList"),
        ],
      ),
    );
  }
}
