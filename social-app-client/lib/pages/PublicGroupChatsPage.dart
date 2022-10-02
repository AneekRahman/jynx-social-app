import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class PublicGroupChatsPage extends StatefulWidget {
  const PublicGroupChatsPage({super.key});

  @override
  State<PublicGroupChatsPage> createState() => _PublicGroupChatsPageState();
}

class _PublicGroupChatsPageState extends State<PublicGroupChatsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Text("This is PublicGroupChatsPage"),
      ),
    );
  }
}
