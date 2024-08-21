import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  static const String id = 'dashboard_screen';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "user";
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName.toString();
      });
    } else {
      print("user not found");
    }
  }

  List<String> users = ['User 1', 'User 2', 'User 3'];
  List<String> friends = ['Friend 1', 'Friend 2', 'Friend 3'];

  void sendRequest(String user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to $user')),
    );
  }

  void unfollowFriend(String friend) {
    setState(() {
      friends.remove(friend);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unfollowed $friend')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Dashboard',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello,$userName",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              Text(
                'Users',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Column(
                children: users.map((user) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(user, style: TextStyle(fontSize: 18)),
                      ElevatedButton(
                        onPressed: () => sendRequest(user),
                        child: Text('Send Request',
                            style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              Text(
                'Friends',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Column(
                children: friends.map((friend) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(friend, style: TextStyle(fontSize: 18)),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, ChatScreen.id);
                        },
                        child: Text('Chat',
                            style: TextStyle(color: Colors.blueAccent)),
                      ),
                      ElevatedButton(
                        onPressed: () => unfollowFriend(friend),
                        child: Text('Unfollow',
                            style: TextStyle(color: Colors.blueAccent)),
                        //style: ElevatedButton.styleFrom(primary: Colors.red),
                      ),
                    ],
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                },
                child: Text('LogOut'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.person),
              color: Colors.blueAccent,
              onPressed: () {
                Navigator.pushNamed(context, SettingsScreen.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
