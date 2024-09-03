import 'package:chat_app/screens/blocked_users_page.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/profile_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/components/theme_provider.dart';

class SettingsScreen extends StatefulWidget with ChangeNotifier {
  static const String id = 'settings_screen';

  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false; // Flag to manage loading state

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _reauthenticateAndUpdateEmail(User user) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(_emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email updated successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update email: ${e.message}')),
      );
    }
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Start loading
      });
      try {
        User? user = FirebaseAuth.instance.currentUser;
        bool isSuccessName = false;
        bool isSuccessEmail = false;

        // Update name
        if (_nameController.text.isNotEmpty &&
            _nameController.text != user?.displayName) {
          await user?.updateDisplayName(_nameController.text);
          if (user?.displayName == _nameController.text) {
            isSuccessName = true;
          } else {
            isSuccessName = false;
          }
        }

        // Update email
        if (_emailController.text.isNotEmpty &&
            _emailController.text != user!.email) {
          await _reauthenticateAndUpdateEmail(user);
          if (user.email == _emailController.text) {
            isSuccessEmail = true;
          } else {
            isSuccessEmail = true;
          }
        }

        // Update password
        if (_passwordController.text.isNotEmpty) {
          await user!.updatePassword(_passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password updated successfully!')),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User details updated successfully!')),
        );
        await _auth.signOut();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: ${e.message}')),
        );
        print(e.message);
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileUpdateScreen(),
                        )),
                    child: ListTile(
                      leading: Icon(
                        Icons.block,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      title: Text(
                        "Edit profile",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  PopupMenuButton<AppTheme>(
                    onSelected: (AppTheme theme) {
                      themeProvider.setTheme(theme);
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<AppTheme>>[
                      const PopupMenuItem<AppTheme>(
                        value: AppTheme.dark,
                        child: Text('Dark Theme'),
                      ),
                      const PopupMenuItem<AppTheme>(
                        value: AppTheme.light,
                        child: Text('Light Theme'),
                      ),
                      const PopupMenuItem<AppTheme>(
                        value: AppTheme.systemDefault,
                        child: Text('System Default Theme'),
                      ),
                    ],
                    child: ListTile(
                      leading: Icon(
                        Icons.sunny,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      title: _currentTheme(themeProvider),
                      trailing: Icon(
                        Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ),

                  //blocked users
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlockedUsersPage(),
                        )),
                    child: ListTile(
                      leading: Icon(
                        Icons.block,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      title: Text(
                        "Blocked Users",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Text _currentTheme(ThemeProvider themeProvider) {
    if (themeProvider.themeMode == ThemeMode.system) {
      return Text("System Mode",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary, fontSize: 18));
    }
    if (themeProvider.themeMode == ThemeMode.light) {
      return Text("Light Mode",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary, fontSize: 18));
    }
    if (themeProvider.themeMode == ThemeMode.dark) {
      return Text("Dark Mode",
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary, fontSize: 18));
    }
    return Text("choose mode",
        style: TextStyle(
            color: Theme.of(context).colorScheme.primary, fontSize: 18));
  }
}
