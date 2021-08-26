import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:provider/provider.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/auth_service.dart';

class OthersProfilePage extends StatefulWidget {
  @override
  _OthersProfilePageState createState() => _OthersProfilePageState();
}

class _OthersProfilePageState extends State<OthersProfilePage> {
  User _currentUser;
  CustomClaims customClaims;

  void _loadUserInfo() {
    setState(() async => customClaims = await CustomClaims.getClaims(false));
  }

  @override
  void initState() {
    _currentUser = context.read<User>();
    _loadUserInfo();
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
                ProfileImageBlock(),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.displayName,
                      style: TextStyle(
                        fontFamily: HelveticaFont.Black,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      customClaims.userName ?? "",
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
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
                Text(
                  " Bangladesh",
                  style: TextStyle(
                    fontFamily: HelveticaFont.Roman,
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Add me on Spotify @lexypanterra gram",
              style: TextStyle(
                fontFamily: HelveticaFont.Roman,
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "www.lexygram.com",
              style: TextStyle(
                fontFamily: HelveticaFont.Bold,
                color: Colors.yellow,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.yellow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Message",
                    style: TextStyle(
                      fontFamily: HelveticaFont.Bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
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
          Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }
}
