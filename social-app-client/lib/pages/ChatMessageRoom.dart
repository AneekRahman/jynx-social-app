import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';

class ChatMessageRoom extends StatefulWidget {
  // if chatRoomsInfos if null, then search for the chatRoomUid in Firestore using the otherUserUid and thisUserUid
  ChatRoomsInfos? chatRoomsInfos;
  final User currentUser;
  final String otherUserUid, otherUserName, otherUserUsername, chatRoomPhotoURL;

  ChatMessageRoom({
    super.key,
    this.chatRoomsInfos,
    required this.currentUser,
    required this.otherUserUid,
    required this.otherUserName,
    required this.otherUserUsername,
    required this.chatRoomPhotoURL,
  });

  @override
  State<ChatMessageRoom> createState() => _ChatMessageRoomState();
}

class _ChatMessageRoomState extends State<ChatMessageRoom> {
  bool noChatRoomFound = false;

  Future getChatRoomInfos() async {
    final firestoreChatRecord = await context.read<FirestoreService>().findPrivateChatWithUser(
          widget.currentUser.uid,
          widget.otherUserUid,
        );

    if (firestoreChatRecord.docs.isNotEmpty) {
      final rtdSnapshot =
          await context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: firestoreChatRecord.docs[0].id);

      print("GOT INFO: " + rtdSnapshot.key!.toString());
      if (rtdSnapshot.exists) {
        widget.chatRoomsInfos = ChatRoomsInfos.fromMap(
          rtdSnapshot.value as Map,
          chatRoomUid: rtdSnapshot.key!,
        );
        if (mounted) setState(() {});
      } else {
        if (mounted)
          setState(() {
            noChatRoomFound = true;
          });
      }
    }
  }

  @override
  void initState() {
    if (widget.chatRoomsInfos == null) {
      getChatRoomInfos();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          body: Column(
            children: [
              _buildTopBar(),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildTopBar() {
    return Container(
      child: Row(
        children: [],
      ),
    );
  }
}
