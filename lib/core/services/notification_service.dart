import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';

/// Global navigator key — set on MaterialApp so foreground notifications
/// can show a SnackBar without needing a BuildContext passed around.
final navigatorKey = GlobalKey<NavigatorState>();

/// Top-level handler required by firebase_messaging for background messages.
/// Must be a top-level (not class) function annotated with vm:entry-point.
@pragma('vm:entry-point')
Future<void> onFirebaseBackgroundMessage(RemoteMessage _) async {
  // Background messages are shown automatically by the OS.
  // No extra work needed here.
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  bool _initialized = false;

  /// Call once after the user's role and villa are confirmed.
  Future<void> initialize({required String uid}) async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // On Android 13+ this shows the system permission dialog.
    // On older Android and iOS the call is a no-op or triggers the system prompt.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _initialized = false;
      return;
    }

    // Web requires a VAPID key — skip token registration there for now.
    if (!kIsWeb) {
      final token = await messaging.getToken();
      if (token != null) {
        await FirebaseService.instance.saveFcmToken(uid: uid, token: token);
      }
      messaging.onTokenRefresh.listen((newToken) {
        FirebaseService.instance.saveFcmToken(uid: uid, token: newToken);
      });
    }

    // Show an in-app banner when the app is in the foreground.
    FirebaseMessaging.onMessage.listen(_showBanner);
  }

  /// Reset when the user signs out so the next login re-initializes.
  void reset() => _initialized = false;

  void _showBanner(RemoteMessage message) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
