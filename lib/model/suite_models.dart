import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeItem {
  final String id;
  final String title;
  final String category; // community | personal | plan | previous
  final String description;
  final int targetSteps;
  final int currentSteps;
  final int participants;
  final bool joined;
  final bool completed;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.targetSteps,
    required this.currentSteps,
    required this.participants,
    this.joined = false,
    this.completed = false,
  });

  double get progress =>
      targetSteps > 0 ? (currentSteps / targetSteps).clamp(0.0, 1.0) : 0.0;

  factory ChallengeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChallengeItem(
      id: doc.id,
      title: (d['title'] ?? 'Step Challenge').toString(),
      category: (d['category'] ?? 'community').toString(),
      description: (d['description'] ?? 'Daily walking milestone').toString(),
      targetSteps: ((d['targetSteps'] ?? 10000) as num).toInt(),
      currentSteps: ((d['currentSteps'] ?? 0) as num).toInt(),
      participants: ((d['participants'] ?? 1) as num).toInt(),
      joined: (d['joined'] ?? false) == true,
      completed: (d['completed'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'description': description,
        'targetSteps': targetSteps,
        'currentSteps': currentSteps,
        'participants': participants,
        'joined': joined,
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class GroupItem {
  final String id;
  final String name;
  final String city;
  final int membersCount;
  final int weeklySteps;
  final bool isJoined;

  GroupItem({
    required this.id,
    required this.name,
    required this.city,
    required this.membersCount,
    required this.weeklySteps,
    this.isJoined = false,
  });

  factory GroupItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GroupItem(
      id: doc.id,
      name: (d['name'] ?? 'Walking Group').toString(),
      city: (d['city'] ?? 'Sahiwal').toString(),
      membersCount: ((d['membersCount'] ?? 1) as num).toInt(),
      weeklySteps: ((d['weeklySteps'] ?? 0) as num).toInt(),
      isJoined: (d['isJoined'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'membersCount': membersCount,
        'weeklySteps': weeklySteps,
        'isJoined': isJoined,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class SuggestedMemberItem {
  final String id;
  final String name;
  final String handle;
  final int todaySteps;
  final bool connected;

  SuggestedMemberItem({
    required this.id,
    required this.name,
    required this.handle,
    required this.todaySteps,
    this.connected = false,
  });

  factory SuggestedMemberItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SuggestedMemberItem(
      id: doc.id,
      name: (d['name'] ?? 'Walker').toString(),
      handle: (d['handle'] ?? '@walker').toString(),
      todaySteps: ((d['todaySteps'] ?? 0) as num).toInt(),
      connected: (d['connected'] ?? false) == true,
    );
  }
}

class ChatThreadItem {
  final String id;
  final String title;
  final String lastMessage;
  final String lastSender;
  final int unreadCount;
  final DateTime? updatedAt;

  ChatThreadItem({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastSender,
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory ChatThreadItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['updatedAt'];
    return ChatThreadItem(
      id: doc.id,
      title: (d['title'] ?? 'Chat Room').toString(),
      lastMessage: (d['lastMessage'] ?? 'Start chatting').toString(),
      lastSender: (d['lastSender'] ?? 'Member').toString(),
      unreadCount: ((d['unreadCount'] ?? 0) as num).toInt(),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class ThreadMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  ThreadMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory ThreadMessageItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return ThreadMessageItem(
      id: doc.id,
      senderId: (d['senderId'] ?? 'anon').toString(),
      senderName: (d['senderName'] ?? 'Member').toString(),
      text: (d['text'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class FeedPostItem {
  final String id;
  final String authorName;
  final String badge;
  final String content;
  final int stepsSnapshot;
  final int likesCount;
  final bool likedByMe;
  final DateTime? createdAt;

  FeedPostItem({
    required this.id,
    required this.authorName,
    required this.badge,
    required this.content,
    required this.stepsSnapshot,
    this.likesCount = 0,
    this.likedByMe = false,
    this.createdAt,
  });

  factory FeedPostItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return FeedPostItem(
      id: doc.id,
      authorName: (d['authorName'] ?? 'StepTrack Member').toString(),
      badge: (d['badge'] ?? 'Daily Walker').toString(),
      content: (d['content'] ?? '').toString(),
      stepsSnapshot: ((d['stepsSnapshot'] ?? 0) as num).toInt(),
      likesCount: ((d['likesCount'] ?? 0) as num).toInt(),
      likedByMe: (d['likedByMe'] ?? false) == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
