import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UsersChatRooms.dart';
import 'package:social_app/modules/UsersChatRoomsRow.dart';

import '../pages/ChatRoomPage.dart';
import '../services/rtd_service.dart';
import 'LoadingBar.dart';

class RTDUsersChatsList extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final User currentUser;
  RTDUsersChatsList({required this.stream, required this.currentUser});
  @override
  State<RTDUsersChatsList> createState() => _RTDUsersChatsListState();
}

class _RTDUsersChatsListState extends State<RTDUsersChatsList> {
  List<ChatRoomsInfos> _chatRoomsInfosList = [];
  bool _loading = true;

  void listPreAddDuplicateRemoval(String chatRoomUid) {
    for (var i = 0; i < _chatRoomsInfosList.length; i++) {
      if (_chatRoomsInfosList[i].chatRoomUid == chatRoomUid) {
        print("GOT Remove at: " + chatRoomUid);
        _chatRoomsInfosList.removeAt(i);
      }
    }
  }

  void initUsersChatRoomsStreamListener() {
    widget.stream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        print("GOT usersChatRooms: " + event.snapshot.value.toString());

        final usersChatRoomsList = UsersChatRooms.fromMap(event.snapshot.value as Map);
        getChatRoomsInfosFromUids(usersChatRoomsList);
      }
    });
  }

  Future getChatRoomsInfosFromUids(UsersChatRooms usersChatRoomList) async {
    List<Future<DataSnapshot>> _promises = [];

    usersChatRoomList.usersChatRooms.forEach((UsersChatRoom usersChatRoom) {
      _promises.add(context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: usersChatRoom.chatRoomUid));
    });

    List<DataSnapshot> chatRoomsInfosList = await Future.wait(_promises);

    print("GOT chatRoomsInfos: " + chatRoomsInfosList.toString());

    for (var i = 0; i < chatRoomsInfosList.length; i++) {
      final element = chatRoomsInfosList[i];
      if (element.exists) {
        listPreAddDuplicateRemoval(element.key!);
        _chatRoomsInfosList.add(ChatRoomsInfos.fromMap(
          element.value as Map,
          chatRoomUid: element.key!,
          seenByThisUser: usersChatRoomList.usersChatRooms[i].seen,
        ));
      }
    }
    setState(() {
      if (_loading) _loading = false;
    });
  }

  @override
  void initState() {
    initUsersChatRoomsStreamListener();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          LoadingBar(
            loading: _loading,
          ),
          Expanded(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      ChatRoomsInfos chatRoomsInfos = _chatRoomsInfosList[index];

                      return TextButton(
                          onPressed: () {
                            // Navigator.push(
                            //   context,
                            //   CupertinoPageRoute(
                            //       builder: (context) => ChatRoomPage(
                            //             chatRow: chatRow,
                            //             otherUser: chatRow.otherUser,
                            //           )),
                            // );
                          },
                          child: UsersChatRoomsRow(
                            chatRoomsInfos: chatRoomsInfos,
                            currentUser: widget.currentUser,
                          ));
                    },
                    childCount: _chatRoomsInfosList.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
