import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatRoom> _chatRooms = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentChatRoomId;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentChatRoomId => _currentChatRoomId;

  // Load chat rooms for a user
  void loadChatRooms(String userId) {
    _chatService.streamChatRooms(userId).listen((rooms) {
      _chatRooms = rooms;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load chats.';
      notifyListeners();
    });
  }

  // Load messages in a chat room
  void loadMessages(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _chatService.streamMessages(chatRoomId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load messages.';
      notifyListeners();
    });
  }

  // Create or get a chat room and return its ID
  Future<String?> createOrGetChatRoom({
    required String currentUserId,
    required String currentUserName,
    String? currentUserImage,
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
    String? toolId,
    String? toolName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final roomId = await _chatService.createOrGetChatRoom(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserImage: currentUserImage,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserImage: otherUserImage,
        toolId: toolId,
        toolName: toolName,
      );
      return roomId;
    } catch (e) {
      _error = 'Failed to open chat.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? rentalId,
  }) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        type: type,
        imageUrl: imageUrl,
        rentalId: rentalId,
      );
      return true;
    } catch (e) {
      _error = 'Failed to send message.';
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatRoomId, userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Get unread count stream
  Stream<int> getUnreadCount(String userId) {
    return _chatService.streamUnreadCount(userId);
  }

  // Clear current messages when leaving chat
  void clearMessages() {
    _messages = [];
    _currentChatRoomId = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
