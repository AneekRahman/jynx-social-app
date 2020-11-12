import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/place_picker.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:social_app/models/CustomClaims.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatelessWidget {
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
                child: EditProfileForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileForm extends StatefulWidget {
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
  User _currentUser;
  CustomClaims customClaims = CustomClaims();

  InputDecoration _getInputDecoration({String labelText, Widget prefix}) {
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
    _userNameController.text = customClaims.userName;
    _displayNameController.text = _currentUser.displayName;
    _bioController.text = customClaims.bio ?? "";
    _wwwController.text = customClaims.website ?? "";
    _location = customClaims.location ?? "";
    setState(() => {});
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
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 30),
              padding: EdgeInsets.all(14),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(1000),
              ),
              child: Text(
                "Update",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: HelveticaFont.Bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LocationButton extends StatelessWidget {
  LocationButton({
    Key key,
    this.location,
  }) : super(key: key);
  String location;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        LocationResult result = await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => PlacePicker(
              "AIzaSyBwPACLNRvfWCz5yUvOFJD3mMroUX1p80A",
            ),
          ),
        );

        if (result != null) {}
        // Handle the result in your way
        print("RASULRT: " + result.toString());
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
        ),
        child: Text(
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
      padding: EdgeInsets.fromLTRB(_padding,
          _padding + MediaQuery.of(context).padding.top, _padding, _padding),
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
            style: TextStyle(
                fontFamily: HelveticaFont.Bold,
                fontSize: 16,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}
