import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:provider/provider.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/EditProfile.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'SettingsPage.dart';

class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  User _currentUser;
  MyUserObject _myUserObject = MyUserObject();

  void _loadUserInfo() async {
    _currentUser = context.read<User>();
    CustomClaims customClaims = await CustomClaims.getClaims(false);
    _myUserObject.userName = customClaims.userName;
    _myUserObject.displayName = _currentUser.displayName;
    _myUserObject.profilePic = _currentUser.photoURL;
    setState(() => {});
  }

  // void _loadUserMetaData() async {
  //   UserDocumentStream userDocumentStream = context.watch<UserDocumentStream>();
  //   MyUserObject userObject = MyUserObject.fromJson(userDocumentStream.data());
  //   setState(() => _myUserObject = userObject);
  // }

  void _launchUserWebsite() async {
    if (_myUserObject.userMeta == null) return;
    String url = "https://" + _myUserObject.userMeta["website"];
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    _loadUserInfo();
    // _loadUserMetaData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1f1f1f),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfilePageAppBar(),
            Row(
              children: [
                ProfileImageBlock(
                  profilePic: _myUserObject.profilePic,
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _myUserObject.displayName,
                      style: TextStyle(
                        fontFamily: HelveticaFont.Bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _myUserObject.userName ?? "",
                      style: TextStyle(
                        fontFamily: HelveticaFont.Medium,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _myUserObject.userMeta != null
                ? Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _myUserObject.userMeta["location"].isNotEmpty
                            ? _myUserObject.userMeta["location"]
                            : "Add location",
                        style: TextStyle(
                          fontFamily: HelveticaFont.Roman,
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Container(),
            SizedBox(height: 10),
            _myUserObject.userMeta != null
                ? Text(
                    _myUserObject.userMeta["bio"].isNotEmpty
                        ? _myUserObject.userMeta["bio"]
                        : "Add a bio",
                    style: TextStyle(
                      fontFamily: HelveticaFont.Roman,
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                : Container(),
            SizedBox(height: 10),
            _myUserObject.userMeta != null
                ? GestureDetector(
                    onTap: () {
                      _launchUserWebsite();
                    },
                    child: Text(
                      _myUserObject.userMeta["website"].isNotEmpty
                          ? _myUserObject.userMeta["website"]
                          : "Add a website",
                      style: TextStyle(
                        fontFamily: HelveticaFont.Bold,
                        color: Colors.yellow,
                        fontSize: 14,
                      ),
                    ),
                  )
                : Container(),
            SizedBox(height: 20),
            buildYellowButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontFamily: HelveticaFont.Bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (context) =>
                              EditProfile(userObject: _myUserObject)));
                },
                context: context,
                loading: false),
          ],
        ),
      ),
    );
  }
}

class ProfileImageBlock extends StatelessWidget {
  const ProfileImageBlock({
    Key key,
    this.profilePic,
  }) : super(key: key);
  final String profilePic;
  @override
  Widget build(BuildContext context) {
    bool hasImg = profilePic != null && profilePic.isNotEmpty;

    return Container(
      height: 110,
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10000),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: hasImg
          ? ClipRRect(
              child: Image.network(
              profilePic,
              height: 110,
              width: 110,
            ))
          : Container(),
    );
  }
}

class ProfilePageAppBar extends StatelessWidget {
  const ProfilePageAppBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 36,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  CupertinoPageRoute(builder: (context) => SettingsPage()));
            },
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
