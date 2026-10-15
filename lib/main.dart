import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
void showAppToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      error: error,
      onFinished: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  final String message;
  final bool error;
  final VoidCallback onFinished;

  const _AppToast({
    required this.message,
    required this.error,
    required this.onFinished,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    final bg = widget.error ? const Color(0xFF3A171B) : const Color(0xFF20262D);
    final accent = widget.error ? const Color(0xFFFF8B94) : const Color(0xFFE7ECF2);
    final icon = widget.error
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Positioned(
      top: top,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showPartyPopper(BuildContext context) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PartyPopperOverlay(onFinished: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _PartyPopperOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const _PartyPopperOverlay({required this.onFinished});

  @override
  State<_PartyPopperOverlay> createState() => _PartyPopperOverlayState();
}

class _PartyPopperOverlayState extends State<_PartyPopperOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<Offset> _starts = const [
    Offset(.16, .38), Offset(.22, .32), Offset(.28, .42), Offset(.34, .29),
    Offset(.40, .38), Offset(.48, .31), Offset(.56, .38), Offset(.63, .29),
    Offset(.70, .40), Offset(.76, .32), Offset(.83, .38), Offset(.88, .30),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                for (int i = 0; i < _starts.length; i++)
                  Positioned(
                    left: MediaQuery.of(context).size.width * _starts[i].dx,
                    top: MediaQuery.of(context).size.height *
                        (_starts[i].dy - .22 * _controller.value) +
                        (i.isEven ? -1 : 1) *
                            26 * Curves.easeOut.transform(_controller.value),
                    child: Opacity(
                      opacity: (1 - Curves.easeIn.transform(_controller.value)).clamp(0, 1),
                      child: Transform.rotate(
                        angle: (i.isEven ? 1 : -1) * 1.8 * _controller.value,
                        child: Container(
                          width: 7 + (i % 3) * 2,
                          height: 12 + (i % 2) * 5,
                          decoration: BoxDecoration(
                            color: [
                              const Color(0xFFD8DCE1),
                              const Color(0xFFE7EBEF),
                              const Color(0xFF9FA8B2),
                              const Color(0xFFF5F7FA),
                            ][i % 4],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Opacity(
                    opacity: (1 - Curves.easeIn.transform(_controller.value * .85)).clamp(0, 1),
                    child: Transform.scale(
                      scale: .8 + .3 * Curves.easeOutBack.transform(_controller.value),
                      child: const Text('🎉', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  debugPrint('DEALENDS BACKGROUND NOTIFICATION: ${message.messageId}');
}
Future<void> sendMyTestNotification() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('Please sign in before testing notifications.');
      return;
    }
    final callable = FirebaseFunctions.instance
        .httpsCallable('sendMyTestNotification');

    final result = await callable.call();

    debugPrint('DealEnds push test: ${result.data}');
  } on FirebaseFunctionsException catch (e) {
    debugPrint('Push test failed: ${e.code} - ${e.message}');
  } catch (e) {
    debugPrint('Push test error: $e');
  }
}
Future<void> saveFcmTokenForUser(User user, [String? token]) async {
  try {
    final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('DealEnds FCM token saved for user: ${user.uid}');
  } catch (e) {
    debugPrint('Failed to save DealEnds FCM token: $e');
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
  }
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      saveFcmTokenForUser(user);
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      saveFcmTokenForUser(user, token);
    }
  });


  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint(
      'DEALENDS NOTIFICATION: ${message.notification?.title}',
    );
    debugPrint(
      'BODY: ${message.notification?.body}',
    );

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'dealends_notifications',
      'DealEnds Notifications',
      channelDescription: 'DealEnds deal and offer notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'DealEnds',
      body: message.notification?.body ?? 'You have a new notification',
      notificationDetails: notificationDetails,
    );
  });

  await DealThemeController.load();

  runApp(const DealEndsApp());
}

Color platinum = const Color(0xFFD8DCE1);
Color silver = const Color(0xFFB5BDC7);
Color ice = const Color(0xFF1F2328);
Color ink = const Color(0xFFF5F7FA);
Color soft = const Color(0xFF0D0F12);
Color border = const Color(0xFF2C3138);
Color surface = const Color(0xFF171A1F);
Color actionColor = const Color(0xFFD8DCE1);
Color actionText = const Color(0xFF17181A);
Color heroStart = const Color(0xFF111317);
Color heroMid = const Color(0xFF2B3037);
Color heroEnd = const Color(0xFF515963);
Color heroGlow = const Color(0xFFD8DCE1);

enum DealThemeOption {
  blackSilver,
  silverBlack,
  blackGold,
  forestGreenCream,
  midnightBlueCyan,
  beigeBrown,
  gradient,
}

class DealThemeController {
  static final ValueNotifier<DealThemeOption> current =
  ValueNotifier(DealThemeOption.gradient);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('dealTheme');

    final theme = switch (saved) {
      'silverBlack' => DealThemeOption.silverBlack,
      'blackGold' => DealThemeOption.blackGold,
      'forestGreenCream' => DealThemeOption.forestGreenCream,
      'midnightBlueCyan' => DealThemeOption.midnightBlueCyan,
      'beigeBrown' => DealThemeOption.beigeBrown,
      'gradient' => DealThemeOption.gradient,
      _ => DealThemeOption.gradient,
    };

    _applyPalette(theme);
    current.value = theme;
  }

  static Future<void> setTheme(DealThemeOption theme) async {
    _applyPalette(theme);
    current.value = theme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dealTheme', theme.name);
  }

  static String label(DealThemeOption theme) {
    switch (theme) {
      case DealThemeOption.blackSilver:
        return 'Black + Silver';
      case DealThemeOption.silverBlack:
        return 'Silver + Black';
      case DealThemeOption.blackGold:
        return 'Black + Gold';
      case DealThemeOption.forestGreenCream:
        return 'Forest Green + Cream';
      case DealThemeOption.midnightBlueCyan:
        return 'Midnight Blue + Cyan';
      case DealThemeOption.beigeBrown:
        return 'Beige + Brown';
      case DealThemeOption.gradient:
        return 'Gradient Blue + Purple';
    }
  }

  static String description(DealThemeOption theme) {
    switch (theme) {
      case DealThemeOption.blackSilver:
        return 'Default dark theme · Clean, premium and modern';
      case DealThemeOption.silverBlack:
        return 'Light theme · Bright, minimal and easy to browse';
      case DealThemeOption.blackGold:
        return 'Luxury theme · Dark, rich and exclusive';
      case DealThemeOption.forestGreenCream:
        return 'Light theme · Fresh, calm and elegant';
      case DealThemeOption.midnightBlueCyan:
        return 'Dark theme · Modern, techy and energetic';
      case DealThemeOption.beigeBrown:
        return 'Light theme · Warm, classy and timeless';
      case DealThemeOption.gradient:
        return 'Modern theme · Premium, vibrant and energetic';
    }
  }

  static bool get isDark =>
      current.value != DealThemeOption.silverBlack &&
          current.value != DealThemeOption.forestGreenCream &&
          current.value != DealThemeOption.beigeBrown &&
          current.value != DealThemeOption.gradient;

  static void _applyPalette(DealThemeOption theme) {
    switch (theme) {
      case DealThemeOption.blackSilver:
        platinum = const Color(0xFFD8DCE1);
        silver = const Color(0xFFB5BDC7);
        ice = const Color(0xFF1F2328);
        ink = const Color(0xFFF5F7FA);
        soft = const Color(0xFF0D0F12);
        border = const Color(0xFF2C3138);
        surface = const Color(0xFF171A1F);
        actionColor = const Color(0xFFD8DCE1);
        actionText = const Color(0xFF17181A);
        heroStart = const Color(0xFF111317);
        heroMid = const Color(0xFF2B3037);
        heroEnd = const Color(0xFF515963);
        heroGlow = const Color(0xFFD8DCE1);
        break;
      case DealThemeOption.silverBlack:
        platinum = const Color(0xFF8F98A3);
        silver = const Color(0xFF5F6873);
        ice = const Color(0xFFE9EDF1);
        ink = const Color(0xFF15181C);
        soft = const Color(0xFFF5F6F8);
        border = const Color(0xFFD8DDE3);
        surface = Colors.white;
        actionColor = const Color(0xFF15181C);
        actionText = Colors.white;
        heroStart = const Color(0xFF15181C);
        heroMid = const Color(0xFF353B43);
        heroEnd = const Color(0xFF66717E);
        heroGlow = const Color(0xFFE9EDF1);
        break;
      case DealThemeOption.blackGold:
        platinum = const Color(0xFFD4AF37);
        silver = const Color(0xFFB88A2B);
        ice = const Color(0xFF2A2415);
        ink = const Color(0xFFF7F1DF);
        soft = const Color(0xFF0D0C0A);
        border = const Color(0xFF3D341F);
        surface = const Color(0xFF18140C);
        actionColor = const Color(0xFFD4AF37);
        actionText = const Color(0xFF1B1507);
        heroStart = const Color(0xFF17130A);
        heroMid = const Color(0xFF3A2B11);
        heroEnd = const Color(0xFF6A5119);
        heroGlow = const Color(0xFFF1D77A);
        break;
      case DealThemeOption.forestGreenCream:
        platinum = const Color(0xFF0F5132);
        silver = const Color(0xFF3E6B57);
        ice = const Color(0xFFE4F0E8);
        ink = const Color(0xFF102018);
        soft = const Color(0xFFF7F3E8);
        border = const Color(0xFFD7E2D8);
        surface = const Color(0xFFFFFEFA);
        actionColor = const Color(0xFF0F5132);
        actionText = Colors.white;
        heroStart = const Color(0xFF0B3824);
        heroMid = const Color(0xFF155C3A);
        heroEnd = const Color(0xFF3F7A5A);
        heroGlow = const Color(0xFFE4F0E8);
        break;
      case DealThemeOption.midnightBlueCyan:
        platinum = const Color(0xFF67D9FF);
        silver = const Color(0xFF2AB3E5);
        ice = const Color(0xFF102A3A);
        ink = const Color(0xFFF2FBFF);
        soft = const Color(0xFF07131E);
        border = const Color(0xFF16364A);
        surface = const Color(0xFF0D1E2A);
        actionColor = const Color(0xFF22D3EE);
        actionText = const Color(0xFF03131A);
        heroStart = const Color(0xFF071322);
        heroMid = const Color(0xFF0B2D4A);
        heroEnd = const Color(0xFF087EA4);
        heroGlow = const Color(0xFF8BE9FF);
        break;
      case DealThemeOption.beigeBrown:
        platinum = const Color(0xFF8B6F47);
        silver = const Color(0xFF6F5638);
        ice = const Color(0xFFF1E7D3);
        ink = const Color(0xFF2E261D);
        soft = const Color(0xFFF8F1E7);
        border = const Color(0xFFDFD0BB);
        surface = const Color(0xFFFFFCF7);
        actionColor = const Color(0xFF3E2F22);
        actionText = Colors.white;
        heroStart = const Color(0xFF3E2F22);
        heroMid = const Color(0xFF6A4C34);
        heroEnd = const Color(0xFF9A7650);
        heroGlow = const Color(0xFFF3E3C4);
        break;
      case DealThemeOption.gradient:
        platinum = const Color(0xFF6C63FF);
        silver = const Color(0xFF64748B);
        ice = const Color(0xFFEAF0FF);
        ink = const Color(0xFF111827);
        soft = const Color(0xFFF5F7FF);
        border = const Color(0xFFD9DFFF);
        surface = Colors.white;
        actionColor = const Color(0xFF5B5FEF);
        actionText = Colors.white;

        heroStart = const Color(0xFFEAF2FF);
        heroMid = const Color(0xFFEDE9FF);
        heroEnd = const Color(0xFFF8EEFF);
        heroGlow = const Color(0xFF8B7CFF);
        break;
    }
  }
}

class DealEndsApp extends StatelessWidget {
  const DealEndsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DealThemeOption>(
      valueListenable: DealThemeController.current,
      builder: (context, theme, _) {
        final dark = DealThemeController.isDark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DealEnds',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: soft,
            colorScheme: ColorScheme.fromSeed(
              seedColor: silver,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: surface,
              foregroundColor: ink,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingPage();
        }
        if (snapshot.data != null) return const HomePage();
        return const AuthPage();
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      body: Center(
        child: CircularProgressIndicator(color: actionColor),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _createMode = true;
  bool _loading = false;
  String? _inlineMessage;
  bool _inlineMessageIsError = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_authMessage(e));
    } catch (e) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    await _run(() async {
      if (_createMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          _showInfo('Account created successfully.');
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Enter your email address first.');
      return;
    }

    await _run(() async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showInfo('Password reset email sent.');
      }
    });
  }

  Future<void> _providerAuth(String providerName) async {
    await _run(() async {
      if (providerName == 'Google') {
        final signIn = GoogleSignIn.instance;
        await signIn.initialize();
        final googleUser = await signIn.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) {
          throw FirebaseAuthException(
            code: 'google-missing-id-token',
            message: 'Google sign-in could not verify the account.',
          );
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
        return;
      }

      final AuthProvider provider = providerName == 'Apple'
          ? AppleAuthProvider()
          : MicrosoftAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(provider);
    });
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No matching account was found, or the password is incorrect.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Use SIGN IN instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not configured for this app yet.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageIsError = true;
    });
  }

  void _showInfo(String message) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageIsError = false;
    });
  }

  Widget _inlineAuthMessage() {
    if (_inlineMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7, left: 4, right: 4),
      child: Text(
        _inlineMessage!,
        style: TextStyle(
          color: _inlineMessageIsError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: silver),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
    );
  }

  Widget _providerButton(String label, IconData icon) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : () => _providerAuth(label),
        icon: Icon(icon, color: ink, size: 20),
        label: Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border),
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: border),
                    ),
                    child: Icon(Icons.shopping_bag_rounded, color: actionColor, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _createMode ? 'Create your DealEnds account' : 'Sign in to DealEnds',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _createMode ? 'Create an account with your email and your own password.' : 'Sign in with the email and password you created.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: silver, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _providerButton('Google', Icons.g_mobiledata_rounded)),
                      const SizedBox(width: 9),
                      Expanded(child: _providerButton('Apple', Icons.apple)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _providerButton('Microsoft', Icons.window_rounded),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: Divider(color: border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR', style: TextStyle(color: silver, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(child: Divider(color: border)),
                  ]),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_inlineMessage != null) {
                        setState(() => _inlineMessage = null);
                      }
                    },
                    decoration: _decoration('Email address', Icons.email_outlined),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (_) {
                      if (_inlineMessage != null) {
                        setState(() => _inlineMessage = null);
                      }
                    },
                    decoration: _decoration(_createMode ? 'Create password (6+ characters)' : 'Password', Icons.lock_outline_rounded),
                  ),
                  _inlineAuthMessage(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _emailAuth,
                      style: FilledButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: actionText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_createMode ? 'CREATE ACCOUNT' : 'SIGN IN', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  if (!_createMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  TextButton(
                    onPressed: _loading ? null : () {
                      setState(() {
                        _createMode = !_createMode;
                        _inlineMessage = null;
                      });
                    },
                    child: Text(_createMode ? 'Already have an account? Sign in' : 'New to DealEnds? Create an account'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'By continuing, you agree to the DealEnds Terms of use and Privacy policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: silver, fontSize: 10, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DealProduct {
  final String name;
  final String category;
  final String price;
  final String oldPrice;
  final String discount;
  final String store;
  final String rating;
  final String drop;
  final IconData icon;
  final String? dealUrl;
  final String? imageUrl;
  final String? description;
  final String? brand;
  final int reviewCount;

  const DealProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.store,
    required this.rating,
    required this.drop,
    required this.icon,
    this.dealUrl,
    this.imageUrl,
    this.description,
    this.brand,
    this.reviewCount = 0,
  });

  factory DealProduct.fromFirestore(Map<String, dynamic> data) {
    final priceValue = (data['price'] as num?)?.toDouble() ?? 0;
    final oldPriceValue =
        (data['originalPrice'] as num?)?.toDouble() ?? 0;

    final discountValue = oldPriceValue > priceValue && oldPriceValue > 0
        ? ((oldPriceValue - priceValue) / oldPriceValue) * 100
        : 0.0;

    final ratingValue = (data['rating'] as num?)?.toDouble() ?? 0;
    final dropValue = oldPriceValue > priceValue
        ? oldPriceValue - priceValue
        : 0.0;

    String formatRupees(double amount) {
      final whole = amount.round().toString();
      if (whole.length <= 3) return '₹$whole';

      final lastThree = whole.substring(whole.length - 3);
      var remaining = whole.substring(0, whole.length - 3);
      final groups = <String>[];

      while (remaining.length > 2) {
        groups.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      groups.insert(0, remaining);

      return '₹${groups.join(',')},$lastThree';
    }

    // Extract raw URL and append Amazon tracking tag if it's an Amazon link
    String? rawUrl = data['affiliateUrl']?.toString() ??
        data['productUrl']?.toString();

    const String amazonTrackingTag = 'dealendsapp-21';

    if (rawUrl != null) {
      if (rawUrl.contains('amazon.in') || rawUrl.contains('amazon.com')) {
        if (!rawUrl.contains('tag=')) {
          final separator = rawUrl.contains('?') ? '&' : '?';
          rawUrl = '$rawUrl${separator}tag=$amazonTrackingTag';
        }
      }
    }

    return DealProduct(
      name: data['name']?.toString() ?? 'Unknown Product',
      category: data['category']?.toString() ?? 'Other',
      price: formatRupees(priceValue),
      oldPrice: oldPriceValue > 0
          ? formatRupees(oldPriceValue)
          : '',
      discount: '${discountValue.round()}% OFF',
      store: data['store']?.toString() ?? 'Unknown',
      rating: ratingValue.toStringAsFixed(1),
      drop: formatRupees(dropValue),
      icon: Icons.shopping_bag_rounded,
      dealUrl: rawUrl,
      imageUrl: data['imageUrl']?.toString(),
      description: data['description']?.toString(),
      brand: data['brand']?.toString(),
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  int get dealScore {
    final currentPrice =
        double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    final previousPrice =
        double.tryParse(oldPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    final productRating = double.tryParse(rating) ?? 0;

    if (currentPrice <= 0 || previousPrice <= 0) {
      return 0;
    }

    final discountPercent =
        ((previousPrice - currentPrice) / previousPrice) * 100;

    final discountScore = (discountPercent * 1.5).clamp(0, 60);
    final ratingScore = ((productRating / 5) * 40).clamp(0, 40);

    return (discountScore + ratingScore).round().clamp(0, 100);
  }
}
const products = [
  DealProduct(
    name: 'iPhone 17 Pro',
    category: 'Tech',
    price: '₹1,19,999',
    oldPrice: '₹1,34,900',
    discount: '11% OFF',
    store: 'Apple',
    rating: '4.8',
    drop: '₹14,901',
    icon: Icons.phone_iphone_rounded,
    dealUrl: 'https://www.apple.com/in/shop/buy-iphone/iphone-17-pro',
  ),
  DealProduct(
    name: 'iPhone 16 Pro',
    category: 'Tech',
    price: '₹99,999',
    oldPrice: '₹1,19,900',
    discount: '17% OFF',
    store: 'Amazon',
    rating: '4.7',
    drop: '₹19,901',
    icon: Icons.phone_iphone_rounded,
    dealUrl: 'https://www.amazon.in/s?k=Apple+iPhone+16+Pro',
  ),
  DealProduct(
    name: 'Galaxy S25 Ultra',
    category: 'Tech',
    price: '₹1,09,999',
    oldPrice: '₹1,34,999',
    discount: '19% OFF',
    store: 'Samsung',
    rating: '4.7',
    drop: '₹25,000',
    icon: Icons.smartphone_rounded,
  ),
  DealProduct(
    name: 'Premium Wireless Headphones',
    category: 'Tech',
    price: '₹2,499',
    oldPrice: '₹3,999',
    discount: '38% OFF',
    store: 'Amazon',
    rating: '4.5',
    drop: '₹1,500',
    icon: Icons.headphones_rounded,
  ),
  DealProduct(
    name: 'Smart Watch Series',
    category: 'Tech',
    price: '₹1,999',
    oldPrice: '₹2,999',
    discount: '33% OFF',
    store: 'Flipkart',
    rating: '4.4',
    drop: '₹1,000',
    icon: Icons.watch_rounded,
  ),
  DealProduct(
    name: 'Nike Air Max',
    category: 'Fashion',
    price: '₹5,499',
    oldPrice: '₹8,999',
    discount: '39% OFF',
    store: 'Myntra',
    rating: '4.6',
    drop: '₹3,500',
    icon: Icons.directions_run_rounded,
  ),
  DealProduct(
    name: 'Oversized Premium Shirt',
    category: 'Fashion',
    price: '₹899',
    oldPrice: '₹1,499',
    discount: '40% OFF',
    store: 'Myntra',
    rating: '4.3',
    drop: '₹600',
    icon: Icons.checkroom_rounded,
  ),
  DealProduct(
    name: 'Gaming Mechanical Keyboard',
    category: 'Gaming',
    price: '₹2,799',
    oldPrice: '₹4,499',
    discount: '38% OFF',
    store: 'Amazon',
    rating: '4.6',
    drop: '₹1,700',
    icon: Icons.keyboard_rounded,
  ),
];
Future<void> recordRecentlyViewed(DealProduct product) async {
  final prefs = await SharedPreferences.getInstance();

  final viewed = prefs.getStringList('recentlyViewed') ?? [];

  viewed.remove(product.name);
  viewed.insert(0, product.name);

  if (viewed.length > 10) {
    viewed.removeRange(10, viewed.length);
  }

  await prefs.setStringList('recentlyViewed', viewed);
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
List<DealProduct>? _firestoreProducts;

List<DealProduct> get _activeProducts {
  return _firestoreProducts ?? <DealProduct>[];
}

class _HomePageState extends State<HomePage> with  TickerProviderStateMixin {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSubscription;
  bool _hasReceivedInitialProductsSnapshot = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool mysteryMode = false;
  int selectedIndex = 0;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String currentLanguage = 'EN';
  String selectedCategory = 'All Categories';
  late final AnimationController _offerTickerController;
  final Set<String> savedProducts = {};
  final Set<String> trackedProducts = {};
  final Set<String> bagProducts = {};
  int dealHunterStreak = 0;
  DateTime? lastCheckIn;

  bool mysteryDealRevealed = false;
  bool mysteryDealAnimating = false;
  bool mysteryDealExplosion = false;
  late final AnimationController mysteryGiftRotationController;
  DateTime? mysteryDealDate;
  DateTime? mysteryDealExpiresAt;
  Timer? mysteryDealTimer;
  Duration mysteryDealRemaining = Duration.zero;
  static const quickCategories = [
    {'name': 'All Categories', 'icon': Icons.category_rounded},
    {'name': 'Electronics', 'icon': Icons.devices_other_rounded},
    {'name': 'Fashion', 'icon': Icons.checkroom_outlined},
    {'name': 'Home', 'icon': Icons.home_outlined},
    {'name': 'Beauty', 'icon': Icons.spa_rounded},
    {'name': 'Sports', 'icon': Icons.sports_soccer_outlined},
  ];
  Future<void> revealMysteryDeal() async {
    if (mysteryDealAnimating || mysteryDealRevealed) return;

    setState(() {
      mysteryDealAnimating = true;
      mysteryDealExplosion = false;
    });

    // Stage 1 — gentle shake
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    // Stage 2 — big gold explosion / sunrise
    setState(() {
      mysteryDealExplosion = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    // Stage 3 — reveal the opened gift
    final now = DateTime.now();
    final expiresAt =
    now.add(const Duration(hours: 24));

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      'mysteryDealRevealedAt',
      now.millisecondsSinceEpoch,
    );

    await prefs.setInt(
      'mysteryDealExpiresAt',
      expiresAt.millisecondsSinceEpoch,
    );

    if (!mounted) return;

    setState(() {
      mysteryDealRevealed = true;
      mysteryDealDate = now;
      mysteryDealExpiresAt = expiresAt;
      mysteryDealRemaining =
      const Duration(hours: 24);
    });

    // Stage 4 — keep the sunrise visible briefly
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    setState(() {
      mysteryDealExplosion = false;
      mysteryDealAnimating = false;
    });

    // Start the 24-hour countdown.
    _startMysteryDealTimer();
  }  Future<void> loadMysteryDeal() async {
    final prefs = await SharedPreferences.getInstance();

    final revealedAtMs = prefs.getInt('mysteryDealRevealedAt');

    final expiresAtMs =
    prefs.getInt('mysteryDealExpiresAt');

    if (revealedAtMs == null || expiresAtMs == null) {
      if (!mounted) return;

      setState(() {
        mysteryDealRevealed = false;
        mysteryDealDate = null;
        mysteryDealExpiresAt = null;
        mysteryDealRemaining = Duration.zero;
      });

      return;
    }

    final now = DateTime.now();
    final expiresAt =
    DateTime.fromMillisecondsSinceEpoch(expiresAtMs);

    if (now.isBefore(expiresAt)) {
      if (!mounted) return;

      setState(() {
        mysteryDealRevealed = true;
        mysteryDealDate =
            DateTime.fromMillisecondsSinceEpoch(revealedAtMs);
        mysteryDealExpiresAt = expiresAt;
        mysteryDealRemaining = expiresAt.difference(now);
      });

      _startMysteryDealTimer();
    } else {
      await prefs.remove('mysteryDealRevealedAt');
      await prefs.remove('mysteryDealExpiresAt');

      if (!mounted) return;

      setState(() {
        mysteryDealRevealed = false;
        mysteryDealDate = null;
        mysteryDealExpiresAt = null;
        mysteryDealRemaining = Duration.zero;
      });
    }
  }
  Widget _mysteryGoldenRings() {
    return AnimatedBuilder(
      animation: mysteryGiftRotationController,
      builder: (context, child) {
        final angle = mysteryGiftRotationController.value * 2 * pi;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Fixed golden ring artwork
            Image.asset(
              'assets/images/mystery_gift_gold_rings.png',
              width: 320,
              height: 320,
              fit: BoxFit.contain,
            ),

            // Moving bright highlight
            ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return SweepGradient(
                  transform: GradientRotation(angle),
                  colors: const [
                    Color(0x00FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0xFFFFB300),
                    Color(0xFFFFFFD6),
                    Color(0xFFFFFFFF),
                    Color(0xFFFFB300),
                    Color(0x00FFFFFF),
                    Color(0x00FFFFFF),
                  ],
                  stops: const [
                    0.0,
                    0.38,
                    0.44,
                    0.47,
                    0.49,
                    0.52,
                    0.58,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              child: Image.asset(
                'assets/images/mystery_gift_gold_rings.png',
                width: 320,
                height: 320,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }
  void _startMysteryDealTimer() {
    mysteryDealTimer?.cancel();

    mysteryDealTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        final expiresAt = mysteryDealExpiresAt;

        if (expiresAt == null) {
          timer.cancel();
          return;
        }

        final remaining = expiresAt.difference(DateTime.now());

        if (remaining <= Duration.zero) {
          timer.cancel();

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('mysteryDealRevealedAt');
          await prefs.remove('mysteryDealExpiresAt');

          if (!mounted) return;

          setState(() {
            mysteryDealRevealed = false;
            mysteryDealDate = null;
            mysteryDealExpiresAt = null;
            mysteryDealRemaining = Duration.zero;
          });

          return;
        }

        if (!mounted) return;

        setState(() {
          mysteryDealRemaining = remaining;
        });
      },
    );
  }
  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }
  Future<void> loadSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('savedProducts') ?? [];

    if (!mounted) return;

    setState(() {
      savedProducts.addAll(saved);
    });
  }
  Future<void> loadTrackedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final tracked = prefs.getStringList('trackedProducts') ?? [];

    if (!mounted) return;

    setState(() {
      trackedProducts.addAll(tracked);
    });
  }
  Future<void> loadBagProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final bag = prefs.getStringList('bagProducts') ?? [];

    if (!mounted) return;

    setState(() {
      bagProducts.addAll(bag);
    });
  }
  Future<void> toggleBag(String name) async {
    setState(() {
      if (bagProducts.contains(name)) {
        bagProducts.remove(name);
      } else {
        bagProducts.add(name);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'bagProducts',
      bagProducts.toList(),
    );
  }
  Future<void> checkInToday() async {
    final prefs = await SharedPreferences.getInstance();

    final savedStreak = prefs.getInt('dealHunterStreak') ?? 0;
    final savedLastCheckIn = prefs.getInt('lastCheckIn');

    final now = DateTime.now();

    int newStreak = savedStreak;
    DateTime? newLastCheckIn = savedLastCheckIn == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(savedLastCheckIn);

    if (newLastCheckIn == null) {
      newStreak = 1;
      newLastCheckIn = now;
    } else {
      final today = DateTime(now.year, now.month, now.day);
      final previous = DateTime(
        newLastCheckIn.year,
        newLastCheckIn.month,
        newLastCheckIn.day,
      );

      final difference = today.difference(previous).inDays;

      if (difference == 1) {
        newStreak++;
        newLastCheckIn = now;
      } else if (difference > 1) {
        newStreak = 1;
        newLastCheckIn = now;
      }
    }

    await prefs.setInt('dealHunterStreak', newStreak);
    await prefs.setInt(
      'lastCheckIn',
      newLastCheckIn.millisecondsSinceEpoch,
    );

    if (!mounted) return;

    setState(() {
      dealHunterStreak = newStreak;
      lastCheckIn = newLastCheckIn;
    });
  }
  Future<void> toggleSaved(String name) async {
    setState(() {
      if (savedProducts.contains(name)) {
        savedProducts.remove(name);
      } else {
        savedProducts.add(name);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'savedProducts',
      savedProducts.toList(),
    );
  }
  Future<void> toggleTracked(String name) async {
    setState(() {
      if (trackedProducts.contains(name)) {
        trackedProducts.remove(name);

        showAppToast(context, '$name removed from price tracking');
      } else {
        trackedProducts.add(name);

        showAppToast(context, '$name added to price tracking');
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'trackedProducts',
      trackedProducts.toList(),
    );
  }
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('DEALENDS BANNER ERROR: $error');
        },
      ),
    )..load();
  }
  @override
  void initState() {
    super.initState();

    mysteryGiftRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _loadBannerAd();

    _offerTickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _loadLanguage();
    checkInToday();
    loadMysteryDeal();
    loadSavedProducts();
    loadTrackedProducts();
    loadBagProducts();
    final Map<String, double> previousProductPrices = {};
    debugPrint('DEALENDS FIREBASE PROJECT: ${FirebaseFirestore.instance.app.options.projectId}');
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) async {
        debugPrint('DEALENDS: Firestore snapshot received: ${snapshot.docs.length} products');
        debugPrint('DEALENDS: Document changes count: ${snapshot.docChanges.length}');
        debugPrint('DEALENDS: Snapshot metadata — fromCache=${snapshot.metadata.isFromCache}, pendingWrites=${snapshot.metadata.hasPendingWrites}');
        if (!_hasReceivedInitialProductsSnapshot) {
          _hasReceivedInitialProductsSnapshot = true;

          // Record existing prices without reporting false price drops.
          for (final doc in snapshot.docs) {
            final data = doc.data();
            debugPrint('DEALENDS PRODUCT DATA ${doc.id}: $data');
            final rawPrice = data['price'];
            final price = rawPrice is num
                ? rawPrice.toDouble()
                : double.tryParse(rawPrice?.toString() ?? '');

            if (price != null && price >= 0) {
              previousProductPrices[doc.id] = price;
            }
            debugPrint(
              'DEALENDS BASELINE: ${doc.id} = ${previousProductPrices[doc.id]}',
            );
          }
        } else {
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            debugPrint(
              'DEALENDS: Document change type: ${change.type}, '
                  'product: ${change.doc.id}',
            );
            final rawPrice = data?['price'];
            final currentPrice = rawPrice is num
                ? rawPrice.toDouble()
                : double.tryParse(rawPrice?.toString() ?? '');

            if (change.type == DocumentChangeType.removed) {
              previousProductPrices.remove(change.doc.id);
              continue;
            }

            if (currentPrice == null || currentPrice < 0) {
              debugPrint(
                'DEALENDS PRICE CHECK FAILED: id=${change.doc.id}, '
                    'rawPrice=$rawPrice, parsedPrice=$currentPrice',
              );
              continue;
            }

            final previousPrice =
            previousProductPrices[change.doc.id];
            if (previousPrice == null) {
              previousProductPrices[change.doc.id] = currentPrice;
              debugPrint(
                'DEALENDS: Price baseline set: '
                    '${change.doc.id} = $currentPrice',
              );
              continue;
            }
            debugPrint(
              'DEALENDS PRICE CHECK: id=${change.doc.id}, '
                  'previous=$previousPrice, current=$currentPrice, '
                  'fromCache=${snapshot.metadata.isFromCache}',
            );


            if (change.type == DocumentChangeType.added) {
              if (!snapshot.metadata.isFromCache) {
                debugPrint(
                  'DealEnds: New product detected: '
                      '${data?['name'] ?? change.doc.id}',
                );
              }

            } else if (change.type == DocumentChangeType.modified &&
                currentPrice < previousPrice &&
                !snapshot.metadata.isFromCache) {
              final productName = data?['name']?.toString() ?? change.doc.id;

              debugPrint(
                'DealEnds: PRICE DROP detected: '
                    '$productName | $previousPrice -> $currentPrice',
              );

              const AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails(
                'dealends_notifications',
                'DealEnds Notifications',
                channelDescription: 'DealEnds deal and offer notifications',
                importance: Importance.high,
                priority: Priority.high,
              );

              const NotificationDetails notificationDetails =
              NotificationDetails(android: androidDetails);

              await flutterLocalNotificationsPlugin.show(
                id: change.doc.id.hashCode,
                title: 'Price Drop! 🔥',
                body: '$productName is now ₹${currentPrice.toStringAsFixed(0)} '
                    '(was ₹${previousPrice.toStringAsFixed(0)})',
                notificationDetails: notificationDetails,
              );
            }


            previousProductPrices[change.doc.id] = currentPrice;
          }
        }

        final loadedProducts = snapshot.docs
            .where((doc) {
          final data = doc.data();
          final id = doc.id.toLowerCase();
          final name = (data['name'] ?? '').toString().toLowerCase();

          // Exclude the known test/demo records.
          if (const {
            'worker test 001',
            'test product',
            'dealends-demo-001',
          }.contains(id)) {
            return false;
          }

          if (name.contains('demo') ||
              name.contains('test product')) {
            return false;
          }

          // Only show products with a usable price and product link.
          final rawPrice = data['price'];
          final price = rawPrice is num
              ? rawPrice.toDouble()
              : double.tryParse(rawPrice?.toString() ?? '');


          final url = (data['affiliateUrl'] ??
              data['productUrl'] ??
              '')
              .toString()
              .trim();

          final uri = Uri.tryParse(url);

          return price != null &&
              price > 0 &&
              uri != null &&
              uri.scheme == 'https' &&
              uri.host.isNotEmpty &&
              data['name'] != null &&
              data['name'].toString().trim().isNotEmpty;
        })
            .map((doc) => DealProduct.fromFirestore(doc.data()))
            .toList();

        if (!mounted) return;

        setState(() {
          _firestoreProducts = loadedProducts;
        });
      },
      onError: (error) {
        debugPrint('Firestore products listener error: $error');
      },
    );

  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('appLanguage') ?? 'EN';
    if (!mounted) return;
    setState(() => currentLanguage = saved);
  }



  Future<bool> _showPermissionIntro({
    required String title,
    required String message,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Icon(icon, size: 34, color: silver),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: silver,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: actionText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Allow',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _requestCameraPermission() async {
    final shouldAsk = await _showPermissionIntro(
      title: 'Enable camera search?',
      message: 'Use your camera to search for products by taking a photo. DealEnds will ask for camera access next.',
      icon: Icons.photo_camera_outlined,
    );

    if (!shouldAsk) return;

    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      showAppToast(context, 'Camera search enabled');
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    showAppToast(context, 'Camera permission was not enabled', error: true);
  }

  Future<void> _requestMicrophonePermission() async {
    final shouldAsk = await _showPermissionIntro(
      title: 'Enable voice search?',
      message: 'Use your microphone to search for products by speaking. DealEnds will ask for microphone access next.',
      icon: Icons.mic_none_rounded,
    );

    if (!shouldAsk) return;

    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status.isGranted) {
      showAppToast(context, 'Voice search enabled');
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    showAppToast(context, 'Microphone permission was not enabled', error: true);
  }


  @override
  void dispose() {
    _bannerAd?.dispose();
    _productsSubscription?.cancel();
    _offerTickerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    mysteryDealTimer?.cancel();
    mysteryGiftRotationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    final bool isMystery = selectedIndex == 2;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor:
        isMystery ? const Color(0xFF030303) : soft,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: isMystery ? const Color(0xFF030303) : surface,
          primary: isMystery
              ? const Color(0xFFFFC928)
              : actionColor,
        ),
      ),
      child: Scaffold(
        backgroundColor:
        isMystery ? const Color(0xFF030303) : soft,
        appBar: null,
        body: _body(),

        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: 76,
              decoration: BoxDecoration(
                gradient: isMystery
                    ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF030303),
                    Color(0xFF0D0903),
                    Color(0xFF030303),
                  ],
                )
                    : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F7FF),
                    Color(0xFFEDE9FE),
                    Color(0xFFFCE7F3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isMystery
                      ? const Color(0xFF76500A)
                      : const Color(0xFFD9DFFF),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMystery
                        ? const Color(0xFFFFB300)
                        .withValues(alpha: .16)
                        : const Color(0xFF6C63FF)
                        .withValues(alpha: .12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _bottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),

                  _bottomNavItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Deals',
                    index: 1,
                  ),

                  // CENTER MYSTERY BUTTON
                  _mysteryNavItem(),

                  _bottomNavItem(
                    icon: Icons.favorite_rounded,
                    label: 'Wishlist',
                    index: 3,
                  ),

                  _bottomNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _mysteryDealPage() {

    final remaining = mysteryDealRemaining;

    final countdown =
        '${remaining.inHours.toString().padLeft(2, '0')}:'
        '${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020202),
            Color(0xFF080601),
            Color(0xFF020202),
          ],
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          child: Column(
            children: [

              // MYSTERY GIFT
              SizedBox(
                width: double.infinity,
                height: 300,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: mysteryDealExplosion
                          ? RadialGradient(
                        colors: [
                          const Color(0xFFFFF3B0).withValues(alpha: .95),
                          const Color(0xFFFFC928).withValues(alpha: .55),
                          const Color(0xFFFF9D00).withValues(alpha: .22),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.25, 0.55, 1.0],
                      )
                          : const RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: mysteryDealExplosion
                          ? [
                        BoxShadow(
                          color: const Color(0xFFFFC928).withValues(alpha: .65),
                          blurRadius: 80,
                          spreadRadius: 25,
                        ),
                      ]
                          : [],
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (mysteryDealRevealed) {
                            final mysteryProduct =
                            products[DateTime.now().day % products.length];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductPage(
                                  product: mysteryProduct,
                                ),
                              ),
                            );
                            return;
                          }

                          if (!mysteryDealAnimating) {
                            revealMysteryDeal();
                          }
                        },


                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Back golden rings with moving light
                            _mysteryGoldenRings(),


                            // Gift
                            AnimatedScale(
                              scale: mysteryDealAnimating
                                  ? (mysteryDealExplosion ? 1.12 : 1.05)
                                  : 1.0,
                              duration: Duration(
                                milliseconds: mysteryDealExplosion ? 650 : 350,
                              ),
                              curve: Curves.easeOutBack,
                              child: AnimatedRotation(
                                turns: mysteryDealAnimating
                                    ? (mysteryDealExplosion ? 0.0 : 0.018)
                                    : 0.0,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutBack,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 750),
                                  switchInCurve: Curves.easeOutBack,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    mysteryDealRevealed
                                        ? 'assets/images/mystery_gift_3d_opened.png'
                                        : 'assets/images/mystery_gift_3d_closed.png',
                                    key: ValueKey(mysteryDealRevealed),
                                    width: 290,
                                    height: 290,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            // Front orbit rings
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // GOLD DIVIDER + CROWN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 1,
                    color: const Color(0xFF9D6A08),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC928),
                    size: 27,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 65,
                    height: 1,
                    color: const Color(0xFF9D6A08),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // TITLE
              const Text(
                'Mystery Deal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFE28A),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),

              const SizedBox(height: 6),

              // SUBTITLE
              const Text(
                'A surprise deal is waiting for you!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8E8E8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // COUNTDOWN
              if (mysteryDealRevealed) ...[
                const SizedBox(height: 17),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF8D6410),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF171006),
                        Color(0xFF0A0804),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300)
                            .withValues(alpha: .10),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFFFC928),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        countdown,
                        style: const TextStyle(
                          color: Color(0xFFFFD75A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 25),

              // FEATURES
              Row(
                children: [
                  _mysteryFeature(
                    Icons.bolt_rounded,
                    'Exclusive\nDeals',
                  ),
                  _mysteryFeature(
                    Icons.access_time_rounded,
                    'Limited\nTime',
                  ),
                  _mysteryFeature(
                    Icons.lock_rounded,
                    'Watch Ad &\nReveal',
                  ),
                  _mysteryFeature(
                    Icons.local_fire_department_rounded,
                    "Don't Miss It!",
                  ),
                ],
              ),

              const SizedBox(height: 27),




              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF151006),
                      Color(0xFF090704),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF76500A),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300)
                          .withValues(alpha: .10),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE28A),
                            Color(0xFFFFC928),
                            Color(0xFFD88C00),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.autorenew_rounded,
                        color: Color(0xFF2A1900),
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW MYSTERY DEAL EVERY 24 HOURS',
                            style: TextStyle(
                              color: Color(0xFFFFD75A),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Your mystery deal refreshes automatically when the timer ends.',
                            style: TextStyle(
                              color: Color(0xFFBDB7A8),
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 18),

// MYSTERY GIFT REVEAL EFFECT
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: mysteryDealRevealed
                    ? Container(
                  key: const ValueKey('revealed'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1204),
                        Color(0xFF090704),
                        Color(0xFF1A1204),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFC928),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300)
                            .withValues(alpha: .18),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFD75A),
                        size: 28,
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'MYSTERY DEAL REVEALED!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFFD75A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Your exclusive surprise is unlocked.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFBDB7A8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox(
                  key: ValueKey('hidden'),
                  height: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedIndex == index) return;

          setState(() {
            selectedIndex = index;
          });
        },
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  0,
                  selected ? -2 : 1,
                  0,
                ),
                child: Icon(
                  icon,
                  size: selected ? 26 : 24,
                  color: selected
                      ? const Color(0xFF5B5FEF)
                      : const Color(0xFF8B91A3),
                ),
              ),

              const SizedBox(height: 2),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF5B5FEF)
                      : const Color(0xFF8B91A3),
                  fontSize: selected ? 11.5 : 11,
                  fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(label),
              ),

              const SizedBox(height: 3),

              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: selected ? 24 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFFC084FC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _mysteryNavItem() {
    final bool selected = selectedIndex == 2;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedIndex == 2) return;

          setState(() {
            selectedIndex = 2;
          });
        },
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: selected ? 52 : 44,
                height: selected ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF0A3),
                      Color(0xFFFFC928),
                      Color(0xFFD88C00),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFE99A),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300)
                          .withValues(
                        alpha: selected ? .65 : .22,
                      ),
                      blurRadius: selected ? 26 : 12,
                      spreadRadius: selected ? 3 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: const Color(0xFF3B2500),
                      fontSize: selected ? 30 : 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mystery Deal',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFC928)
                      : const Color(0xFF8B91A3),
                  fontSize: selected ? 10.5 : 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _homeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👑DealEnds',
                  style: TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                      () {
                    final hour = DateTime.now().hour;

                    if (hour >= 5 && hour < 12) {
                      return 'Good morning 👋';
                    } else if (hour >= 12 && hour < 17) {
                      return 'Good afternoon 👋';
                    } else {
                      return 'Good evening 👋';
                    }
                  }(),
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Find the best deals today.',
                  style: TextStyle(
                    color: silver.withValues(alpha: .72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              showAppToast(
                context,
                'Deal Hunter Streak: $dealHunterStreak ${dealHunterStreak == 1 ? 'day' : 'days'}',
              );
            },
            icon: Icon(
              Icons.local_fire_department_rounded,
              color: actionColor,
              size: 24,
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PriceAlertsPage(),
                ),
              );
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              color: ink,
            ),
          ),

          IconButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final bag = prefs.getStringList('bagProducts') ?? [];

              setState(() {
                bagProducts
                  ..clear()
                  ..addAll(bag);
              });

              if (!mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoppingBagPage(
                    bagNames: bagProducts,
                    onToggleBag: toggleBag,
                    savedNames: savedProducts,
                    trackedNames: trackedProducts,
                    onToggleSaved: toggleSaved,
                    onToggleTracked: toggleTracked,
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
  Widget _body() {

    if (selectedIndex == 0 && _isSearchOpen) {
      return SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  // Smooth back button
                  Container(
                    width: 44,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4E8FF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        _searchFocusNode.unfocus();
                        setState(() {
                          _isSearchOpen = false;
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 27,
                        color: Color(0xFF4545B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Search bar
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF625BFF),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: ink),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands or deals',
                          hintStyle: TextStyle(color: silver),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: silver,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Voice search',
                                onPressed: _requestMicrophonePermission,
                                icon: Icon(
                                  Icons.mic_none_rounded,
                                  color: silver,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Camera search',
                                onPressed: _requestCameraPermission,
                                icon: Icon(
                                  Icons.photo_camera_outlined,
                                  color: silver,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _searchResults()),
          ],
        ),
      );
    }


    if (selectedIndex == 1) {
      return SafeArea(
        top: true,
        bottom: false,
        child: DealsPage(
          savedNames: savedProducts,
          trackedNames: trackedProducts,
          onToggleSaved: toggleSaved,
          onToggleTracked: toggleTracked,
        ),
      );
    }

    if (selectedIndex == 2) {
      return _mysteryDealPage();
    }

    if (selectedIndex == 3) {
      return SafeArea(
        top: true,
        bottom: false,
        child: SavedPage(
          savedNames: savedProducts,
          onToggleSaved: toggleSaved,
          onToggleTracked: toggleTracked,
          trackedNames: trackedProducts,
        ),
      );
    }


    if (selectedIndex == 4) {
      return SafeArea(
        top: true,
        bottom: false,
        child: ProfilePage(
          savedNames: savedProducts,
          trackedNames: trackedProducts,
          onToggleSaved: toggleSaved,
          onToggleTracked: toggleTracked,
        ),
      );
    }


    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _homeHeader(),
            const SizedBox(height: 8),
            _search(),
            const SizedBox(height: 10),
            _quickCategoryStrip(),
            const SizedBox(height: 16),
            _hero(),

            const SizedBox(height: 14),

            if (_isBannerAdLoaded && _bannerAd != null)
              Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),

            const SizedBox(height: 18),

            const SizedBox(height: 24),

            _homeSectionTitle(
              'Today’s Best Deals',
              Icons.local_fire_department_rounded,
              action: 'See all',
            ),

            const SizedBox(height: 12),

            _todayDeals(),

            const SizedBox(height: 28),

            _homeSectionTitle(
              'Trending Now',
              Icons.bolt_rounded,
            ),

            const SizedBox(height: 12),

            _trendingNow(),

            const SizedBox(height: 28),

            _sectionTitle('Popular right now'),

            const SizedBox(height: 12),

            _horizontalProducts(),
          ],
        ),
      ),
    );

  }
  Widget _searchResults() {
    final query = _searchController.text.trim().toLowerCase();

    final results = query.isEmpty
        ? <DealProduct>[]
        : products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.store.toLowerCase().contains(query);
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Text(
          'Search products, brands or deals',
          style: TextStyle(
            color: silver,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No deals found',
          style: TextStyle(
            color: silver,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];

        return ProductCard(
          product: product,
          saved: savedProducts.contains(product.name),
          tracked: trackedProducts.contains(product.name),
          onSaved: () => toggleSaved(product.name),
          onTracked: () => toggleTracked(product.name),
        );
      },
    );
  }


  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: GestureDetector(
        onTap: _openSearch,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.search_rounded,
                color: silver,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search products, brands or deals',
                  style: TextStyle(
                    color: silver.withValues(alpha: .72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _requestMicrophonePermission,
                tooltip: 'Voice search',
                icon: Icon(
                  Icons.mic_none_rounded,
                  color: silver,
                  size: 21,
                ),
              ),
              IconButton(
                onPressed: _requestCameraPermission,
                tooltip: 'Camera search',
                icon: Icon(
                  Icons.photo_camera_outlined,
                  color: silver,
                  size: 21,
                ),
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickCategoryStrip() {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: quickCategories.length,
        itemBuilder: (context, index) {
          final category = quickCategories[index];
          final name = category['name'] as String;
          final selected = selectedCategory == name;

          return SizedBox(
            width: 76,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => selectedCategory = name);
              },
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected
                          ? platinum.withValues(alpha: .16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: selected ? platinum : silver,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: selected ? 46 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? platinum : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DealProduct> _categoryProducts() {
    if (selectedCategory == 'All Categories') {
      return [..._activeProducts];
    }

    final target = switch (selectedCategory) {
      'Electronics' => 'Tech',
      'Fashion' => 'Fashion',
      'Home' => 'Home',
      'Beauty' => 'Beauty',
      'Sports' => 'Sports',
      _ => selectedCategory,
    };

    return _activeProducts
        .where((product) => product.category == target)
        .toList();
  }
  Widget _hero() {
    if (_activeProducts.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'New deals are coming soon.',
          style: TextStyle(
            color: silver,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final featured = _activeProducts.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 120,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    platinum.withValues(alpha: .23),
                    platinum.withValues(alpha: .01),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 12,
            bottom: 4,
            child: Icon(
              featured.icon,
              size: 78,
              color: platinum.withValues(alpha: .92),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡Deals of the day',
                  style: TextStyle(
                    color: silver,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Top Deals Right Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Save big. Shop smarter.',
                  style: TextStyle(
                    color: silver,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _heroDot(true),
                    const SizedBox(width: 6),
                    _heroDot(false),
                    const SizedBox(width: 6),
                    _heroDot(false),
                    const SizedBox(width: 6),
                    _heroDot(false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 7 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? platinum
            : silver.withValues(alpha: .45),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _sectionTitle(String title, {String? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -.3,
            ),
          ),
          if (action != null)
            Text(
              action,
              style: TextStyle(
                color: silver,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
  Widget _todayDeals() {
    final todayDeals = _categoryProducts()
      ..sort(
            (a, b) => b.dealScore.compareTo(a.dealScore),
      );

    final topDeals = todayDeals.take(4).toList();

    if (topDeals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          'No deals in $selectedCategory yet',
          style: TextStyle(
            color: silver,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: topDeals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final product = topDeals[index];

        return _todayDealCard(product);
      },
    );
  }
  Widget _todayDealCard(DealProduct product) {
    final isSaved = savedProducts.contains(product.name);
    final isTracked = trackedProducts.contains(product.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: product.imageUrl != null &&
                          product.imageUrl!.isNotEmpty
                          ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) {
                          return Icon(
                            product.icon,
                            size: 55,
                            color: platinum,
                          );
                        },
                      )
                          : Icon(
                        product.icon,
                        size: 55,
                        color: platinum,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Text(
                        product.oldPrice,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 9,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          product.price,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // OFFER BADGE — TOP LEFT
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.discount,
                  style: TextStyle(
                    color: actionText,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // WISHLIST BUTTON — TOP RIGHT
            Positioned(
              top: 7,
              right: 42,
              child: Material(
                color: surface.withValues(alpha: .92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final willBeSaved = !savedProducts.contains(product.name);

                    toggleSaved(product.name);

                    showAppToast(
                      context,
                      willBeSaved
                          ? 'Added to wishlist'
                          : 'Removed from wishlist',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isSaved ? actionColor : ink,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // DEAL ALERT / BELL BUTTON — TOP RIGHT
            Positioned(
              top: 7,
              right: 7,
              child: Material(
                color: surface.withValues(alpha: .92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => toggleTracked(product.name),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isTracked
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: isTracked ? actionColor : ink,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _homeSectionTitle(
      String title,
      IconData icon, {
        String? action,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: actionColor,
            size: 23,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
          ),
          if (action != null)
            Text(
              '$action →',
              style: TextStyle(
                color: actionColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
  Widget _trendingNow() {
    final visible = _categoryProducts();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final product = visible[index];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _trendingCard(product),
          );
        },
      ),
    );
  }
  Widget _mysteryFeature(
      IconData icon,
      String text,
      ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFD76A),
            size: 21,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB9A77A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  Widget _trendingCard(DealProduct product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(product: product),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Product image
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 7, 25),
                child: Center(
                  child: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                      ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return Icon(
                        product.icon,
                        size: 34,
                        color: platinum,
                      );
                    },
                  )
                      : Icon(
                    product.icon,
                    size: 34,
                    color: platinum,
                  ),
                ),
              ),
            ),

            // Offer badge
            Positioned(
              top: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.discount,
                  style: TextStyle(
                    color: actionText,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // Product name
            Positioned(
              left: 7,
              right: 7,
              bottom: 6,
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalProducts() {
    final visible = _categoryProducts();
    return SizedBox(
      height: 238,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final product = visible[index];
          return SizedBox(
            width: 175,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ProductCard(
                product: product,
                saved: savedProducts.contains(product.name),
                tracked: trackedProducts.contains(product.name),
                onSaved: () => toggleSaved(product.name),
                onTracked: () => toggleTracked(product.name),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final DealProduct product;
  final bool saved;
  final bool tracked;
  final VoidCallback onSaved;
  final VoidCallback onTracked;
  final VoidCallback? onRemove;

  const ProductCard({
    super.key,
    required this.product,
    required this.saved,
    required this.tracked,
    required this.onSaved,
    required this.onTracked,
    this.onRemove,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  bool _showDoubleTapHeart = false;
  bool _doubleTapWillLike = true;
  late bool _isLiked;
  late bool _isTracked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.saved;
    _isTracked = widget.tracked;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saved != widget.saved) {
      _isLiked = widget.saved;
      if (oldWidget.tracked != widget.tracked) {
        _isTracked = widget.tracked;
      }
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _openProduct() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPage(
          product: widget.product,
          onSaved: widget.onSaved,
          onTracked: widget.onTracked,
        ),
      ),
    );
  }

  Future<void> _doubleTapLike() async {
    final willBeSaved = !_isLiked;

    setState(() {
      _isLiked = willBeSaved;
      _showDoubleTapHeart = true;
      _doubleTapWillLike = willBeSaved;
    });

    widget.onSaved();
    showAppToast(
      context,
      willBeSaved ? 'Added to wishlist' : 'Removed from wishlist',
    );
    await _heartController.forward(from: 0);

    if (!mounted) return;
    setState(() => _showDoubleTapHeart = false);
  }

  void _toggleLikeFromButton() {
    final willBeSaved = !_isLiked;

    setState(() {
      _isLiked = willBeSaved;
    });

    widget.onSaved();

    if (!mounted) return;

    showAppToast(
      context,
      willBeSaved ? 'Added to wishlist' : 'Removed from wishlist',
    );
  }
  void _toggleTrackedFromButton() {
    setState(() {
      _isTracked = !_isTracked;
    });
    widget.onTracked();
  }
  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
    required bool active,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: soft.withValues(alpha: .92),
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? actionColor : silver,
          ),
        ),
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    debugPrint('DEALENDS IMAGE URL: ${widget.product.imageUrl}');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openProduct,
      onDoubleTap: _doubleTapLike,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: soft,
                    child: Center(
                      child: widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                          ? Image.network(
                        widget.product.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            widget.product.icon,
                            size: 57,
                            color: platinum,
                          );
                        },
                      )
                          : Icon(
                        widget.product.icon,
                        size: 57,
                        color: platinum,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.product.discount,
                        style: TextStyle(
                          color: actionText,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _roundAction(
                          icon: _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: _toggleLikeFromButton,
                          active: _isLiked,
                        ),
                        const SizedBox(width: 6),
                        _roundAction(
                          icon: _isTracked
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          onTap: _toggleTrackedFromButton,
                          active: _isTracked,
                        ),
                      ],
                    ),
                  ),
                  if (_showDoubleTapHeart)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _heartController,
                              curve: Curves.elasticOut,
                            ),
                            child: FadeTransition(
                              opacity: Tween<double>(begin: 1, end: 0).animate(
                                CurvedAnimation(
                                  parent: _heartController,
                                  curve: const Interval(.35, 1),
                                ),
                              ),
                              child: Icon(
                                _doubleTapWillLike
                                    ? Icons.favorite_rounded
                                    : Icons.heart_broken_rounded,
                                color: _doubleTapWillLike
                                    ? const Color(0xFFFF3B4D)
                                    : Colors.grey,
                                size: 86,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.onRemove != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _roundAction(
                        icon: Icons.delete_outline_rounded,
                        onTap: widget.onRemove!,
                        active: false,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: silver,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          widget.product.price,
                          style: TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.product.oldPrice,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7E8791),
                              fontSize: 9.5,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ice,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            widget.product.discount,
                            style: TextStyle(
                              color: ink,
                              fontSize: 7.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: platinum, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          widget.product.rating,
                          style: TextStyle(
                            color: silver,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DealsPage extends StatelessWidget {
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Function(String) onToggleSaved;
  final Function(String) onToggleTracked;

  const DealsPage({
    super.key,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F7FF),
            const Color(0xFFEDE9FE),
            const Color(0xFFFCE7F3),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Text(
            'Today\'s Price Drops',
            style: TextStyle(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Prices worth checking right now.',
            style: const TextStyle(
              color: Color(0xFF777E86),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          ...products.map(
                (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DealListTile(
                product: product,
                savedNames: savedNames,
                trackedNames: trackedNames,
                onToggleSaved: onToggleSaved,
                onToggleTracked: onToggleTracked,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DealListTile extends StatelessWidget {
  final DealProduct product;
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Function(String) onToggleSaved;
  final Function(String) onToggleTracked;

  const DealListTile({
    super.key,
    required this.product,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(
              product: product,
              onSaved: () => onToggleSaved(product.name),
              onTracked: () => onToggleTracked(product.name),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(product.icon, size: 38, color: silver),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.store,
                    style: TextStyle(
                      color: silver,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    product.name,
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.price,
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        product.oldPrice,
                        style: TextStyle(
                          color: Color(0xFF999FA6),
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    '↓ ${product.drop} saved',
                    style: TextStyle(
                      color: Color(0xFF5D646C),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    onToggleSaved(product.name);
                  },
                  child: Icon(
                    savedNames.contains(product.name)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: ink,
                    size: 22,
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    onToggleTracked(product.name);
                  },
                  child: Icon(
                    trackedNames.contains(product.name)
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: ink,
                    size: 22,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    product.discount,
                    style: TextStyle(
                      color: ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SavedPage extends StatelessWidget {
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Function(String) onToggleSaved;
  final Function(String) onToggleTracked;

  const SavedPage({
    super.key,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });

  @override
  Widget build(BuildContext context) {
    final saved = products
        .where((product) => savedNames.contains(product.name))
        .toList();

    if (saved.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: platinum,
            ),
            SizedBox(height: 15),
            Text(
              'No wishlist items yet',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Like a deal to save it here.',
              style: TextStyle(color: Color(0xFF888F97)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'Wishlist',
              style: TextStyle(
                color: ink,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: saved.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: .67,
              ),
              itemBuilder: (context, index) {
                final product = saved[index];

                return ProductCard(
                  product: product,
                  saved: true,
                  tracked: trackedNames.contains(product.name),
                  onSaved: () => onToggleSaved(product.name),
                  onTracked: () => onToggleTracked(product.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class PriceAlertsPage extends StatefulWidget {
  const PriceAlertsPage({super.key});

  @override
  State<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends State<PriceAlertsPage> {
  final Set<String> trackedNames = {};
  List<DealProduct> trackedProducts = [];

  @override
  void initState() {
    super.initState();
    loadTrackedProducts();
  }

  Future<void> loadTrackedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('trackedProducts') ?? [];

    final loaded = names
        .map(
          (name) => products.firstWhere(
            (product) => product.name == name,
        orElse: () => products.first,
      ),
    )
        .toList();

    if (!mounted) return;

    setState(() {
      trackedNames.addAll(names);
      trackedProducts = loaded;
    });
  }

  Future<void> removeAlert(String name) async {
    final prefs = await SharedPreferences.getInstance();

    trackedNames.remove(name);

    trackedProducts = trackedProducts
        .where((product) => product.name != name)
        .toList();

    await prefs.setStringList(
      'trackedProducts',
      trackedNames.toList(),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          'Price Alerts',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: trackedProducts.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 58,
              color: platinum,
            ),
            SizedBox(height: 14),
            Text(
              'No price alerts yet',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap the bell on a deal to track it.',
              style: TextStyle(
                color: Color(0xFF888F97),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trackedProducts.length,
        itemBuilder: (context, index) {
          final product = trackedProducts[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DealListTile(
              product: product,
              savedNames: const {},
              trackedNames: trackedNames,
              onToggleSaved: (_) {},
              onToggleTracked: removeAlert,
            ),
          );
        },
      ),
    );
  }
}
class ShoppingBagPage extends StatefulWidget {
  final Set<String> bagNames;
  final Function(String) onToggleBag;
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Function(String) onToggleSaved;
  final Function(String) onToggleTracked;

  const ShoppingBagPage({
    super.key,
    required this.bagNames,
    required this.onToggleBag,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });

  @override
  State<ShoppingBagPage> createState() => _ShoppingBagPageState();
}

class _ShoppingBagPageState extends State<ShoppingBagPage> {
  late Set<String> bagNames;

  @override
  void initState() {
    super.initState();
    bagNames = {...widget.bagNames};
  }

  Future<void> _removeFromBag(String name) async {
    await widget.onToggleBag(name);

    if (!mounted) return;

    setState(() {
      bagNames.remove(name);
    });

    showAppToast(context, 'Removed from shopping bag');
  }

  @override
  Widget build(BuildContext context) {
    final bag = products
        .where((product) => bagNames.contains(product.name))
        .toList();

    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          bag.isEmpty ? 'Shopping Bag' : 'Shopping Bag (${bag.length})',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: bag.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: ice,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 40,
                  color: platinum,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your bag is empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Add deals you want to keep together.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF888F97),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('Continue browsing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: actionText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bag.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: .67,
        ),
        itemBuilder: (context, index) {
          final product = bag[index];

          return ProductCard(
            product: product,
            saved: widget.savedNames.contains(product.name),
            tracked: widget.trackedNames.contains(product.name),
            onSaved: () => widget.onToggleSaved(product.name),
            onTracked: () => widget.onToggleTracked(product.name),
            onRemove: () => _removeFromBag(product.name),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage your DealEnds preferences.',
                  style: TextStyle(
                    color: Color(0xFF777E86),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          ListTile(
            tileColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(color: border),
            ),
            leading: Icon(
              Icons.notifications_none_rounded,
              color: silver,
            ),
            title: Text(
              'Notifications',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: platinum,
            ),
            onTap: () {},
          ),
          ListTile(
            tileColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(color: border),
            ),
            leading: Icon(
              Icons.language_rounded,
              color: silver,
            ),
            title: Text(
              'Language',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Choose your preferred language',
              style: TextStyle(
                color: silver,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: platinum,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(height: 8),
          ValueListenableBuilder<DealThemeOption>(
            valueListenable: DealThemeController.current,
            builder: (context, theme, _) {
              return ListTile(
                tileColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: BorderSide(color: border),
                ),
                leading: Icon(
                  Icons.palette_outlined,
                  color: silver,
                ),
                title: Text(
                  'Theme',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  DealThemeController.label(theme),
                  style: TextStyle(
                    color: silver,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: platinum,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ThemeSelectionPage(),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            tileColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(color: border),
            ),
            leading: Icon(
              Icons.info_outline_rounded,
              color: silver,
            ),
            title: Text(
              'About DealEnds',
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: platinum,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          'Theme',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ValueListenableBuilder<DealThemeOption>(
        valueListenable: DealThemeController.current,
        builder: (context, currentTheme, _) {
          final options = DealThemeOption.values;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your DealEnds look',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your choice is saved and will stay active when you reopen the app.',
                      style: TextStyle(
                        color: silver,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...options.map(
                    (theme) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ThemeOptionCard(
                    theme: theme,
                    selected: theme == currentTheme,
                    onTap: () {
                      DealThemeController.setTheme(theme);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final DealThemeOption theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = theme != DealThemeOption.silverBlack &&
        theme != DealThemeOption.forestGreenCream &&
        theme != DealThemeOption.beigeBrown;
    final previewBackground = switch (theme) {
      DealThemeOption.blackSilver => const Color(0xFF0D0F12),
      DealThemeOption.silverBlack => const Color(0xFFF5F6F8),
      DealThemeOption.blackGold => const Color(0xFF0D0C0A),
      DealThemeOption.forestGreenCream => const Color(0xFFF7F3E8),
      DealThemeOption.midnightBlueCyan => const Color(0xFF07131E),
      DealThemeOption.beigeBrown => const Color(0xFFF8F1E7),
      DealThemeOption.gradient => const Color(0xFFF5F7FF),
    };
    final previewAccent = switch (theme) {
      DealThemeOption.blackSilver => const Color(0xFFD8DCE1),
      DealThemeOption.silverBlack => const Color(0xFF15181C),
      DealThemeOption.blackGold => const Color(0xFFD4AF37),
      DealThemeOption.forestGreenCream => const Color(0xFF0F5132),
      DealThemeOption.midnightBlueCyan => const Color(0xFF22D3EE),
      DealThemeOption.beigeBrown => const Color(0xFF8B6F47),
      DealThemeOption.gradient => const Color(0xFF5B5FEF),
    };
    final previewText = dark ? Colors.white : const Color(0xFF15181C);
    final previewBorder = switch (theme) {
      DealThemeOption.blackSilver => const Color(0xFF2C3138),
      DealThemeOption.silverBlack => const Color(0xFFD8DDE3),
      DealThemeOption.blackGold => const Color(0xFF3D341F),
      DealThemeOption.forestGreenCream => const Color(0xFFD7E2D8),
      DealThemeOption.midnightBlueCyan => const Color(0xFF16364A),
      DealThemeOption.beigeBrown => const Color(0xFFDFD0BB),
      DealThemeOption.gradient => const Color(0xFFD9DFFF),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? previewAccent : border,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 58,
              decoration: BoxDecoration(
                color: previewBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: previewBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: previewAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 20,
                    height: 8,
                    decoration: BoxDecoration(
                      color: previewText.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DealThemeController.label(theme),
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DealThemeController.description(theme),
                    style: TextStyle(
                      color: silver,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? previewAccent : silver,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Future<void> Function(String) onToggleSaved;
  final Future<void> Function(String) onToggleTracked;

  const ProfilePage({
    super.key,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F7FF),
            Color(0xFFEDE9FE),
            Color(0xFFFCE7F3),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          // ------------------------------------------------------------
          // PROFILE
          // ------------------------------------------------------------

          Center(
            child: Text(
              'Profile',
              style: TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Profile icon
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFFC084FC),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: .18),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Sravan',
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 3),

          Center(
            child: Text(
              'email@example.com',
              style: TextStyle(
                color: silver,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Manage Account
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageAccountPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF8B5CF6),
                      Color(0xFFC084FC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: .18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Manage Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),


          const SizedBox(height: 20),

// TEMPORARY PUSH NOTIFICATION TEST
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await sendMyTestNotification();
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Test Push Notification'),
            ),
          ),

          const SizedBox(height: 30),

// ------------------------------------------------------------
// MAIN PROFILE ACTIONS

          Row(
            children: [
              Expanded(
                child: _profileAction(
                  icon: Icons.favorite_rounded,
                  label: 'Wishlist',
                  count: '0',
                  onTap: () {
                    // Wishlist navigation
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _profileAction(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  count: '0',
                  onTap: () {
                    // Alerts navigation
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _profileAction(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Shopping Bag',
                  count: '0',
                  onTap: () {
                    // Shopping Bag navigation
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 34),

          // ------------------------------------------------------------
          // DEALENDS
          // ------------------------------------------------------------

          _profileSectionTitle('DEALENDS'),

          const SizedBox(height: 12),

          _profileMenuItem(
            icon: Icons.auto_awesome_rounded,
            title: 'DealEnds Suggests',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DealEndsSuggestsPage(
                    savedNames: savedNames,
                    trackedNames: trackedNames,
                    onToggleSaved: onToggleSaved,
                    onToggleTracked: onToggleTracked,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          _profileMenuItem(
            icon: Icons.history_rounded,
            title: 'Recently Viewed',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecentlyViewedPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 34),

          // ------------------------------------------------------------
          // ACCOUNT
          // ------------------------------------------------------------

          _profileSectionTitle('ACCOUNT'),

          const SizedBox(height: 12),

          _profileMenuItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          _profileMenuItem(
            icon: Icons.help_center_rounded,
            title: 'Help Centre',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpSupportPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 34),

          // ------------------------------------------------------------
          // LEGAL & POLICIES
          // ------------------------------------------------------------

          _profileSectionTitle('LEGAL & POLICIES'),

          const SizedBox(height: 12),

          _profileMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms of Use',
            onTap: () async {
              final uri = Uri.parse(
                'https://dealends-product-sync.sravansmangattu60.workers.dev/terms',
              );

              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
          ),

          const SizedBox(height: 18),

          _profileMenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy Policy',
            onTap: () async {
              final uri = Uri.parse(
                'https://dealends-product-sync.sravansmangattu60.workers.dev/privacy',
              );

              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
          ),

          const SizedBox(height: 32),

          // ------------------------------------------------------------
          // INSTAGRAM
          // ------------------------------------------------------------

          Center(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(
                  'https://instagram.com/dealends',
                );

                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Follow us on Instagram',
                    style: TextStyle(
                      color: const Color(0xFF6C63FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------------
          // VERSION
          // ------------------------------------------------------------

          Center(
            child: Column(
              children: [
                Text(
                  'App Version',
                  style: TextStyle(
                    color: silver,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1.0.0.0',
                  style: TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN PROFILE ACTION
  // ============================================================

  Widget _profileAction({
    required IconData icon,
    required String label,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .72),
              border: Border.all(
                color: const Color(0xFFD9DFFF),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C63FF),
              size: 25,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            count,
            style: TextStyle(
              color: const Color(0xFF6C63FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _profileSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF6C63FF),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _profileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 21,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: const Text(
          'Manage Account',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: soft,
        foregroundColor: ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _groupCard(
            children: [
              _profileRow(
                Icons.person_outline_rounded,
                'Account & Details',
                onTap: () => _showAccountDetails(context),
              ),
              _divider(),
              _profileRow(
                Icons.lock_outline_rounded,
                'Privacy Policy',
                onTap: () async {
                  final uri = Uri.parse(
                    'https://dealends-product-sync.sravansmangattu60.workers.dev/privacy',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              _divider(),
              _profileRow(
                Icons.description_outlined,
                'Terms of Use',
                onTap: () async {
                  final uri = Uri.parse(
                    'https://dealends-product-sync.sravansmangattu60.workers.dev/terms',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => _showLogoutNotice(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A72),
                side: const BorderSide(color: Color(0xFFFF5A72)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _groupCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }

  static Widget _profileRow(
      IconData icon,
      String title, {
        VoidCallback? onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      minVerticalPadding: 4,
      onTap: onTap,
      leading: Icon(icon, color: silver, size: 22),
      title: Text(
        title,
        style: TextStyle(color: ink, fontWeight: FontWeight.w800),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: silver),
    );
  }

  static Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: border,
    );
  }

  Future<void> _showAccountDetails(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          'Account & Details',
          style: TextStyle(color: ink, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email', style: TextStyle(color: silver, fontSize: 11)),
            const SizedBox(height: 3),
            Text(user.email ?? 'Not provided', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('Phone', style: TextStyle(color: silver, fontSize: 11)),
            const SizedBox(height: 3),
            Text(user.phoneNumber ?? 'Not provided', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('Verification', style: TextStyle(color: silver, fontSize: 11)),
            const SizedBox(height: 3),
            Text(user.emailVerified ? 'Email verified' : 'Email not verified', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE', style: TextStyle(color: actionColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutNotice(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          'Log out',
          style: TextStyle(color: ink, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'You will need to sign in again to access your DealEnds account.',
          style: TextStyle(color: silver, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: silver, fontWeight: FontWeight.w800)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: actionColor, foregroundColor: actionText),
            child: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find answers to common questions about DealEnds.',
                  style: TextStyle(
                    color: Color(0xFF777E86),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          _helpItem(
            'How do I save a deal?',
            'Tap the heart icon on any deal or product page. Your wishlist keeps them together.',
          ),
          _helpItem(
            'How does price tracking work?',
            'Tap the bell icon on a deal to add it to your price alerts.',
          ),
          _helpItem(
            'Where can I find recently viewed deals?',
            'Open Profile and select Recently viewed.',
          ),
          _helpItem(
            'How do I add a product to my bag?',
            'Open a product and tap the shopping bag icon.',
          ),
          _helpItem(
            'How do I open a deal?',
            'Open the product page and tap VIEW DEAL to visit the store.',
          ),
        ],
      ),
    );
  }

  static Widget _helpItem(String title, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ExpansionTile(
        iconColor: platinum,
        collapsedIconColor: silver,
        title: Text(
          title,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Color(0xFF777E86),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class DealEndsSuggestsPage extends StatefulWidget {
  final Set<String> savedNames;
  final Set<String> trackedNames;
  final Future<void> Function(String) onToggleSaved;
  final Future<void> Function(String) onToggleTracked;

  const DealEndsSuggestsPage({
    super.key,
    required this.savedNames,
    required this.trackedNames,
    required this.onToggleSaved,
    required this.onToggleTracked,
  });
  @override
  State<DealEndsSuggestsPage> createState() =>
      _DealEndsSuggestsPageState();
}

class _DealEndsSuggestsPageState
    extends State<DealEndsSuggestsPage> {
  Future<void> _handleTracked(String name) async {
    await widget.onToggleTracked(name);

    if (!mounted) return;
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final suggestions = [...products]
      ..sort((a, b) {
        final aDiscount =
            int.tryParse(a.discount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bDiscount =
            int.tryParse(b.discount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return bDiscount.compareTo(aDiscount);
      });

    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        backgroundColor: soft,
        title: Text(
          'DealEnds Suggests',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: suggestions.isEmpty
          ? Center(
        child: Text(
          'No suggestions available yet',
          style: TextStyle(color: silver),
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFD4AF37),
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Picked for you',
                            style: TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Explore deals with the biggest listed discounts.',
                            style: TextStyle(
                              color: silver,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = suggestions[index];

                  return ProductCard(
                    product: product,
                    saved: widget.savedNames.contains(product.name),
                    tracked: widget.trackedNames.contains(product.name),
                    onSaved: () => widget.onToggleSaved(product.name),
                    onTracked: () => _handleTracked(product.name),
                  );
                },
                childCount: suggestions.length,
              ),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.67,
              ),
            ),
          ),
        ],
      ),
    );
  }
}class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({super.key});

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> {
  final Set<String> savedNames = {};
  final Set<String> trackedNames = {};
  List<DealProduct> recentlyViewed = [];

  @override
  void initState() {
    super.initState();
    loadRecentlyViewed();
    loadSavedAndTracked();
  }

  Future<void> loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('recentlyViewed') ?? [];

    final loaded = names
        .map(
          (name) => products.firstWhere(
            (product) => product.name == name,
        orElse: () => products.first,
      ),
    )
        .toList();

    if (!mounted) return;

    setState(() {
      recentlyViewed = loaded;
    });
  }
  Future<void> loadSavedAndTracked() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getStringList('savedProducts') ?? [];
    final tracked = prefs.getStringList('trackedProducts') ?? [];

    if (!mounted) return;

    setState(() {
      savedNames.addAll(saved);
      trackedNames.addAll(tracked);
    });
  }
  Future<void> toggleRecentSaved(String name) async {
    setState(() {
      if (savedNames.contains(name)) {
        savedNames.remove(name);
      } else {
        savedNames.add(name);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'savedProducts',
      savedNames.toList(),
    );
  }

  Future<void> toggleRecentTracked(String name) async {
    setState(() {
      if (trackedNames.contains(name)) {
        trackedNames.remove(name);
      } else {
        trackedNames.add(name);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'trackedProducts',
      trackedNames.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: Text(
          'Recently Viewed',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: recentlyViewed.isEmpty
          ? Center(
        child: Text(
          'No recently viewed deals',
          style: TextStyle(
            color: silver,
            fontWeight: FontWeight.w700,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recentlyViewed.length,
        itemBuilder: (context, index) {
          final product = recentlyViewed[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DealListTile(
              product: product,
              savedNames: savedNames,
              trackedNames: trackedNames,
              onToggleSaved: toggleRecentSaved,
              onToggleTracked: toggleRecentTracked,
            ),
          );
        },
      ),
    );
  }
}
class _ProductImageDoubleTapHeart extends StatefulWidget {
  final bool Function() onDoubleTap;

  const _ProductImageDoubleTapHeart({
    required this.onDoubleTap,
  });

  @override
  State<_ProductImageDoubleTapHeart> createState() =>
      _ProductImageDoubleTapHeartState();
}

class _ProductImageDoubleTapHeartState
    extends State<_ProductImageDoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _doubleTapWillLike = true;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  Future<void> _handleDoubleTap() async {
    final adding = widget.onDoubleTap();

    setState(() {
      _doubleTapWillLike = adding;
      _showHeart = true;
    });

    await _controller.forward(from: 0);

    if (mounted) {
      setState(() => _showHeart = false);
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SizedBox.expand(),
          if (_showHeart)
            IgnorePointer(
              child: Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(.35, 1),
                      ),
                    ),
                    child: Icon(
                      _doubleTapWillLike
                          ? Icons.favorite_rounded
                          : Icons.heart_broken_rounded,
                      color: _doubleTapWillLike
                          ? const Color(0xFFFF3B4D)
                          : Colors.red,
                      size: 86,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
final Map<String, ValueNotifier<bool>> _productSavedStates = {};
final Set<String> _loadedProductSavedStates = {};

ValueNotifier<bool> _savedStateFor(String name) {
  return _productSavedStates.putIfAbsent(
    name,
        () => ValueNotifier<bool>(false),
  );
}

Future<void> _loadProductSavedState(String name) async {
  if (!_loadedProductSavedStates.add(name)) return;

  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('savedProducts') ?? [];

  _savedStateFor(name).value = saved.contains(name);
}
class ProductPage extends StatelessWidget {
  final DealProduct product;
  final VoidCallback? onSaved;
  final VoidCallback? onTracked;

  const ProductPage({
    super.key,
    required this.product,
    this.onSaved,
    this.onTracked,
  });

  Future<void> _toggleBag(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bag = prefs.getStringList('bagProducts') ?? [];

    final adding = !bag.contains(product.name);
    if (adding) {
      bag.add(product.name);
    } else {
      bag.remove(product.name);
    }

    await prefs.setStringList('bagProducts', bag);
    if (!context.mounted) return;

    showAppToast(
      context,
      adding ? 'Added to shopping bag' : 'Removed from shopping bag',
    );
  }


  Future<void> _openDeal(BuildContext context) async {
    final url = product.dealUrl?.trim();

    if (url == null || url.isEmpty) {
      showAppToast(
        context,
        'Deal link not available yet',
        error: true,
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      showAppToast(
        context,
        'This deal link is invalid',
        error: true,
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        showAppToast(
          context,
          'Could not open deal link',
          error: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(
          context,
          'Could not open deal link',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadProductSavedState(product.name);
    recordRecentlyViewed(product);



    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: () async {
              final url = product.dealUrl;
              final message = url == null
                  ? '${product.name}\n${product.price}\n${product.discount}\nDealEnds'
                  : '${product.name}\n${product.price}\n${product.discount}\n$url';

              await SharePlus.instance.share(
                ShareParams(
                  text: message,
                  subject: 'DealEnds Deal',
                ),
              );
            },
            icon: Icon(Icons.share_outlined, color: ink, size: 21),
          ),
          FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then(
                  (prefs) =>
                  (prefs.getStringList('trackedProducts') ?? []).contains(product.name),
            ),
            builder: (context, snapshot) {
              var isTracked = snapshot.data ?? false;
              return StatefulBuilder(
                builder: (context, setIconState) {
                  return IconButton(
                    onPressed: () {
                      final adding = !isTracked;
                      onTracked?.call();
                      setIconState(() => isTracked = adding);
                      showAppToast(
                        context,
                        adding
                            ? '${product.name} added to price tracking'
                            : '${product.name} removed from price tracking',
                      );
                    },
                    icon: Icon(
                      isTracked
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: isTracked ? actionColor : ink,
                      size: 21,
                    ),
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: _savedStateFor(product.name),
            builder: (context, isSaved, _) {
              return IconButton(
                onPressed: () {
                  final adding = !isSaved;

                  _savedStateFor(product.name).value = adding;
                  onSaved?.call();

                  showAppToast(
                    context,
                    adding ? 'Added to wishlist' : 'Removed from wishlist',
                  );
                },

                icon: Icon(
                  isSaved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isSaved ? actionColor : ink,
                  size: 21,
                ),
              );
            },
          ),

          FutureBuilder<bool>(
            future: SharedPreferences.getInstance().then(
                  (prefs) =>
                  (prefs.getStringList('bagProducts') ?? []).contains(product.name),
            ),
            builder: (context, snapshot) {
              var isInBag = snapshot.data ?? false;
              return StatefulBuilder(
                builder: (context, setIconState) {
                  return IconButton(
                    onPressed: () async {
                      await _toggleBag(context);
                      if (context.mounted) {
                        setIconState(() => isInBag = !isInBag);
                      }
                    },
                    icon: Icon(
                      isInBag
                          ? Icons.shopping_bag_rounded
                          : Icons.shopping_bag_outlined,
                      color: isInBag ? actionColor : ink,
                      size: 21,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 304,
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: .88,
                          colors: [
                            platinum.withValues(alpha: .14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      product.imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          product.icon,
                          size: 152,
                          color: platinum.withValues(alpha: .95),
                        );
                      },
                    ),
                  )
                      :product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                    product.imageUrl!,
                    width: 152,
                    height: 152,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        product.icon,
                        size: 152,
                        color: platinum.withValues(alpha: .95),
                      );
                    },
                  )
                      : Icon(
                    product.icon,
                    size: 152,
                    color: platinum.withValues(alpha: .95),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        product.discount,
                        style: TextStyle(
                          color: actionText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: _ProductImageDoubleTapHeart(
                      onDoubleTap: () {
                        final savedState = _savedStateFor(product.name);
                        final adding = !savedState.value;

                        savedState.value = adding;
                        onSaved?.call();

                        showAppToast(
                          context,
                          adding ? 'Added to wishlist' : 'Removed from wishlist',
                        );

                        return adding;
                      },
                    ),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 24,
                      height: 1.07,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.55,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: platinum, size: 17),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating} (${product.dealScore} deal score)',
                        style: TextStyle(
                          color: silver,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 9,
                    runSpacing: 7,
                    children: [
                      Text(
                        product.price,
                        style: TextStyle(
                          color: ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        product.oldPrice,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7D858F),
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: border,
                          ),
                        ),
                        child: Text(
                          product.discount,
                          style: TextStyle(
                            color: actionText,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'You save ${product.drop}',
                    style: TextStyle(
                      color: silver,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _productChip(product.store),
                      _productChip('Rating ${product.rating}'),
                      _productChip('Deal ${product.dealScore}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        initiallyExpanded: false,
                        title: Text(
                          'Why this deal?',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          'Tap the arrow to see the deal details',
                          style: TextStyle(
                            color: silver,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        iconColor: ink,
                        collapsedIconColor: ink,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: soft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: ice,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        Icons.local_fire_department_rounded,
                                        color: silver,
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${product.discount} price drop from the previous price',
                                        style: TextStyle(
                                          color: ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _dealInfoRow(Icons.savings_rounded, 'You save', product.drop),
                                const SizedBox(height: 11),
                                _dealInfoRow(Icons.percent_rounded, 'Discount', product.discount),
                                const SizedBox(height: 11),
                                _dealInfoRow(Icons.star_rounded, 'Rating', '${product.rating}/5'),
                                const SizedBox(height: 11),
                                _dealInfoRow(Icons.storefront_rounded, 'Store', product.store),
                                const SizedBox(height: 11),
                                _dealInfoRow(Icons.verified_rounded, 'Deal score', '${product.dealScore}/100'),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ice,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, color: silver, size: 18),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _dealVerdict(product),
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 12.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this deal',
                          style: TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _productSummary(product),
                          style: TextStyle(
                            color: silver,
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Price can change. Check the retailer before purchasing.',
                    style: TextStyle(
                      color: silver,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _openDeal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: actionText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'VIEW DEAL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  static String _productSummary(DealProduct product) {
    final brandText =
    product.brand != null && product.brand!.isNotEmpty
        ? ' Brand: ${product.brand}.'
        : '';

    final descriptionText =
    product.description != null && product.description!.isNotEmpty
        ? ' ${product.description}'
        : '';

    final reviewsText = product.reviewCount > 0
        ? ' Based on ${product.reviewCount} reviews.'
        : '';

    return '${product.name} is listed at ${product.price} with '
        '${product.discount} off the previous ${product.oldPrice}, '
        'saving ${product.drop}.$brandText$descriptionText '
        'This ${product.category.toLowerCase()} deal is from ${product.store}, '
        'rated ${product.rating}/5$reviewsText with a deal score of '
        '${product.dealScore}/100.';
  }
  Widget _productChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ice,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ink,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

}

class DealSearchDelegate extends SearchDelegate<String> {
  final Set<String> savedProducts;
  final Set<String> trackedProducts;
  final Function(String) onSaved;
  final Function(String) onTracked;
  final VoidCallback onCamera;
  final VoidCallback onMicrophone;

  DealSearchDelegate({
    required this.savedProducts,
    required this.trackedProducts,
    required this.onSaved,
    required this.onTracked,
    required this.onCamera,
    required this.onMicrophone,
  });
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        iconTheme: IconThemeData(color: ink),
        actionsIconTheme: IconThemeData(color: ink),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: silver),
        labelStyle: TextStyle(color: silver),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: ice,
        selectionHandleColor: ink,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: onMicrophone,
        tooltip: 'Voice search',
        icon: Icon(
          Icons.mic_none_rounded,
          color: silver,
        ),
      ),
      IconButton(
        onPressed: onCamera,
        tooltip: 'Camera search',
        icon: Icon(
          Icons.photo_camera_outlined,
          color: silver,
        ),
      ),
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          tooltip: 'Clear',
          icon: Icon(
            Icons.clear_rounded,
            color: silver,
          ),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: Icon(Icons.arrow_back_rounded),
    );
  }

  List<DealProduct> get results {
    if (query.trim().isEmpty) return products;

    return products.where((product) {
      final text =
      '${product.name} ${product.category} ${product.store}'
          .toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResults(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResults(context);
  }

  Widget _buildResults(BuildContext context) {
    final matches = results;

    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No deals found',
          style: TextStyle(
            color: silver,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      color: soft,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: matches.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: .67,
        ),
        itemBuilder: (context, index) {
          final product = matches[index];
          return StatefulBuilder(
            builder: (context, setCardState) {
              bool isSaved = savedProducts.contains(product.name);
              bool isTracked = trackedProducts.contains(product.name);

              return ProductCard(
                product: product,
                saved: isSaved,
                tracked: isTracked,
                onSaved: () {
                  setCardState(() {
                    isSaved = !isSaved;
                  });

                  onSaved(product.name);

                  showAppToast(context, isSaved ? 'Added to saved deals' : 'Removed from saved deals');
                },
                onTracked: () {
                  setCardState(() {
                    isTracked = !isTracked;
                  });

                  onTracked(product.name);

                  showAppToast(context, isTracked ? 'Added to price tracking' : 'Removed from price tracking');
                },
              );
            },
          );
        },
      ),
    );
  }
}Widget _dealInfoRow(
    IconData icon,
    String label,
    String value,
    ) {
  return Row(
    children: [
      Icon(
        icon,
        size: 18,
        color: silver,
      ),

      SizedBox(width: 10),

      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B6872),
          ),
        ),
      ),

      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: ink,
        ),
      ),
    ],
  );
}

String _dealVerdict(DealProduct product) {
  final score = product.dealScore;

  if (score >= 90) {
    return 'Excellent deal — this price drop is worth checking right now.';
  }

  if (score >= 80) {
    return 'Strong deal — the current price is significantly lower than before.';
  }

  if (score >= 70) {
    return 'Good deal — there is a noticeable saving compared with the previous price.';
  }

  return 'Worth checking — compare the current price before buying.';
}
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const String contactEmail = 'dealendsapp@gmail.com';
  static const String instagramUrl =
      'https://www.instagram.com/dealendsapp/';

  Future<void> _openEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: contactEmail,
    );

    final launched = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      await Clipboard.setData(
        const ClipboardData(
          text: contactEmail,
        ),
      );
    }
  }

  Future<void> _openInstagram() async {
    final Uri instagramUri = Uri.parse(instagramUrl);

    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(
        instagramUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: soft,
      appBar: AppBar(
        title: const Text(
          'Contact',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: soft,
        foregroundColor: ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _contactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: contactEmail,
            onTap: () => _openEmail(context),
          ),
          const SizedBox(height: 14),
          _contactCard(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: 'Follow DealEnds on Instagram',
            onTap: _openInstagram,
          ),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, color: silver, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: silver,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: silver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}




