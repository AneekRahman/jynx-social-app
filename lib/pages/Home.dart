import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/modules/ChatList.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/MyProfilePage.dart';
import 'package:social_app/pages/RequestsPage.dart';
import 'package:social_app/pages/SearchUsersPage.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/firestore_service.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/HomePage";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User _currentUser;

  @override
  void initState() {
    _currentUser = context.read<User>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Column(
          children: [
            HomeAppBar(),
            ChatsList(
              currentUser: _currentUser,
              emptyChatListMsg: HomeChatListIntro(),
              stream: context
                  .watch<FirestoreService>()
                  .getUserChatsStream(_currentUser.uid, false),
            ),
            RaisedButton(
              onPressed: () {
                context.read<AuthenticationService>().signOut();
              },
              child: Text("Sign out"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeAppBar extends StatelessWidget {
  final double _padding = 20;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_padding,
          _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showMaterialModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: context,
                builder: (context, scrollController) => Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
    Key key,
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
          decoration: BoxDecoration(
              color: Colors.white12, borderRadius: BorderRadius.circular(100)),
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

class HomeChatListIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Icon(Icons.cake),
          Text(
            "Looks like we need some friends in this chat :D",
            style: TextStyle(
                fontFamily: HelveticaFont.Roman, color: Colors.black38),
          )
        ],
      ),
    );
  }
}
