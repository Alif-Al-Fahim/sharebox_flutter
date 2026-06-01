import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Generate a consistent chat room ID for two users
  String getChatRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  // Create or get chat room
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String currentUserName,
    String? currentUserImage,
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
    String? toolId,
    String? toolName,
  }) async {
    final roomId = getChatRoomId(currentUserId, otherUserId);
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) {
      final chatRoom = ChatRoom(
        id: roomId,
        participantIds: [currentUserId, otherUserId],
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        participantImages: {
          currentUserId: currentUserImage,
          otherUserId: otherUserImage,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        toolId: toolId,
        toolName: toolName,
      );

      await roomRef.set(chatRoom.toMap());
    }

    return roomId;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? rentalId,
  }) async {
    final msgData = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      rentalId: rentalId,
    );

    final batch = _firestore.batch();

    // Add message to messages subcollection
    final msgRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(msgData.id);
    batch.set(msgRef, msgData.toMap());

    // Update chat room last message
    final roomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    batch.update(roomRef, {
      'lastMessage': message,
      'lastMessageTime': Timestamp.fromDate(msgData.timestamp),
      'unreadCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Stream messages in a chat room
  Stream<List<MessageModel>> streamMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  // Stream chat rooms for a user
  Stream<List<ChatRoom>> streamChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final messagesRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages');

    final unreadMessages = await messagesRef
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Reset unread count
    batch.update(
      _firestore.collection('chatRooms').doc(chatRoomId),
      {'unreadCount': 0},
    );

    await batch.commit();
  }

  // Get unread count for user
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] as String?;
        if (lastSenderId != null && lastSenderId != userId) {
          total += (data['unreadCount'] as int? ?? 0);
        }
      }
      return total;
    });
  }

  // Delete a message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
