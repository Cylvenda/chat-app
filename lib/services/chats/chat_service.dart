import 'package:chatting_app/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  // get instance of firebase store & current user
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get user stream

  /*

  List<Map<String, dynamic>
  [
  {
  'email': test@gmail.com,
  'id': ...
  }
    {
  'email': test2@gmail.com,
  'id': ...
  }
  ]

  */

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each indidual user
        final user = doc.data();

        //return user
        return user;
      }).toList();
    });
  }

  // stream of user IDs the current user has already chatted with
  Stream<Set<String>> getChattedUserIdsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(<String>{});
    }

    return _firestore.collection("chat_rooms").snapshots().map((snapshot) {
      final chattedUserIds = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final dynamic rawParticipants = data["participants"];
        final participants = rawParticipants is List
            ? rawParticipants.whereType<String>().toList()
            : <String>[];

        final hasCurrentUser = participants.contains(currentUser.uid) ||
            doc.id.split('_').contains(currentUser.uid);

        if (!hasCurrentUser) continue;

        if (participants.isNotEmpty) {
          for (final participantId in participants) {
            if (participantId != currentUser.uid) {
              chattedUserIds.add(participantId);
            }
          }
          continue;
        }

        // fallback for older rooms keyed as "uidA_uidB"
        for (final idPart in doc.id.split('_')) {
          if (idPart != currentUser.uid) {
            chattedUserIds.add(idPart);
          }
        }
      }

      return chattedUserIds;
    });
  }

  String _buildChatRoomId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }

  Stream<Map<String, int>> getUnreadCountsByUserIdStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(<String, int>{});
    }

    return _firestore.collection("chat_rooms").snapshots().map((snapshot) {
      final unreadByUserId = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dynamic rawParticipants = data["participants"];
        final participants = rawParticipants is List
            ? rawParticipants.whereType<String>().toList()
            : <String>[];

        final hasCurrentUser = participants.contains(currentUser.uid) ||
            doc.id.split('_').contains(currentUser.uid);

        if (!hasCurrentUser) continue;

        String? otherUserId;
        if (participants.isNotEmpty) {
          for (final participantId in participants) {
            if (participantId != currentUser.uid) {
              otherUserId = participantId;
              break;
            }
          }
        } else {
          for (final idPart in doc.id.split('_')) {
            if (idPart != currentUser.uid) {
              otherUserId = idPart;
              break;
            }
          }
        }

        if (otherUserId == null || otherUserId.isEmpty) continue;

        final unreadCounts = data["unreadCounts"];
        int count = 0;
        if (unreadCounts is Map<String, dynamic>) {
          final rawCount = unreadCounts[currentUser.uid];
          if (rawCount is int) {
            count = rawCount;
          } else if (rawCount is num) {
            count = rawCount.toInt();
          }
        }

        unreadByUserId[otherUserId] = count;
      }

      return unreadByUserId;
    });
  }

  // send message
  Future<void> sendMessage(String receiverID, String message) async {
    // get current user
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    final ids = [currentUserID, receiverID]..sort();
    final chatRoomID = _buildChatRoomId(currentUserID, receiverID);

    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      "participants": ids,
      "lastMessage": message,
      "lastMessageTimestamp": timestamp,
      "lastSenderID": currentUserID,
      "lastSenderEmail": currentUserEmail,
      "unreadCounts.$receiverID": FieldValue.increment(1),
      "unreadCounts.$currentUserID": 0,
    }, SetOptions(merge: true));

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Future<void> markChatAsRead(String otherUserID) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatRoomID = _buildChatRoomId(currentUser.uid, otherUserID);
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      "unreadCounts.${currentUser.uid}": 0,
    }, SetOptions(merge: true));
  }

  // get message
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    final chatRoomID = _buildChatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
