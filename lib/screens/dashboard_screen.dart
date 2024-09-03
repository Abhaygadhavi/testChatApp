import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/screens/chat_page.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/services/auth/auth_provider.dart' as auth;
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:chat_app/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const String id = 'dashboard_screen';

  DashboardScreen({super.key});
  final ChatService _chatService = ChatService();

  //show options
  void _showOptions(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              //block user button
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text("Block"),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context, userId, userName);
                },
              ),

              //cancel button
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //block user
  void _blockUser(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Block User"),
        content: Text("Are you sure you want to block this user?"),
        actions: [
          //cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          //report button
          TextButton(
            onPressed: () {
              //perform block
              ChatService().blockUser(userId);
              //dismiss dialog
              Navigator.pop(context);
              //let user know about the result
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(userName + " Blocked")));
            },
            child: Text("Block"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth.AuthProvider>(context);
    var user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Welcome ${user?.displayName ?? 'User'}'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: MyDrawer(),
      body: _buildUserList(user),
    );
  }

  Widget _buildUserList(User? user) {
    return StreamBuilder(
      stream: _chatService.getUsersStreamExcludingBlocked(),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return const Text("error");
        }
        //loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }
        //return listview
        return ListView(
          children: snapshot.data!
              .map<Widget>(
                  (userData) => _buildUserListItem(userData, context, user))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context, User? user) {
    //display all user except current user
    if (userData["email"] != user?.email) {
      return UserTile(
        onLongPress: () =>
            _showOptions(context, userData["uid"], userData["name"]),
        text: userData["name"],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData["email"],
                receiverName: userData["name"],
                receiverID: userData["uid"],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}
