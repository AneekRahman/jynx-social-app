import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_app/pages/ChatMessageRoom.dart';
import 'package:social_app/pages/VideoCallPage.dart';
import 'app.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:math' as Math;

import 'models/FCMNotification.dart';
import 'modules/constants.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    print("Handling a background message: ${message.toMap()} for ${currentUser.displayName}");
    // Initialize showing notifications
    await _initializeNotifications();
    final FCMNotifcation fcmNotifcation = FCMNotifcation.fromJson(message.data);

    if (fcmNotifcation.notiType == NotificationType.INCOMING_CALL) {
      // If this is an /incomingCall/ notification
      _showIncomingCallNotification(fcmNotifcation);
    } else if (fcmNotifcation.notiType == NotificationType.MESSAGE_ADDED) {
      // If this is an /messages/ notification
      _showMessageAddedNotification(fcmNotifcation);
    }
  }
}

void _showIncomingCallNotification(FCMNotifcation fcmNotifcation) async {
  // Create the notification
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: fcmNotifcation.hashCode,
      channelKey: 'incoming_call_channel',
      title: 'Incoming call...',
      body: fcmNotifcation.usersName! + " is calling you.",
      payload: {
        "chatRoomUid": fcmNotifcation.chatRoomUid!,
      },
      largeIcon: fcmNotifcation.usersPhotoURL,
      roundedBigPicture: true,
      notificationLayout: NotificationLayout.Default,
    ),
  );
}

void _showMessageAddedNotification(FCMNotifcation fcmNotifcation) async {
  // Create the notification
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: fcmNotifcation.hashCode,
      groupKey: fcmNotifcation.chatRoomUid,
      channelKey: 'new_messages_channel',
      title: fcmNotifcation.usersName,
      body: fcmNotifcation.msg,
      payload: {
        "chatRoomUid": fcmNotifcation.chatRoomUid!,
      },
      largeIcon: "https://rubygarage.s3.amazonaws.com/uploads/article_image/file/2903/custom-design-1x.png",
      roundedLargeIcon: true,
      summary: 'New messages',
      notificationLayout: NotificationLayout.Messaging,
    ),
  );
}

Future _initializeNotifications() async {
  // Initialize the notification channels
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
      NotificationChannel(
        channelKey: 'new_messages_channel',
        channelName: 'New Messages Notifications',
        channelDescription: "",
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );
}

void _listenToAwesomeNotiTaps() {
  AwesomeNotifications().actionStream.listen((notification) {
    print("Handling AwesomeNotifications:actionStream: ${notification.toMap()}");
    // When the notification is for a new message
    if (notification.channelKey == "new_messages_channel") {
      Navigator.of(GlobalVariable.navState.currentContext!).push(
        CupertinoPageRoute(
            builder: (context) => ChatMessageRoom(
                  fromRequestList: false,
                  chatRoomsUid: notification.payload!["chatRoomUid"],
                )),
      );
    }
    // When the notification is for an incoming call
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
  // Initialize the AwesomeNotification for listening [actionStream] tap listener
  await _initializeNotifications();
  _listenToAwesomeNotiTaps();

  // Create the background listener for notification (when app is in the background or terminated)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FirebaseMessaging.onMessage.listen((event) {});

  // Initialize firebase
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();

  runApp(MyApp());

  // Request notification permission if not already
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
}
