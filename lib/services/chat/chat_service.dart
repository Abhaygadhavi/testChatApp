import 'package:chat_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //get all users stream
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        //go through each individual user
        final user = doc.data();
        //return user
        return user;
      }).toList();
    });
  }

  //get all users stream except blocked users
  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;

    return _firestore
        .collection("Users")
        .doc(currentUser!.uid)
        .collection("BlockedUsers")
        .snapshots()
        .asyncMap((snapshot) async {
      //get list of blocked user ids
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      //get all users
      final usersSnapshot = await _firestore.collection('Users').get();

      //return as stream list,excluding current user and blocked users
      return usersSnapshot.docs
          .where((doc) =>
              doc.data()['email'] != currentUser.email &&
              !blockedUserIds.contains(doc.id))
          .map((doc) => doc.data())
          .toList();
    });
  }

  //send messages
  Future<void> sendMessage(String receiverID, message) async {
    //get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    //crete a new mesage
    Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp);

    //construct chat room ID for the two users(sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // sort the ids(this ensure the chatroomID is the same for any 2 prople)
    String chatRoomID = ids.join('_');

    //add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  //get messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct a chatroom id for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  //report user
  Future<void> reportUser(String messageID, String userID) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy': currentUser!.uid,
      'messageID': messageID,
      'messageOwnerID': userID,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('Reports').add(report);
  }

  //block user
  Future<void> blockUser(String userID) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection("Users")
        .doc(currentUser!.uid)
        .collection("BlockedUsers")
        .doc(userID)
        .set({});
    notifyListeners();
  }

  //unblock user
  Future<void> unblockUser(String blockedUserID) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection("Users")
        .doc(currentUser!.uid)
        .collection("BlockedUsers")
        .doc(blockedUserID)
        .delete();
  }

  //get blocked users stream
  Stream<List<Map<String, dynamic>>> getBlockedUsersStrem(String userID) {
    return _firestore
        .collection("Users")
        .doc(userID)
        .collection("BlockedUsers")
        .snapshots()
        .asyncMap((snapshot) async {
      //get list of blocked user ids
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      final userDocs = await Future.wait(
        blockedUserIds
            .map((id) => _firestore.collection('Users').doc(id).get()),
      );

      //return as a list
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }
}
