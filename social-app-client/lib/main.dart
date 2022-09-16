import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_app/pages/VideoCallPage.dart';
import 'app.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:math' as Math;

import 'models/IncomingCall.dart';
import 'modules/constants.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    _showIncomingCallNotification(message);
    print("Handling a background message: ${message.toMap()} for ${currentUser.displayName}");
  }
}

void _showIncomingCallNotification(RemoteMessage message) async {
  final FCMNotifcation fcmNotifcation = FCMNotifcation.fromJson(message.data);

  // If this is an /incomingCall/ notification
  if (fcmNotifcation.notiType == NotificationType.INCOMING_CALL) {
    // Initialize showing notifications
    await _initializeNotifications();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Math.Random().nextInt(9999),
        channelKey: 'incoming_call_channel',
        title: 'Incoming call...',
        body: fcmNotifcation.callerName! + " is calling you.",
        payload: {
          "chatRoomUid": fcmNotifcation.chatRoomUid!,
        },
        largeIcon: fcmNotifcation.callerPhotoURL,
        roundedBigPicture: true,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}

Future _initializeNotifications() async {
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'incoming_call_channel',
        channelName: 'Incoming Call Notifications',
        channelDescription: "",
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );

  // Listen to taps for [onMessageAdded] or [onIncomingCall]
  AwesomeNotifications().actionStream.listen((notification) {
    print("Handling AwesomeNotifications:actionStream: ${notification.toMap()}");
    if (notification.channelKey == "incoming_call_channel") {
      Navigator.of(GlobalVariable.navState.currentContext!).push(
        CupertinoPageRoute(
            builder: (context) => VideoCallPage(
                  shouldCreateOffer: false,
                  notificationChatRoomUid: notification.payload!["chatRoomUid"],
                )),
      );
    }
  });
}

Future<void> main() async {
  // First bind flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Create the background listener for notification (when app is in the background or terminated)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Initialize the AwesomeNotification for listening [actionStream] tap listener
  await _initializeNotifications();

  // FirebaseMessaging.onMessage.listen((event) {});

  // Initialize firebase
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();

  runApp(MyApp());
}
