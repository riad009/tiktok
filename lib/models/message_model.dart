import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String messageType; // 'text', 'image', 'system'
  final String mediaUrl;
  final String mediaType; // '', 'image', 'video'
  final Map<String, String> reactions; // userId -> emoji
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.messageType = 'text',
    this.mediaUrl = '',
    this.mediaType = '',
    this.reactions = const {},
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      messageType: map['messageType'] ?? 'text',
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: map['mediaType'] ?? '',
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'reactions': reactions,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final bool isGroupChat;
  final String groupName;
  final String groupPhotoUrl;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.participantNames = const {},
    this.participantPhotos = const {},
    this.isGroupChat = false,
    this.groupName = '',
    this.groupPhotoUrl = '',
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  factory ConversationModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConversationModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos:
          Map<String, String>.from(map['participantPhotos'] ?? {}),
      isGroupChat: map['isGroupChat'] ?? false,
      groupName: map['groupName'] ?? '',
      groupPhotoUrl: map['groupPhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
    };
  }
}
