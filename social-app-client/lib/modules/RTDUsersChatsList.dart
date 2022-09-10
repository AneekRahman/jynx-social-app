import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UsersChatRooms.dart';
import 'package:social_app/modules/UsersChatRoomsRow.dart';
import 'package:social_app/pages/ChatMessageRoom.dart';

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

  void initUsersChatRoomsStreamListener() {
    widget.stream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final usersChatRoomsList = UsersChatRooms.fromMap(event.snapshot.value as Map);
        getChatRoomsInfosFromUids(usersChatRoomsList);
      } else {
        // There were no chatRooms found for this user
        setState(() {
          if (_loading) _loading = false;
        });
      }
    });
  }

  void listPreAddDuplicateRemoval(String chatRoomUid) {
    for (var i = 0; i < _chatRoomsInfosList.length; i++) {
      if (_chatRoomsInfosList[i].chatRoomUid == chatRoomUid) {
        _chatRoomsInfosList.removeAt(i);
        print("GOT: removed: " + chatRoomUid);
      }
    }
  }

  Future getChatRoomsInfosFromUids(UsersChatRooms usersChatRoomList) async {
    print("GOT total usersChatRoomList: ${usersChatRoomList.usersChatRooms.length}");
    List<Future<DataSnapshot>> _promises = [];

    usersChatRoomList.usersChatRooms.forEach((UsersChatRoom usersChatRoom) {
      _promises.add(context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: usersChatRoom.chatRoomUid));
    });

    /// The order of entries in [chatRoomsInfosList] matches the order of entries in [usersChatRoomList] which were given
    /// So, looping through will have both lists index match each other!
    List<DataSnapshot> chatRoomsInfosList = await Future.wait(_promises);

    /// First, add the newest version of the entry and remove the older version. Also map [seenByThisUser]
    for (var i = 0; i < chatRoomsInfosList.length; i++) {
      final element = chatRoomsInfosList[i];
      if (element.exists) {
        /// [listPreAddDuplicateRemoval] loops through [_chatRoomsInfosList] to find if [element.key] matches any element
        /// then it removes [element] and then we can add the newest version.
        listPreAddDuplicateRemoval(element.key!);
        _chatRoomsInfosList.add(ChatRoomsInfos.fromMap(
          element.value as Map,
          chatRoomUid: element.key!,
          seenByThisUser: usersChatRoomList.usersChatRooms[i].seen,
        ));
      }
    }

    /// Secondly, sort the new [_chatRoomsInfosList] from newest to the oldest
    _chatRoomsInfosList.sort((a, b) => b.lTime.compareTo(a.lTime));

    /// Use [setState] to update the UI
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
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => ChatMessageRoom(
                                        chatRoomsInfos: chatRoomsInfos,
                                        currentUser: widget.currentUser,
                                      )),
                            );
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
