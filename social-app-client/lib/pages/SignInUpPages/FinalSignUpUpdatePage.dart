import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/auth_service.dart';

class FinalSignUpUpdatePage extends StatefulWidget {
  @override
  _FinalSignUpUpdatePageState createState() => _FinalSignUpUpdatePageState();
}

class _FinalSignUpUpdatePageState extends State<FinalSignUpUpdatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegExp _userNameRegExp = new RegExp("^([a-zA-Z0-9_.]{6,32})\$");
  final RegExp _displayNameRegExp = new RegExp("^([a-zA-Z ]{3,32})\$");
  String _userName = "";
  String _displayName = "";
  late FirebaseFirestore _firestoreInstance;
  User? _user;
  bool _loading = false;

  void _finishAccount(_context) async {
    if (_loading && _user == null) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      try {
        String idToken = await _user!.getIdToken();
        http.Response response = await http.post(
          Uri.parse(MyServer.SERVER_API + MyServer.SIGNUP),
          headers: {"Authorization": idToken, ...MyServer.JSON_HEADER},
          body: json.encode({
            "userName": _userName.trim(),
            "displayName": _displayName.trim(),
          }),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
            content: Text("Welcome, $_displayName!"),
          ));
          // Update the displayName
          await _user!.updateDisplayName(_displayName);
          // Force refresh the Id token to get the userName in the future
          await context.read<AuthenticationService>().currentUserClaims(true);
        } else {
          Map jsonObject = json.decode(response.body);
          ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
            content: Text(jsonObject["message"] ?? "There was an error while, try again!"),
          ));
        }
      } catch (e) {
        print(e.toString());
        ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
          content: Text("There was an error while, try again!"),
        ));
      }
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  void initState() {
    _firestoreInstance = FirebaseFirestore.instance;
    _user = context.read<User>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildForm(context),
              ),
            ),
            Builder(builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: buildYellowButton(
                  child: Text(
                    "Finish Account",
                    style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () async {
                    _finishAccount(context);
                  },
                  loading: _loading,
                  context: context,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Form _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * .05),
            Text("Complete Account", style: singInHeadingStyle),
            SizedBox(height: 10),
            Text(
              'Select a new username and enter your full name to complete the account creation',
              style: Theme.of(context).textTheme.caption,
            ),
            SizedBox(height: 40),
            TextFormField(
              onChanged: (value) => _userName = value.trim(),
              validator: (input) {
                if (input!.length < 6 || input.length > 32) {
                  return "Should be between 6 - 32 characters long";
                }
                if (input.isEmpty || !_userNameRegExp.hasMatch(input)) {
                  return "Usernames must only be Alpha-Numeric, dots or underscores";
                }
              },
              autofocus: true,
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 20),
              decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.white),
                  prefix: Text("@"),
                  prefixStyle: TextStyle(color: Colors.white54, fontSize: 18),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: "john_doe123",
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
            ),
            SizedBox(height: 20),
            TextFormField(
              onChanged: (value) => _displayName = value.trim(),
              validator: (input) {
                if (input!.length < 3 || input.length > 32) {
                  return "Should be between 3 - 32 characters long";
                }
                if (input.isEmpty || !_displayNameRegExp.hasMatch(input)) {
                  return "Names cannot contain numbers or special characters";
                }
              },
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 20),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: Colors.white),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: "eg: John Doe",
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
            ),
          ],
        ),
      ),
    );
  }
}
