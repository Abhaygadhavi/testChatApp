import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatelessWidget {
  final String userId;
  FriendRequestsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Friend Requests')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot1) {
          if (!snapshot1.hasData) return CircularProgressIndicator();

          var userDoc = snapshot1.data!;
          List friendRequests = userDoc['friendRequests'];

          return ListView.builder(
            itemCount: friendRequests.length,
            itemBuilder: (context, index) {
              String requesterId = friendRequests[index];

              return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(requesterId)
                      .snapshots(),
                  builder: (context, snapshot2) {
                    if (!snapshot2.hasData) return CircularProgressIndicator();
                    var userData = snapshot2.data!;
                    String requesterName = userData['name'];

                    return ListTile(
                      title: Text(requesterName),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            acceptFriendRequest(userId, requesterId),
                        child: Text('Accept'),
                      ),
                    );
                  });
            },
          );
        },
      ),
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
}
