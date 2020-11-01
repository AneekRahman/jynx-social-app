import 'package:flutter/material.dart';

final normalTextStyle = TextStyle(
  fontFamily: HelveticaFont.Roman,
);

class HelveticaFont {
  static const String Heavy = "helvetica_heavy";
  static const String Roman = "helvetica_roman";
}

final headingStyle = TextStyle(
  fontSize: 28,
  fontFamily: HelveticaFont.Heavy,
  color: Colors.black,
  height: 1.5,
);

final otpInputDecoration = InputDecoration(
  counterText: "",
  contentPadding: EdgeInsets.symmetric(vertical: 15),
  border: outlineInputBorder(false),
  focusedBorder: outlineInputBorder(true),
  enabledBorder: outlineInputBorder(false),
);

OutlineInputBorder outlineInputBorder(bool focused) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide:
        BorderSide(color: focused ? Colors.blueAccent : Color(0xFF757575)),
  );
}
