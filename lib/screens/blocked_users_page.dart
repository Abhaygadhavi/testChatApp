import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/services/auth/auth_provider.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  //chat and auth provider
  final ChatService chatService = ChatService();
  final AuthProvider authProvider = AuthProvider();

  //show confirm unblock box
  void _showUnblockBox(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Unblock User"),
        content: Text("Are you sure you want to unblock this user?"),
        actions: [
          //cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),

          //unblock button
          TextButton(
            onPressed: () {
              ChatService().unblockUser(userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(userName + " Unblocked")));
            },
            child: Text("Unblock"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //get current user's id
    String userId = authProvider.currentUser!.uid;

    //UI
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getBlockedUsersStrem(userId),
        builder: (context, snapshot) {
          //errors
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading"),
            );
          }

          //loading..
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final blockedUsers = snapshot.data ?? [];
          print("blockedusers");
          print(blockedUsers);
          //no users
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("No blocked users"),
            );
          }
          //load complete
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return UserTile(
                text: user["name"],
                onTap: () =>
                    _showUnblockBox(context, user['uid'], user["name"]),
              );
            },
          );
        },
      ),
    );
  }
}
