import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_app/pages/ChatMessageRoom/ChatMessageRoom.dart';
import 'package:social_app/pages/ChatMessageRoom/VideoCallPage.dart';
import 'app.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

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
  final int id = fcmNotifcation.hashCode;
  // Create the incoming call notification
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: 'incoming_call_channel',
      title: 'Incoming call...',
      body: fcmNotifcation.usersName! + " is calling you.",
      payload: {
        "chatRoomUid": fcmNotifcation.chatRoomUid!,
        "usersName": fcmNotifcation.usersName!,
        "usersPhotoURL": fcmNotifcation.usersPhotoURL!,
      },
      largeIcon: fcmNotifcation.usersPhotoURL,
      roundedLargeIcon: true,
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Call,
      criticalAlert: true,
      autoDismissible: true,
    ),
  );

  // Remove the incoming call notification since it cant be removed by the user
  await Future.delayed(Duration(seconds: 20));
  await AwesomeNotifications().cancel(id);
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
      largeIcon: fcmNotifcation.usersPhotoURL,
      roundedLargeIcon: true,
      summary: 'Messages',
      notificationLayout: NotificationLayout.Messaging,
      category: NotificationCategory.Message,
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
        importance: NotificationImportance.Max,
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
    if (notification.payload!["chatRoomUid"] == null) return;
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
      FCMNotifcation fcmNotifcation = FCMNotifcation(
        chatRoomUid: notification.payload!["chatRoomUid"],
        usersName: notification.payload!["usersName"],
        usersPhotoURL: notification.payload!["usersPhotoURL"],
      );
      Navigator.of(GlobalVariable.navState.currentContext!).push(
        CupertinoPageRoute(
            builder: (context) => VideoCallPage(
                  shouldCreateOffer: false,
                  fcmNotifcation: fcmNotifcation,
                )),
      );
    }
  });
}

Future<void> _firebaseMessagingForegroungHandler(RemoteMessage message) async {
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    print("Handling a foreground message: ${message.toMap()} for ${currentUser.displayName}");
    final FCMNotifcation fcmNotifcation = FCMNotifcation.fromJson(message.data);

    if (fcmNotifcation.notiType == NotificationType.INCOMING_CALL) {
      // If this is an /incomingCall/ notification
      _showIncomingCallNotification(fcmNotifcation);
    }
  }
}

Future<void> main() async {
  // First bind flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the AwesomeNotification for listening [actionStream] tap listener
  await _initializeNotifications();
  _listenToAwesomeNotiTaps();

  // Create the background listener for notification (when app is in the background or terminated)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize firebase
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();

  // When the app is in the foreground this will run
  FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroungHandler);

  runApp(MyApp());

  // Request notification permission if not already
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
}
