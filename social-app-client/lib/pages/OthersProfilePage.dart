import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/ChatMessageRoom.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ChatRoomPage.dart';
import 'MyProfilePage.dart';

class OthersProfilePage extends StatefulWidget {
  final UserFirestore otherUsersProfileObject;
  final bool showMessageButton;
  const OthersProfilePage({required this.otherUsersProfileObject, required this.showMessageButton});
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
      body: StreamBuilder(
        stream: context.watch<FirestoreService>().getUserDocumentStream(widget.otherUsersProfileObject.userUid),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.data == null) return SizedBox();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2)));
          } else if (snapshot.hasData && snapshot.data!.exists) {
            UserFirestore _myUserObject = UserFirestore.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfilePageAppBar(),
                  _buildUserPicNamesRow(_myUserObject),
                  SizedBox(height: 20),
                  _myUserObject.location!.isNotEmpty ? _buildLocationTextRow(_myUserObject) : SizedBox(),
                  SizedBox(height: 10),
                  _buildBioTextRow(_myUserObject),
                  SizedBox(height: 10),
                  _myUserObject.website!.isNotEmpty ? _buildWebsiteTextRow(_myUserObject) : SizedBox(),
                  SizedBox(height: 20),
                  widget.showMessageButton
                      ? buildYellowButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble, size: 18, color: Colors.black),
                              SizedBox(width: 10),
                              Text(
                                "Message",
                                style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 14, color: Colors.black),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => ChatMessageRoom(
                                  currentUser: _currentUser!,
                                  otherUser: widget.otherUsersProfileObject,
                                  fromRequestList: false,
                                ),
                              ),
                            );
                          },
                          context: context,
                          loading: false)
                      : SizedBox(),
                  SizedBox(height: 20),
                  // Text(
                  //   "Activities",
                  //   style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.white),
                  // ),
                ],
              ),
            );
          } else {
            return Center(child: Text("There was an error, try again", style: TextStyle(color: Colors.white)));
          }
        },
      ),
    );
  }

  GestureDetector _buildWebsiteTextRow(UserFirestore _myUserObject) {
    return GestureDetector(
      onTap: () {
        if (!_myUserObject.website!.isEmpty) {
          _launchUserWebsite(_myUserObject.website!);
        }
      },
      child: Text(
        _myUserObject.website!,
        style: TextStyle(
          fontFamily: HelveticaFont.Bold,
          color: Colors.yellow,
          fontSize: 14,
        ),
      ),
    );
  }

  Text _buildBioTextRow(UserFirestore _myUserObject) {
    return Text(
      _myUserObject.userBio!.isNotEmpty ? _myUserObject.userBio! : "There was no bio added...",
      style: TextStyle(
        fontFamily: HelveticaFont.Roman,
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Row _buildLocationTextRow(UserFirestore _myUserObject) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.white,
          size: 18,
        ),
        SizedBox(width: 4),
        Text(
          _myUserObject.location!,
          style: TextStyle(
            fontFamily: HelveticaFont.Roman,
            color: Colors.white38,
            fontSize: 14,
          ),
        )
      ],
    );
  }

  Row _buildUserPicNamesRow(UserFirestore _myUserObject) {
    return Row(
      children: [
        ProfileImageBlock(
          photoURL: _myUserObject.photoURL,
        ),
        SizedBox(
          width: 20,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _myUserObject.displayName ?? "",
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
        ),
      ],
    );
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
