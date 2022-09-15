import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics;

  const AnalyticsService(this._firebaseAnalytics);

  Future logSignIn() async {
    await _firebaseAnalytics.logLogin();
  }

  Future logSignUp() async {
    await _firebaseAnalytics.logSignUp(signUpMethod: "Phone");
  }
}
