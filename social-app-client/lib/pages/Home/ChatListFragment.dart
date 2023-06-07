import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_app/modules/RTDUsersChatsList.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modules/constants.dart';
import '../../services/rtd_service.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/pages/MyProfilePage.dart';
import 'package:social_app/pages/RequestsPage.dart';
import 'package:social_app/pages/SearchUsersPage.dart';

class ChatListFragment extends StatelessWidget {
  final User currentUser;
  const ChatListFragment({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatListAppBar(),
        RTDUsersChatsList(
          stream: context.read<RealtimeDatabaseService>().getUsersChatsStream(userUid: currentUser.uid),
          currentUser: currentUser,
          fromRequestList: false,
        ),
      ],
    );
  }
}

class ChatListAppBar extends StatelessWidget {
  final double _padding = 20;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_padding, _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showMaterialModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: MyProfilePage(),
                ),
              );
            },
            child: Image.asset(
              "assets/profile-user.png",
              height: 30,
              width: 30,
            ),
          ),
          SearchBox(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => RequestsPage()),
              );
            },
            child: Image.asset(
              "assets/box.png",
              height: 30,
              width: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, anim1, anim2) => SearchUsersPage(),
                transitionDuration: Duration(milliseconds: 0),
              ));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15),
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(100)),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.white38),
              SizedBox(
                width: 6,
              ),
              Text(
                "Search for friends",
                style: TextStyle(
                  fontFamily: HelveticaFont.Roman,
                  fontSize: 12,
                  color: Colors.white54,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
