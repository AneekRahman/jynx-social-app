import 'package:flutter/material.dart';

final normalTextStyle = TextStyle(
  fontFamily: HelveticaFont.Roman,
);

class HelveticaFont {
  static const String UltraLight = "helvetica_ultra_light";
  static const String Thin = "helvetica_thin";
  static const String Light = "helvetica_light";
  static const String Roman = "helvetica_roman";
  static const String Medium = "helvetica_medium";
  static const String Bold = "helvetica_bold";
  static const String Heavy = "helvetica_heavy";
  static const String Black = "helvetica_black";
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

String getOneOnOneChatUid(String userUid1, userUid2) {
  // The greaterString:smallerString
  if (userUid1.compareTo(userUid2) == 1) {
    return userUid1 + ":" + userUid2;
  } else {
    return userUid2 + ":" + userUid1;
  }
}
