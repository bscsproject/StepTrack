import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/social_models.dart';

class SocialRealtimeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 0 = Hub, 1 = Chat Screen, 2 = Discover Screen
  final RxInt hubTabIndex = 0.obs;

  final RxList<ChatThreadModel> threads = <ChatThreadModel>[].obs;
  final RxList<ChatMessageModel> activeMessages = <ChatMessageModel>[].obs;
  final RxList<DiscoverChallengeModel> challenges =
      <DiscoverChallengeModel>[].obs;
  final RxList<DiscoverMemberModel> members = <DiscoverMemberModel>[].obs;

  final RxString activeThreadId = ''.obs;
  final RxString activeThreadTitle = ''.obs;
  final RxString selectedDiscoverFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;

  final RxBool isStreamConnected = false.obs;
  final RxBool isSeeding = false.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _threadsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _challengesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _membersSub;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String get currentUserName {
    final user = _auth.currentUser;
    if (user == null) return 'StepTrack User';
    final display = user.displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    final email = user.email?.trim() ?? '';
    return email.isNotEmpty ? email.split('@').first : 'StepTrack User';
  }

  bool _ensureAuthenticated() {
    if (_auth.currentUser != null) return true;
    Get.snackbar(
      'Sign In Required',
      'Please sign in to perform this action.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  int get totalUnreadCount =>
      threads.fold<int>(0, (sum, t) => sum + t.unreadCount);

  int get joinedChallengesCount =>
      challenges.where((c) => c.joined).length;

  int get totalChallengeSteps =>
      challenges.fold<int>(0, (sum, c) => sum + c.currentSteps);

  @override
  void onInit() {
    super.onInit();
    _bindRealtimeStreams();
  }

  @override
  void onClose() {
    _threadsSub?.cancel();
    _messagesSub?.cancel();
    _challengesSub?.cancel();
    _membersSub?.cancel();
    super.onClose();
  }

  void _bindRealtimeStreams() {
    _threadsSub = _firestore
        .collection('chat_threads')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        isStreamConnected.value = true;
        final list =
            snapshot.docs.map((doc) => ChatThreadModel.fromDoc(doc)).toList();
        threads.assignAll(list);

        if (activeThreadId.value.isEmpty && list.isNotEmpty) {
          selectThread(list.first.id, list.first.title);
        }
      },
      onError: (_) {
        isStreamConnected.value = false;
      },
    );

    _challengesSub = _firestore
        .collection('discover_challenges')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        isStreamConnected.value = true;
        challenges.assignAll(
          snapshot.docs
              .map((doc) => DiscoverChallengeModel.fromDoc(doc))
              .toList(),
        );
      },
      onError: (_) {
        isStreamConnected.value = false;
      },
    );

    _membersSub = _firestore
        .collection('discover_members')
        .orderBy('todaySteps', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        isStreamConnected.value = true;
        members.assignAll(
          snapshot.docs
              .map((doc) => DiscoverMemberModel.fromDoc(doc))
              .toList(),
        );
      },
      onError: (_) {
        isStreamConnected.value = false;
      },
    );
  }

  void selectThread(String threadId, String title) {
    activeThreadId.value = threadId;
    activeThreadTitle.value = title;
    _messagesSub?.cancel();

    _messagesSub = _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      activeMessages.assignAll(
        snapshot.docs.map((doc) => ChatMessageModel.fromDoc(doc)).toList(),
      );
    });

    _firestore.collection('chat_threads').doc(threadId).set(
      {'unreadCount': 0},
      SetOptions(merge: true),
    );
  }

  Future<void> sendMessage(String text) async {
    if (!_ensureAuthenticated()) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    String threadId = activeThreadId.value;
    if (threadId.isEmpty) {
      final created = await createThread(
        title: 'StepTrack Group Chat',
        initialMessage: clean,
        isGroup: true,
      );
      threadId = created;
    }

    final message = ChatMessageModel(
      id: '',
      senderId: currentUserId,
      senderName: currentUserName,
      text: clean,
    );

    final threadRef = _firestore.collection('chat_threads').doc(threadId);
    final batch = _firestore.batch();
    batch.set(threadRef.collection('messages').doc(), message.toMap());
    batch.set(
      threadRef,
      {
        'lastMessage': clean,
        'senderName': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<String> createThread({
    required String title,
    String initialMessage = 'Joined the step conversation!',
    bool isGroup = true,
  }) async {
    if (!_ensureAuthenticated()) return '';
    final cleanTitle = title.trim().isEmpty ? 'New Step Chat' : title.trim();
    final docRef = _firestore.collection('chat_threads').doc();
    final batch = _firestore.batch();

    batch.set(docRef, {
      'title': cleanTitle,
      'lastMessage': initialMessage,
      'senderName': currentUserName,
      'unreadCount': 0,
      'isGroup': isGroup,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(docRef.collection('messages').doc(), {
      'senderId': currentUserId,
      'senderName': currentUserName,
      'text': initialMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    selectThread(docRef.id, cleanTitle);
    return docRef.id;
  }

  Future<void> createChallenge({
    required String title,
    required String category,
    required String description,
    required int targetSteps,
  }) async {
    if (!_ensureAuthenticated()) return;
    final docRef = _firestore.collection('discover_challenges').doc();
    await docRef.set({
      'title': title.trim(),
      'category': category,
      'description': description.trim(),
      'targetSteps': targetSteps,
      'currentSteps': 0,
      'participantsCount': 1,
      'joined': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleJoinChallenge(DiscoverChallengeModel item) async {
    if (!_ensureAuthenticated()) return;
    final nextJoined = !item.joined;
    final deltaParticipants = nextJoined ? 1 : -1;
    final nextCount =
        (item.participantsCount + deltaParticipants).clamp(0, 1000000);

    await _firestore.collection('discover_challenges').doc(item.id).set({
      'joined': nextJoined,
      'participantsCount': nextCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logChallengeSteps(DiscoverChallengeModel item, int addSteps) async {
    if (!_ensureAuthenticated()) return;
    if (addSteps <= 0) return;
    await _firestore.collection('discover_challenges').doc(item.id).set({
      'currentSteps': FieldValue.increment(addSteps),
      'joined': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleConnectMember(DiscoverMemberModel member) async {
    if (!_ensureAuthenticated()) return;
    await _firestore.collection('discover_members').doc(member.id).set({
      'isConnected': !member.isConnected,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedSampleRealtimeData() async {
    try {
      isSeeding.value = true;
      final batch = _firestore.batch();

      final t1 = _firestore.collection('chat_threads').doc('morning_walkers');
      batch.set(t1, {
        'title': 'Morning Walkers Club',
        'lastMessage': 'Who is hitting 10,000 steps before noon today?',
        'senderName': 'Ayesha',
        'unreadCount': 2,
        'isGroup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(t1.collection('messages').doc('m1'), {
        'senderId': 'u_ayesha',
        'senderName': 'Ayesha',
        'text': 'Who is hitting 10,000 steps before noon today?',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final t2 = _firestore.collection('chat_threads').doc('sahiwal_runners');
      batch.set(t2, {
        'title': 'Sahiwal Step Squad',
        'lastMessage': 'Evening park walk at 5:30 PM!',
        'senderName': 'Bilal',
        'unreadCount': 1,
        'isGroup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(t2.collection('messages').doc('m2'), {
        'senderId': 'u_bilal',
        'senderName': 'Bilal',
        'text': 'Evening park walk at 5:30 PM!',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final c1 = _firestore
          .collection('discover_challenges')
          .doc('november_100k_challenge');
      batch.set(c1, {
        'title': 'November 100K Step Sprint',
        'category': 'community',
        'description': 'Reach 100,000 steps together with live daily sync.',
        'targetSteps': 100000,
        'currentSteps': 42500,
        'participantsCount': 28,
        'joined': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final c2 = _firestore
          .collection('discover_challenges')
          .doc('daily_10k_streak');
      batch.set(c2, {
        'title': 'Personal 10K Daily Habit',
        'category': 'personal',
        'description': 'Stay consistent with your daily walking target.',
        'targetSteps': 10000,
        'currentSteps': 6400,
        'participantsCount': 1,
        'joined': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final c3 = _firestore
          .collection('discover_challenges')
          .doc('weight_loss_cardio_plan');
      batch.set(c3, {
        'title': 'Active Fat-Burn Walking Plan',
        'category': 'plan',
        'description': 'Brisk daily step intervals for steady calorie burn.',
        'targetSteps': 12000,
        'currentSteps': 4800,
        'participantsCount': 14,
        'joined': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final m1 = _firestore.collection('discover_members').doc('member_zain');
      batch.set(m1, {
        'name': 'Zainab Tariq',
        'city': 'Sahiwal',
        'todaySteps': 8420,
        'isConnected': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final m2 = _firestore.collection('discover_members').doc('member_hamza');
      batch.set(m2, {
        'name': 'Hamza Raza',
        'city': 'Lahore',
        'todaySteps': 11250,
        'isConnected': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      Get.snackbar(
        'Real-Time Data Ready',
        'Sample Chat & Discover documents synced to Firestore.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal.withOpacity(0.15),
      );
    } finally {
      isSeeding.value = false;
    }
  }

  List<DiscoverChallengeModel> get filteredChallenges {
    final q = searchQuery.value.trim().toLowerCase();
    return challenges.where((c) {
      final matchesCat = selectedDiscoverFilter.value == 'all' ||
          c.category == selectedDiscoverFilter.value;
      final matchesQuery = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }

  List<DiscoverMemberModel> get filteredMembers {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return members;
    return members
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.city.toLowerCase().contains(q),
        )
        .toList();
  }
}
