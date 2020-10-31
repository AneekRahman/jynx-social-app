import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class PhoneSignInPage extends StatefulWidget {
  @override
  _PhoneSignInPageState createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _phoneNo, _smsCode;
  String _msg = "";

  void _phoneSignIn() {
    _formKey.currentState.save();
    setState(() {
      _msg = "Loading...";
    });
    context
        .read<AuthenticationService>()
        .phoneSignIn(
          smsCode: _smsCode,
        )
        .then((response) {
      setState(() {
        _msg = response;
      });
    });
  }

  void _sendCode() {
    if (_formKey.currentState.validate()) {
      setState(() {
        _msg = "Loading...";
      });
      _formKey.currentState.save();
      context.read<AuthenticationService>().sendPhoneVerificationCode(
          phoneNo: _phoneNo,
          callback: (msg) {
            setState(() {
              _msg = msg;
            });
          });
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            validator: (input) {
              if (input.isEmpty) {
                return 'Enter your phone no';
              }
            },
            decoration: InputDecoration(labelText: 'Phone no'),
            keyboardType: TextInputType.phone,
            onSaved: (input) => _phoneNo = input,
          ),
          TextFormField(
            validator: (input) {
              if (input.isEmpty) {
                return 'Enter the code you recieved';
              }
            },
            decoration: InputDecoration(labelText: 'Sms code'),
            onSaved: (input) => _smsCode = input,
          ),
          Text(_msg ?? "got null"),
          RaisedButton(
            onPressed: () {
              _sendCode();
            },
            child: Text("Send code"),
          ),
          RaisedButton(
            onPressed: () {
              _phoneSignIn();
            },
            child: Text("Sign in using sms code"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Jynx"),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildForm()),
        ],
      ),
    );
  }
}
