import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class EnterNumberPage extends StatefulWidget {
  final Function saveSentPhoneNo;
  EnterNumberPage({required this.saveSentPhoneNo});
  @override
  _EnterNumberPageState createState() => _EnterNumberPageState();
}

class _EnterNumberPageState extends State<EnterNumberPage> {
  final _phoneNumberTextController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _completePhoneNumber = "", _msg = "";
  bool _loading = false;

  void _sendCode() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    // Start loading animation
    setState(() {
      _msg = "";
      _loading = true;
    });

    // Send a phone no verification code
    await context.read<AuthenticationService>().sendPhoneVerificationCode(
        phoneNo: _completePhoneNumber,
        callback: (msg) {
          if (msg == "success") {
            // Go to OTP page after successfully sent code
            widget.saveSentPhoneNo(_completePhoneNumber);
            // Stop loading animation
            setState(() {
              _loading = false;
            });
          } else {
            // Show an error
            setState(() {
              _msg = msg;
              _loading = false;
            });
          }
        });
  }

  Widget _buildForm() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.phone),
            SizedBox(width: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: IntlPhoneField(
                  controller: _phoneNumberTextController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.white),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: "XXX-XXXXXX",
                  ),
                  invalidNumberMessage: 'Please enter a full number',
                  showDropdownIcon: false,
                  flagsButtonPadding: EdgeInsets.only(top: 18),
                  initialCountryCode: 'US',
                  onCountryChanged: (phone) {
                    _phoneNumberTextController.clear();
                  },
                  onChanged: (phone) {
                    _completePhoneNumber = phone.completeNumber;
                    if (_msg.isNotEmpty) {
                      setState(() {
                        _msg = "";
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        _msg.isNotEmpty
            ? Column(
                children: [
                  Text(
                    _msg,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 30),
                ],
              )
            : SizedBox(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * .05),
                  Text("Enter your phone number", style: singInHeadingStyle),
                  SizedBox(height: 20),
                  _buildForm(),
                  Text(
                    'By continuing you confirm that you agree with our Terms and Conditions',
                    style: Theme.of(context).textTheme.caption,
                  )
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: buildYellowButton(
            child: Text(
              "Send code",
              style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            onTap: _sendCode,
            loading: _loading,
            context: context,
          ),
        ),
      ],
    );
  }
}
