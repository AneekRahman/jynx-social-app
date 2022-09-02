import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/models/UserProfileObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/modules/flutter_google_places/flutter_google_places.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'package:google_maps_webservice/places.dart';

import '../services/auth_service.dart';

class EditProfile extends StatelessWidget {
  UserProfileObject userObject;
  EditProfile({required this.userObject});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            EditProfileAppBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: EditProfileForm(userObject: userObject),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileForm extends StatefulWidget {
  UserProfileObject userObject;
  EditProfileForm({required this.userObject});
  @override
  _EditProfileFormState createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  GlobalKey<FormState> _formKey = GlobalKey();
  TextStyle _labelTextStyle = TextStyle(color: Colors.white30);
  TextEditingController _userNameController = TextEditingController();
  TextEditingController _displayNameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _wwwController = TextEditingController();
  String _location = "";

  final RegExp _userNameRegExp = new RegExp("^([a-zA-Z0-9_.]{6,32})\$");
  final RegExp _displayNameRegExp = new RegExp("^([a-zA-Z ]{3,32})\$");
  User? _currentUser;
  CustomClaims customClaims = CustomClaims();
  bool _loading = false;

  InputDecoration _getInputDecoration({required String labelText, Widget? prefix}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: _labelTextStyle,
      prefix: prefix ?? Text(""),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  void _setupInitialData() async {
    customClaims = await CustomClaims.getClaims(false);
    _userNameController.text = customClaims.userName ?? "";
    _displayNameController.text = _currentUser!.displayName ?? "";
    _bioController.text = widget.userObject.userBio ?? "";
    _wwwController.text = widget.userObject.website ?? "";
    _location = widget.userObject.location ?? "";
    setState(() => {});
  }

  Future _updateProfile(_context) async {
    if (_loading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });

      bool updateUserName = customClaims.userName!.trim() != _userNameController.text.trim();
      String newDisplayName = _displayNameController.text.trim();
      String newUserName = _userNameController.text.trim();

      try {
        // If the userName was changed, then update it!
        if (updateUserName) {
          String idToken = await _currentUser!.getIdToken();
          // Update userName using Server API
          http.Response response = await http.post(
            Uri.parse(MyServer.SERVER_API + MyServer.UPDATE_USERNAME),
            headers: {"Authorization": idToken, ...MyServer.JSON_HEADER},
            body: json.encode({
              "userName": newUserName,
            }),
          );
          if (response.statusCode != 200) {
            // ERROR From Server
            Map jsonObject = json.decode(response.body);
            ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
              content: Text(jsonObject["message"] ?? "There was an error, try again!"),
            ));
          }
        }
        // Update the displayName
        await _currentUser!.updateDisplayName(newDisplayName);
        // Force refresh the Id token to get the userName in the future
        await context.read<AuthenticationService>().currentUserClaims(true);
        // Update in Firestore
        await context.read<FirestoreService>().updateUser(_currentUser!, {
          "displayName": newDisplayName,
          "location": _location,
          "userBio": _bioController.text,
          "website": _wwwController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Updated profile!"),
        ));
      } on FirebaseException catch (e) {
        print(e.toString());
        ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
          content: Text("There was an error while, try again!"),
        ));
      }

      if (this.mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  void initState() {
    _currentUser = context.read<User>();
    _setupInitialData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _userNameController,
              validator: (input) {
                if (input!.length < 6 || input.length > 32) {
                  return "Should be between 6 - 32 characters long";
                }
                if (input.isEmpty || !_userNameRegExp.hasMatch(input)) {
                  return "Usernames must only be Alpha-Numeric, dots or underscores";
                }
              },
              style: TextStyle(color: Colors.white),
              decoration: _getInputDecoration(
                labelText: "Username",
                prefix: Text(
                  "@",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: _displayNameController,
              validator: (input) {
                if (input!.length < 3 || input.length > 32) {
                  return "Should be between 3 - 32 characters long";
                }
                if (input.isEmpty || !_displayNameRegExp.hasMatch(input)) {
                  return "Names cannot contain numbers or special characters";
                }
              },
              style: TextStyle(color: Colors.white),
              decoration: _getInputDecoration(labelText: "Display Name"),
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: _bioController,
              style: TextStyle(color: Colors.white),
              decoration: _getInputDecoration(labelText: "Bio"),
            ),
            SizedBox(height: 5),
            TextFormField(
              controller: _wwwController,
              style: TextStyle(color: Colors.white),
              decoration: _getInputDecoration(
                labelText: "Website",
                prefix: Text(
                  "https://",
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 10),
            LocationButton(
                location: _location,
                setLocation: (location) {
                  setState(() => _location = location);
                }),
            SizedBox(height: 30),
            Builder(
              builder: (_context) {
                return buildYellowButton(
                  child: Text(
                    "Update",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: HelveticaFont.Bold),
                  ),
                  onTap: () {
                    _updateProfile(_context);
                  },
                  context: context,
                  loading: _loading,
                );
              },
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class LocationButton extends StatelessWidget {
  String location;
  Function setLocation;
  LocationButton({
    Key? key,
    required this.location,
    required this.setLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: ListTile(
        onTap: () async {
          Prediction? result = await PlacesAutocomplete.show(
              context: context,
              apiKey: "AIzaSyDXy4pdfJRGz9Vy2MbW6C4kSYhAUL9BAwM",
              mode: Mode.overlay, // Mode.fullscreen
              language: "en",
              hint: "Search for places...",
              components: []);

          if (result != null) {
            setLocation(result.description);
          }
        },
        trailing: location.length > 0
            ? GestureDetector(
                onTap: () {
                  setLocation("");
                },
                child: Icon(Icons.close, color: Colors.white))
            : null,
        title: Text(
          location.isEmpty ? "Add location" : location,
          style: TextStyle(
            color: location.isEmpty ? Colors.white30 : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class EditProfileAppBar extends StatelessWidget {
  final double _padding = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_padding, _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            "Edit Profile",
            style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
