import 'package:chat_app/screens/users_and_friends_screen.dart';
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

  // Separate function to update the user's name
  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in.')),
      );
      return;
    }

    try {
      _toggleLoading(true);

      // Update the display name
      await user.updateDisplayName(_nameController.text);
      await user.reload(); // Refresh user info

      _toggleLoading(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully.')),
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

  // Separate function to update the user's password
  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in.')),
      );
      return;
    }

    try {
      _toggleLoading(true);

      // Reauthenticate the user with the current credentials
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(_passwordController.text);
      await user.reload(); // Refresh user info

      _toggleLoading(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully.')),
      );

      // Log out the user after updates
      await FirebaseAuth.instance.signOut();

      // Redirect to the login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthGate()),
        (Route<dynamic> route) => false,
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

  // Function to show warning dialog before updating password
  Future<void> _showPasswordUpdateWarning() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text(
              'Are you sure you want to update the password? This action will log you out.'),
          actions: [
            TextButton(
              onPressed: () {
                // Clear the text fields and dismiss the dialog
                _currentPasswordController.clear();
                _passwordController.clear();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Proceed with updating the password
                Navigator.of(context).pop();
                _updatePassword();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
        title: Text(
            'Update Profile for ${FirebaseAuth.instance.currentUser!.displayName}'),
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateName,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Update Name'),
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
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showPasswordUpdateWarning,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
