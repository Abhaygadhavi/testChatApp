import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileUpdateScreen extends StatefulWidget {
  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _toggleLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _updateNameAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in.')),
      );
      return;
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text,
    );

    try {
      _toggleLoading(true);

      // Reauthenticate the user with the current credentials
      await user.reauthenticateWithCredential(credential);

      // Update the display name if the name is not empty
      if (_nameController.text.isNotEmpty) {
        await user.updateDisplayName(_nameController.text);
      }

      // Update the password if the password field is not empty
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      await user.reload(); // Refresh user info
      _toggleLoading(false);

      // Log out the user after updates
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated. Please log in again.')),
      );

      // Redirect to login or main screen
      // Redirect to the login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthGate()),
        (Route<dynamic> route) => false, // Removes all routes
      );
    } on FirebaseAuthException catch (e) {
      _toggleLoading(false);
      _handleFirebaseAuthException(e);
    } catch (e) {
      _toggleLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'wrong-password':
        message = 'Incorrect current password. Please try again.';
        break;
      case 'requires-recent-login':
        message = 'Please log in again to perform this action.';
        break;
      default:
        message = 'An error occurred: ${e.message}';
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'New Name'),
                ),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current password cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New password cannot be empty';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateNameAndPassword,
                  child:
                      _isLoading ? CircularProgressIndicator() : Text('Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
