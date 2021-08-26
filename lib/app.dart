import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/pages/SignInUpPages/IntialSignUpUpdatePage.dart';
import 'package:social_app/pages/SignInUpPages/PhoneSignInPage.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';
import 'pages/Home.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(FirebaseAuth.instance),
        ),
        Provider<RealtimeDatabaseService>(
          create: (_) {
            FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
            firebaseDatabase.setPersistenceEnabled(true);
            firebaseDatabase.setPersistenceCacheSizeBytes(10000000);
            return RealtimeDatabaseService(firebaseDatabase);
          },
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(FirebaseFirestore.instance),
        ),
        StreamProvider(
          create: (context) =>
              context.read<AuthenticationService>().authStateChanges,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.yellow,
          accentColor: Colors.yellow,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          unselectedWidgetColor: Colors.yellow,
        ),
        routes: {
          AuthenticationWrapper.routeName: (context) => AuthenticationWrapper(),
          HomePage.routeName: (context) => HomePage(),
        },
        initialRoute: AuthenticationWrapper.routeName,
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  static final String routeName = "/AuthenticationWrapper";
  @override
  Widget build(BuildContext context) {
    final User firebaseUser = context.watch<User>();

    if (firebaseUser != null) {
      if (firebaseUser.displayName == null ||
          firebaseUser.displayName.isEmpty) {
        return IntialSignUpUpdatePage();
      } else {
        return HomePage();
      }

      // return TestPage();
    } else {
      return PhoneSignInPage();
    }
  }
}
