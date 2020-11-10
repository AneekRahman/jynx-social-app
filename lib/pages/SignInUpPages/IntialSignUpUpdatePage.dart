import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/auth_service.dart';

class IntialSignUpUpdatePage extends StatefulWidget {
  @override
  _IntialSignUpUpdatePageState createState() => _IntialSignUpUpdatePageState();
}

class _IntialSignUpUpdatePageState extends State<IntialSignUpUpdatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegExp _userNameRegExp = new RegExp("^([a-zA-Z0-9_.]{6,32})\$");
  final RegExp _displayNameRegExp = new RegExp("^([a-zA-Z ]{3,32})\$");
  String _userName = "";
  String _displayName = "";
  FirebaseFirestore _firestoreInstance;
  User _user;
  bool _loading = false;

  void _finishAccount(_context) async {
    if (_loading) return;
    if (_formKey.currentState.validate()) {
      try {
        setState(() {
          _loading = true;
        });

        // Try to Save the /users/ and /takenUserNames/ documents
        await _firestoreInstance.runTransaction((transaction) async {
          transaction
              .set(_firestoreInstance.collection("users").doc(_user.uid), {
            "displayName": _displayName.trim(),
            "userName": _userName.trim(),
            "searchKeywords": [
              ..._createKeywords(_displayName.trim()),
              ..._createKeywords(_userName.trim()),
            ]
          });
          transaction.set(
              _firestoreInstance
                  .collection("takenUserNames")
                  .doc(_userName.trim()),
              {"userUid": _user.uid});
        });

        // Update the displayName
        await _user.updateProfile(displayName: _displayName);

        // Force refresh the Id token to get the userName in the future
        await CustomClaims.getClaims(true);
      } on FirebaseException catch (error) {
        print("Account Finish Error: " + error.toString());
        Scaffold.of(_context).showSnackBar(SnackBar(
          content: Text("The username is already taken"),
        ));
      }
      if (this.mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  List<String> _createKeywords(text) {
    List<String> keywordsList = [];
    // Split the text into words if there are spaces
    text.split(" ").forEach((word) {
      String tempWord = "";
      word.split("").forEach((letter) {
        tempWord += letter;
        if (!keywordsList.contains(tempWord)) keywordsList.add(tempWord);
      });
    });
    return keywordsList;
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Text("Complete Account", style: headingStyle),
                        SizedBox(height: 10),
                        Text(
                          'Select a new username and enter your full name \nto complete the account creation',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                        ),
                        SizedBox(height: 40),
                        TextFormField(
                          onChanged: (value) => _userName = value.trim(),
                          validator: (input) {
                            if (input.length < 6 || input.length > 32) {
                              return "Should be between 6 - 32 characters long";
                            }
                            if (input.isEmpty ||
                                !_userNameRegExp.hasMatch(input)) {
                              return "Usernames must only be Alpha-Numeric, dots or underscores";
                            }
                          },
                          autofocus: true,
                          style: TextStyle(
                              fontFamily: HelveticaFont.Roman, fontSize: 20),
                          decoration: InputDecoration(
                              labelText: "Username",
                              prefix: Text("@"),
                              prefixStyle: TextStyle(
                                  color: Colors.black45, fontSize: 18),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              hintText: "john_doe123",
                              contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) => _displayName = value.trim(),
                          validator: (input) {
                            if (input.length < 3 || input.length > 32) {
                              return "Should be between 3 - 32 characters long";
                            }
                            if (input.isEmpty ||
                                !_displayNameRegExp.hasMatch(input)) {
                              return "Names cannot contain numbers or special characters";
                            }
                          },
                          style: TextStyle(
                              fontFamily: HelveticaFont.Roman, fontSize: 20),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                              labelText: "Full Name",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              hintText: "eg: John Doe",
                              contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) {
                return MyBottomButton(
                  isLoading: _loading,
                  text: "Finish Account",
                  onTap: () {
                    _finishAccount(context);
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
