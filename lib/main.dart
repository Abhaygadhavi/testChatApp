import 'package:chat_app/screens/dashboard_screen.dart';
import 'package:chat_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/screens/welcome_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/registration_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/components/theme_provider.dart';
import 'package:chat_app/services/auth/auth_provider.dart';
import 'services/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBWBWdNFlzvhDSL92M9333cF_qZV2l9iQY",
      appId: "1:827255126548:android:5afc930ff1d63308284501",
      messagingSenderId: "827255126548",
      projectId: "super-chat-95836",
    ),
  );
  runApp(FlashChat());
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            themeMode: themeProvider.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            initialRoute: AuthGate.id,
            routes: {
              AuthGate.id: (context) => AuthGate(),
              WelcomeScreen.id: (context) => WelcomeScreen(),
              LoginScreen.id: (context) => LoginScreen(),
              RegistrationScreen.id: (context) => RegistrationScreen(),
              ChatScreen.id: (context) => ChatScreen(),
              DashboardScreen.id: (context) => DashboardScreen(),
              SettingsScreen.id: (context) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
