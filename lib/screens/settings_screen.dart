import 'package:chat_app/screens/blocked_users_page.dart';
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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
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
      await user.updateEmail(_emailController.text);
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
      try {
        User? user = FirebaseAuth.instance.currentUser;

        // Update name
        if (_nameController.text.isNotEmpty &&
            _nameController.text != user?.displayName) {
          await user?.updateDisplayName(_nameController.text);
        }

        // Update email
        if (_emailController.text.isNotEmpty &&
            _emailController.text != user?.email) {
          await _reauthenticateAndUpdateEmail(user!);
        }

        // Update password
        if (_passwordController.text.isNotEmpty) {
          await user?.updatePassword(_passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password updated successfully!')),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User details updated successfully!')),
        );
        user?.reload();
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Update User Info'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration:
                          InputDecoration(labelText: 'Current Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password to update email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateUser,
                      child: Text('Update'),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
