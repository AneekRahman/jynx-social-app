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

import 'SettingsPage.dart';

class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  User? _currentUser;
  bool _uploadingPhotoURL = false;

  void _launchUserWebsite(String websiteUrl) async {
    String url = "https://" + websiteUrl;
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  Future _uploadImageToFirebase(File imageFile) async {
    if (_uploadingPhotoURL) return;
    setState(() {
      _uploadingPhotoURL = true;
    });
    int sizeInBytes = imageFile.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024); // Size in MB
    if (sizeInMb > 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File cannot be larger than 2MB")));
      return;
    }

    try {
      String extension = path.extension(imageFile.path);
      UploadTask uploadTask = FirebaseStorage.instance.ref('/user-files/${_currentUser!.uid}/profile_picture$extension').putFile(imageFile);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Uploading profile picture...'),
        duration: Duration(seconds: 15),
      ));
      uploadTask.snapshotEvents.listen((event) async {
        if (event.state == TaskState.running) {
        } else if (event.state == TaskState.success) {
          try {
            // Get the link
            String downloadLink = await event.ref.getDownloadURL();

            // Update it in the database and firebase auth
            await context.read<FirestoreService>().updateUser(_currentUser!, {
              "photoURL": downloadLink,
            });
            // Update in auth
            await _currentUser!.updatePhotoURL(downloadLink);
            // Refresh the _currentUser
            await _currentUser!.getIdToken(true);
          } catch (e) {
            print(e);
          }
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully updated profile picture!")));
        }
      });
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message!)));
      print(e);
    }
    setState(() {
      _uploadingPhotoURL = false;
    });
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
      body: _currentUser != null
          ? StreamBuilder(
              stream: context.watch<FirestoreService>().getUserDocumentStream(_currentUser!.uid),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.data == null) return Container();
                UserProfileObject _myUserObject =
                    UserProfileObject.fromJson(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfilePageAppBar(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                              _uploadImageToFirebase(File(pickedFile!.path));
                            },
                            child: ProfileImageBlock(
                              photoURL: _myUserObject.photoURL,
                            ),
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
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              if (_myUserObject.location!.isEmpty) {
                                Navigator.push(context, CupertinoPageRoute(builder: (context) => EditProfile(userObject: _myUserObject)));
                              }
                            },
                            child: Text(
                              _myUserObject.location!.isNotEmpty ? _myUserObject.location! : "Add location",
                              style: TextStyle(
                                fontFamily: HelveticaFont.Roman,
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          if (_myUserObject.userBio!.isEmpty) {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => EditProfile(userObject: _myUserObject)));
                          }
                        },
                        child: Text(
                          _myUserObject.userBio!.isNotEmpty ? _myUserObject.userBio! : "Add a bio",
                          style: TextStyle(
                            fontFamily: HelveticaFont.Roman,
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          if (_myUserObject.website!.isEmpty) {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => EditProfile(userObject: _myUserObject)));
                          } else {
                            _launchUserWebsite(_myUserObject.website!);
                          }
                        },
                        child: Text(
                          _myUserObject.website!.isNotEmpty ? _myUserObject.website! : "Add a website",
                          style: TextStyle(
                            fontFamily: HelveticaFont.Bold,
                            color: Colors.yellow,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => EditProfile(userObject: _myUserObject)));
                          },
                          context: context,
                          loading: false),
                      SizedBox(height: 20),
                      Text(
                        "Activities",
                        style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                );
              })
          : Center(
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}

class ProfileImageBlock extends StatelessWidget {
  final String? photoURL;
  const ProfileImageBlock({
    Key? key,
    this.photoURL,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    bool hasImg = photoURL != null && photoURL!.isNotEmpty;

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
                photoURL!,
                height: 110,
                width: 110,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(100)),
            )
          : Container(),
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
          GestureDetector(
            onTap: () {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPage()));
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
