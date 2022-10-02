import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/modules/RTDUsersChatsList.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/MyProfilePage.dart';
import 'package:social_app/pages/RequestsPage.dart';
import 'package:social_app/pages/SearchUsersPage.dart';
import 'package:provider/provider.dart';

import '../services/rtd_service.dart';
import 'PublicGroupChatsList.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/HomePage";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User _currentUser;
  // 0 = PublicGroupChatsPage | 1 = RTDUsersChatsList | 2 = MyProfilePage
  int _pageNum = 1;

  Future _saveNewFCMToken(User user) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      context.read<RealtimeDatabaseService>().setFCMToken(token: fcmToken, userUid: user.uid);
    }
  }

  @override
  void initState() {
    _currentUser = context.read<User>();
    _saveNewFCMToken(_currentUser);
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
        body: Stack(
          children: [
            Column(
              children: [
                HomeAppBar(),
                _pageNum == 0 ? PublicGroupChatsList() : SizedBox(),
                _pageNum == 1
                    ? RTDUsersChatsList(
                        stream: context.read<RealtimeDatabaseService>().getUsersChatsStream(userUid: _currentUser.uid),
                        currentUser: _currentUser,
                        fromRequestList: false,
                      )
                    : SizedBox(),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavBar(
                  pageNum: _pageNum,
                  setPageNum: (pageNum) {
                    setState(() {
                      _pageNum = pageNum;
                    });
                  }),
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

class BottomNavBar extends StatelessWidget {
  final int pageNum;
  final Function setPageNum;
  const BottomNavBar({super.key, required this.pageNum, required this.setPageNum});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(100)),
            child: BackdropFilter(
              filter: new ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                decoration: new BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.2),
                ),
                width: MediaQuery.of(context).size.width * .7,
                padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        setPageNum(0);
                      },
                      icon: Opacity(
                        opacity: pageNum == 0 ? 1 : .5,
                        child: Image.asset("assets/icons/People-icon.png"),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setPageNum(1);
                      },
                      icon: Opacity(
                        opacity: pageNum == 1 ? 1 : .5,
                        child: Image.asset("assets/icons/Send-icon-white.png"),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showMaterialModalBottomSheet(
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                            child: MyProfilePage(),
                          ),
                        );
                      },
                      icon: Opacity(
                        opacity: .5,
                        child: Image.asset("assets/icons/User-icon.png"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
