import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:permission_handler/permission_handler.dart';

class MyServer {
  static const String SERVER_API = "https://us-central1-jynx-chat.cloudfunctions.net/api";
  // static const String SERVER_API = "http://192.168.0.100:5000/jynx-chat/us-central1/api";
  static const String SIGNUP = "/signup";
  static const String UPDATE_USERNAME = "/update-username";
  static Map<String, String> JSON_HEADER = {
    "content-type": "application/json",
    "accept": "application/json",
  };
}

class Constants {
  static const int CHAT_LIST_READ_LIMIT = 10;
  static const int CHAT_ROOM_MESSAGES_READ_LIMIT = 10;

  static const TextStyle SignInHeadingStyle = TextStyle(
    fontSize: 24,
    fontFamily: HelveticaFont.Medium,
    height: 1.5,
  );

  static final InputDecoration OtpInputDecoration = InputDecoration(
    counterText: "",
    contentPadding: EdgeInsets.symmetric(vertical: 15),
    border: outlineInputBorder(false),
    focusedBorder: outlineInputBorder(true),
    enabledBorder: outlineInputBorder(false),
  );

  static OutlineInputBorder outlineInputBorder(bool focused) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: focused ? Colors.blueAccent : Color(0xFF757575)),
    );
  }

  static String convertToTimeAgo(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays >= 7) {
      return '${(diff.inDays / 7).floor()}w';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inSeconds >= 1) {
      return '${diff.inSeconds}s';
    } else {
      return '0s';
    }
  }

  static List<String> createKeywords(text) {
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

  static Future<bool> checkCamMicPermission() async {
    final _camPermStatus = await Permission.camera.status;
    final _micPermStatus = await Permission.microphone.status;
    if (_camPermStatus.isGranted && _micPermStatus.isGranted) return true;

    return false;
  }
}

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

/// Global variables
/// * [GlobalKey<NavigatorState>]
class GlobalVariable {
  /// This global key is used in material app for navigation through firebase notifications.
  /// [navState] usage can be found in [notification_notifier.dart] file.
  static final GlobalKey<NavigatorState> navState = GlobalKey<NavigatorState>();
}

class MyEncryption {
  static const String MY_PADDING_IV_KEY = "ma13[;0-@#w.;987\$/.B8/./;[]6GV\$#AW]b)(&([;p%hJNF4*&(E8SVAmv)(^";
  static const String CHAT_ROOM_MESSAGES_PASSWORD = "L4v3,./;'F5!\$W6#7fP\"uy(A97^bwxEG";

  static String _getModifiedIvPasswordFrom(String initialIV) {
    initialIV = initialIV.substring(0, min(10, initialIV.length));
    var paddingNeeded = 16 - initialIV.length;
    return initialIV + MY_PADDING_IV_KEY.substring(0, paddingNeeded);
  }

  static String getEncryptedString({required String mainString, required String password, required String uid}) {
    final key = encrypt.Key.fromUtf8(password);
    final iv = encrypt.IV.fromUtf8(_getModifiedIvPasswordFrom(uid));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.encrypt(mainString, iv: iv).base64;
  }

  static String getDecryptedString({required String encryptedString, required String password, required String uid}) {
    final key = encrypt.Key.fromUtf8(password);
    final iv = encrypt.IV.fromUtf8(_getModifiedIvPasswordFrom(uid));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt64(encryptedString, iv: iv);
  }
}

Widget buildYellowButton({required Widget child, required Function() onTap, required bool loading, required BuildContext context}) {
  return TextButton(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.yellow),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
    ),
    onPressed: onTap,
    child: Container(
      padding: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: !loading
            ? child
            : SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              ),
      ),
    ),
  );
}
