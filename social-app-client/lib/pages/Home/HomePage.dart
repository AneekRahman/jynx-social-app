import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/pages/Home/ChatListFragment.dart';
import 'package:social_app/pages/ProfilePage/MyProfilePage.dart';
import 'package:provider/provider.dart';

import '../../services/rtd_service.dart';
import 'VideosFragment.dart';

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
            _pageNum == 0 ? VideosFragment() : SizedBox(),
            _pageNum == 1 ? ChatListFragment(currentUser: _currentUser) : SizedBox(),
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
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        setPageNum(0);
                      },
                      child: Opacity(
                        opacity: pageNum == 0 ? 1 : .5,
                        child: Image.asset("assets/icons/People-icon.png", height: 30),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
                      onPressed: () {
                        setPageNum(1);
                      },
                      child: Opacity(
                        opacity: pageNum == 1 ? 1 : .5,
                        child: Image.asset("assets/icons/Send-icon-white.png", height: 30),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.all(0),
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
                      child: Opacity(
                        opacity: .5,
                        child: Image.asset("assets/icons/User-icon.png", height: 30),
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
