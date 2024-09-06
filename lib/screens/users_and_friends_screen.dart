import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/screens/chat_page.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersAndFriendsScreen extends StatefulWidget {
  @override
  _UsersAndFriendsScreenState createState() => _UsersAndFriendsScreenState();
}

class _UsersAndFriendsScreenState extends State<UsersAndFriendsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final ChatService _chatService = ChatService();
  List<String> localSentRequests =
      []; // Track requests sent locally for immediate feedback

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Center(child: Text("Please log in"));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Users and Friends'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: MyDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          var userDoc = snapshot.data!;

          // Safely handle missing "friends" and "friendRequests" fields
          List<String> friends = [];
          if (userDoc.data() != null && userDoc['friends'] != null) {
            friends = List<String>.from(userDoc['friends']);
          }
          List<String> friendRequests = [];
          if (userDoc.data() != null && userDoc['friendRequests'] != null) {
            friendRequests = List<String>.from(userDoc['friendRequests'] ?? []);
          }

          return Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text("All Users"),
                    Expanded(child: buildUsersList(friends, friendRequests)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text("Friends"),
                    Expanded(child: buildFriendsList(friends)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildUsersList(List<String> friends, List<String> friendRequests) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').snapshots(),
      builder: (context, snapshot1) {
        if (!snapshot1.hasData) return CircularProgressIndicator();

        var users = snapshot1.data!.docs;

        // Stream blocked users directly from Firestore
        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser!.uid)
              .collection("BlockedUsers")
              .snapshots(),
          builder: (context, snapshot2) {
            if (!snapshot2.hasData) return CircularProgressIndicator();

            // Extract blocked users ids from the snapshot, defaulting to an empty list if not present
            var blockedUsers =
                snapshot2.data!.docs.map((doc) => doc.id).toList();

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];
                var userId = user.id;
                var userName = user['name'];
                if (userId == currentUser!.uid ||
                    friends.contains(userId) ||
                    blockedUsers!.contains(userId)) {
                  return Container(); // Skip current user,already friends and blocked users
                }

                //if the other user have sent the logged in user friend request
                if (friendRequests.contains(userId)) {
                  return ListTile(
                    title: Text(userName),
                    trailing: ElevatedButton(
                      onPressed: () {
                        acceptFriendRequest(currentUser!.uid, userId);
                      },
                      child: Text('Accept'),
                    ),
                  );
                }
                bool requestSent = localSentRequests.contains(userId);

                return ListTile(
                  title: Text(userName),
                  trailing: ElevatedButton(
                    onPressed:
                        requestSent ? null : () => sendFriendRequest(userId),
                    child: Text(requestSent ? "Pending" : "Send Request"),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void acceptFriendRequest(String currentUserId, String requesterId) async {
    print(currentUserId);
    print(requesterId);
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .update({
      'friends': FieldValue.arrayUnion([requesterId])
    });

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(requesterId)
        .update({
      'friends': FieldValue.arrayUnion([currentUserId])
    });

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUserId)
        .update({
      'friendRequests': FieldValue.arrayRemove([requesterId])
    });
  }

  void sendFriendRequest(String targetUserId) async {
    final targetUserDocRef =
        FirebaseFirestore.instance.collection('Users').doc(targetUserId);

    // Optimistic UI update: Add the user ID to localSentRequests
    setState(() {
      localSentRequests.add(targetUserId);
    });

    try {
      // Ensure the target user's document exists before updating
      await targetUserDocRef.update({
        'friendRequests': FieldValue.arrayUnion([currentUser!.uid])
      });
    } catch (e) {
      print("Error sending friend request: $e");

      // Rollback the UI update if Firestore update fails
      setState(() {
        localSentRequests.remove(targetUserId);
      });
    }
  }

  Widget buildFriendsList(List<String> friends) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        var users = snapshot.data!.docs
            .where((user) => friends.contains(user.id))
            .toList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            var userName = user['name'];

            return UserTile(
              onLongPress: () =>
                  _showOptions(context, user["uid"], user["name"]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverEmail: user["email"],
                      receiverName: user["name"],
                      receiverID: user["uid"],
                    ),
                  ),
                );
              },
              text: userName,
            );
          },
        );
      },
    );
  }

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
              _chatService.blockUser(userId);
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
}
