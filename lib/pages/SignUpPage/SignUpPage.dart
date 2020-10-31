import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/SignUpPage/OTP/OtpPage.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController _phoneTextEditController = TextEditingController();
  String _dialCode, _phoneNo, _msg = "";
  bool _loading = false;

  void _sendCode() {
    if (_loading) return;
    if (_phoneNo == null ||
        _phoneNo.isEmpty ||
        _phoneNo.length - _dialCode.length <= 0) {
      setState(() {
        _msg = "Enter a phone number";
      });
      return;
    }

    // Start loading animation
    setState(() {
      _msg = "";
      _loading = true;
    });

    context.read<AuthenticationService>().sendPhoneVerificationCode(
        phoneNo: _phoneNo,
        callback: (msg) {
          if (msg == "success") {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OtpPage(phoneNo: _phoneNo)));
          } else {
            setState(() {
              _msg = msg;
              _loading = false;
            });
          }
        });
  }

  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          InternationalPhoneNumberInput(
            inputDecoration: InputDecoration(
              labelText: "Phone",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: "Enter your number",
            ),
            onInputChanged: (PhoneNumber number) {
              _phoneNo = number.phoneNumber;
              _dialCode = number.dialCode;
            },
            selectorConfig: SelectorConfig(
              selectorType: PhoneInputSelectorType.DIALOG,
            ),
            ignoreBlank: false,
            selectorTextStyle: TextStyle(color: Colors.black, fontSize: 18),
            textStyle: TextStyle(fontSize: 18),
            textFieldController: _phoneTextEditController,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text("Create Account", style: headingStyle),
                    SizedBox(height: MediaQuery.of(context).size.height * .06),
                    _buildForm(),
                    SizedBox(height: 10),
                    Text(
                      _msg ?? "",
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'By continuing your confirm that you agree \nwith our Terms and Conditions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    )
                  ],
                ),
              ),
            ),
            MyBottomButton(
              text: "Get Code",
              onTap: () {
                _sendCode();
              },
            )
          ],
        ),
      ),
    );
  }
}
