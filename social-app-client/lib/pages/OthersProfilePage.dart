import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/UserProfileObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/EditProfile.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';

import 'ChatRoomPage.dart';
import 'MyProfilePage.dart';
import 'SettingsPage.dart';

class OthersProfilePage extends StatefulWidget {
  final UserProfileObject otherUsersProfileObject;
  const OthersProfilePage({required this.otherUsersProfileObject});
  @override
  _OthersProfilePageState createState() => _OthersProfilePageState();
}

class _OthersProfilePageState extends State<OthersProfilePage> {
  User? _currentUser;

  void _launchUserWebsite(String websiteUrl) async {
    String url = "https://" + websiteUrl;
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    _currentUser = context.read<User?>();
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
                    photoURL: widget.otherUsersProfileObject.photoURL,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.otherUsersProfileObject.displayName ?? "",
                          style: TextStyle(
                            fontFamily: HelveticaFont.Bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          widget.otherUsersProfileObject.userName ?? "",
                          style: TextStyle(
                            fontFamily: HelveticaFont.Medium,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              widget.otherUsersProfileObject.location!.isNotEmpty
                  ? Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          widget.otherUsersProfileObject.location!,
                          style: TextStyle(
                            fontFamily: HelveticaFont.Roman,
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        )
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              widget.otherUsersProfileObject.userBio!.isNotEmpty
                  ? Text(
                      widget.otherUsersProfileObject.userBio!,
                      style: TextStyle(
                        fontFamily: HelveticaFont.Roman,
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              widget.otherUsersProfileObject.website!.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        if (!widget.otherUsersProfileObject.website!.isEmpty) {
                          _launchUserWebsite(widget.otherUsersProfileObject.website!);
                        }
                      },
                      child: Text(
                        widget.otherUsersProfileObject.website!,
                        style: TextStyle(
                          fontFamily: HelveticaFont.Bold,
                          color: Colors.yellow,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 20),
              buildYellowButton(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ChatRoomPage(
                          otherUser: widget.otherUsersProfileObject,
                        ),
                      ),
                    );
                  },
                  context: context,
                  loading: false),
              SizedBox(height: 20),
              // Text(
              //   "Activities",
              //   style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.white),
              // ),
            ],
          ),
        ));
  }
}

class ProfilePageAppBar extends StatelessWidget {
  const ProfilePageAppBar({
    Key? key,
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
        ],
      ),
    );
  }
}
