import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThreadModel {
  final String id;
  final String title;
  final String lastMessage;
  final String senderName;
  final int unreadCount;
  final bool isGroup;
  final DateTime? updatedAt;

  ChatThreadModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.senderName,
    this.unreadCount = 0,
    this.isGroup = false,
    this.updatedAt,
  });

  factory ChatThreadModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['updatedAt'];
    return ChatThreadModel(
      id: doc.id,
      title: (data['title'] ?? data['name'] ?? 'Fitness Chat').toString(),
      lastMessage: (data['lastMessage'] ?? 'Tap to start chatting').toString(),
      senderName: (data['senderName'] ?? 'Member').toString(),
      unreadCount: ((data['unreadCount'] ?? 0) as num).toInt(),
      isGroup: (data['isGroup'] ?? false) == true,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'lastMessage': lastMessage,
      'senderName': senderName,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return ChatMessageModel(
      id: doc.id,
      senderId: (data['senderId'] ?? 'unknown').toString(),
      senderName: (data['senderName'] ?? 'Member').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class DiscoverChallengeModel {
  final String id;
  final String title;
  final String category; // 'community' | 'personal' | 'plan'
  final String description;
  final int targetSteps;
  final int currentSteps;
  final int participantsCount;
  final bool joined;

  DiscoverChallengeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.targetSteps,
    required this.currentSteps,
    required this.participantsCount,
    this.joined = false,
  });

  double get progress =>
      targetSteps > 0 ? (currentSteps / targetSteps).clamp(0.0, 1.0) : 0.0;

  factory DiscoverChallengeModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DiscoverChallengeModel(
      id: doc.id,
      title: (data['title'] ?? 'Step Challenge').toString(),
      category: (data['category'] ?? 'community').toString(),
      description: (data['description'] ?? 'Daily walking milestone').toString(),
      targetSteps: ((data['targetSteps'] ?? 10000) as num).toInt(),
      currentSteps: ((data['currentSteps'] ?? 0) as num).toInt(),
      participantsCount: ((data['participantsCount'] ?? 1) as num).toInt(),
      joined: (data['joined'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'targetSteps': targetSteps,
      'currentSteps': currentSteps,
      'participantsCount': participantsCount,
      'joined': joined,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class DiscoverMemberModel {
  final String id;
  final String name;
  final String city;
  final int todaySteps;
  final bool isConnected;

  DiscoverMemberModel({
    required this.id,
    required this.name,
    required this.city,
    required this.todaySteps,
    this.isConnected = false,
  });

  factory DiscoverMemberModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DiscoverMemberModel(
      id: doc.id,
      name: (data['name'] ?? 'Runner').toString(),
      city: (data['city'] ?? 'Sahiwal').toString(),
      todaySteps: ((data['todaySteps'] ?? data['steps'] ?? 0) as num).toInt(),
      isConnected: (data['isConnected'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'todaySteps': todaySteps,
      'isConnected': isConnected,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
