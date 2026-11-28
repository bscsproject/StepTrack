import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../model/suite_models.dart';

class SuiteRealtimeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ChallengeItem> challenges = <ChallengeItem>[].obs;
  final RxList<GroupItem> groups = <GroupItem>[].obs;
  final RxList<SuggestedMemberItem> people = <SuggestedMemberItem>[].obs;
  final RxList<ChatThreadItem> threads = <ChatThreadItem>[].obs;
  final RxList<ThreadMessageItem> messages = <ThreadMessageItem>[].obs;
  final RxList<FeedPostItem> feedPosts = <FeedPostItem>[].obs;

  final RxString activeThreadId = ''.obs;
  final RxString activeThreadTitle = 'StepTrack Community'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxBool isConnected = false.obs;
  final RxBool isSeeding = false.obs;

  StreamSubscription? _challengesSub;
  StreamSubscription? _groupsSub;
  StreamSubscription? _peopleSub;
  StreamSubscription? _threadsSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _feedSub;

  String get currentUid =>
      _auth.currentUser?.uid ?? '50g9eQsYLWZpva9tGLYMUAy2qSQ2';

  String get currentUserName =>
      _auth.currentUser?.displayName ?? 'Quratulain';

  int get totalUnread =>
      threads.fold<int>(0, (acc, item) => acc + item.unreadCount);

  List<ChallengeItem> get communityChallenges =>
      challenges.where((c) => c.category == 'community' && !c.completed).toList();

  List<ChallengeItem> get personalChallenges =>
      challenges.where((c) => c.category == 'personal' && !c.completed).toList();

  List<ChallengeItem> get fitnessPlans =>
      challenges.where((c) => c.category == 'plan').toList();

  List<ChallengeItem> get previousChallenges =>
      challenges.where((c) => c.completed || c.category == 'previous').toList();

  List<ChallengeItem> get joinedChallenges =>
      challenges.where((c) => c.joined).toList();

  List<ChallengeItem> get filteredChallenges {
    final q = searchQuery.value.trim().toLowerCase();
    return challenges.where((c) {
      final catOk =
          selectedCategory.value == 'all' || c.category == selectedCategory.value;
      final qOk = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _bindStreams();
  }

  @override
  void onClose() {
    _challengesSub?.cancel();
    _groupsSub?.cancel();
    _peopleSub?.cancel();
    _threadsSub?.cancel();
    _messagesSub?.cancel();
    _feedSub?.cancel();
    super.onClose();
  }

  void _bindStreams() {
    _challengesSub = _db
        .collection('discover_challenges')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        isConnected.value = true;
        challenges.assignAll(
          snap.docs.map((d) => ChallengeItem.fromDoc(d)).toList(),
        );
      },
      onError: (_) => isConnected.value = false,
    );

    _groupsSub = _db
        .collection('discover_groups')
        .orderBy('weeklySteps', descending: true)
        .snapshots()
        .listen((snap) {
      isConnected.value = true;
      groups.assignAll(snap.docs.map((d) => GroupItem.fromDoc(d)).toList());
    });

    _peopleSub = _db
        .collection('discover_members')
        .orderBy('todaySteps', descending: true)
        .snapshots()
        .listen((snap) {
      isConnected.value = true;
      people.assignAll(
        snap.docs.map((d) => SuggestedMemberItem.fromDoc(d)).toList(),
      );
    });

    _threadsSub = _db
        .collection('chat_threads')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snap) {
      isConnected.value = true;
      final list = snap.docs.map((d) => ChatThreadItem.fromDoc(d)).toList();
      threads.assignAll(list);
      if (activeThreadId.value.isEmpty && list.isNotEmpty) {
        openThread(list.first.id, list.first.title);
      }
    });

    _feedSub = _db
        .collection('stepsapp_feed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      isConnected.value = true;
      feedPosts.assignAll(
        snap.docs.map((d) => FeedPostItem.fromDoc(d)).toList(),
      );
    });
  }

  void openThread(String threadId, String title) {
    activeThreadId.value = threadId;
    activeThreadTitle.value = title;
    _messagesSub?.cancel();

    _messagesSub = _db
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snap) {
      messages.assignAll(
        snap.docs.map((d) => ThreadMessageItem.fromDoc(d)).toList(),
      );
    });

    _db.collection('chat_threads').doc(threadId).set(
      {'unreadCount': 0},
      SetOptions(merge: true),
    );
  }

  Future<void> sendThreadMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    var tid = activeThreadId.value;
    if (tid.isEmpty) {
      final ref = await _db.collection('chat_threads').add({
        'title': 'StepTrack Squad Room',
        'lastMessage': clean,
        'lastSender': currentUserName,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tid = ref.id;
      openThread(tid, 'StepTrack Squad Room');
    }

    final batch = _db.batch();
    final tRef = _db.collection('chat_threads').doc(tid);
    batch.set(tRef.collection('messages').doc(), {
      'senderId': currentUid,
      'senderName': currentUserName,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      tRef,
      {
        'lastMessage': clean,
        'lastSender': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> createNewThread(String title, String firstMessage) async {
    final cleanTitle = title.trim().isEmpty ? 'Step Club Chat' : title.trim();
    final cleanMsg =
        firstMessage.trim().isEmpty ? 'Hi team!' : firstMessage.trim();

    final docRef = _db.collection('chat_threads').doc();
    final batch = _db.batch();
    batch.set(docRef, {
      'title': cleanTitle,
      'lastMessage': cleanMsg,
      'lastSender': currentUserName,
      'unreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(docRef.collection('messages').doc(), {
      'senderId': currentUid,
      'senderName': currentUserName,
      'text': cleanMsg,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    openThread(docRef.id, cleanTitle);
  }

  Future<void> createChallenge({
    required String title,
    required String category,
    required String description,
    required int targetSteps,
  }) async {
    await _db.collection('discover_challenges').add({
      'title': title.trim(),
      'category': category,
      'description': description.trim(),
      'targetSteps': targetSteps,
      'currentSteps': 0,
      'participants': 1,
      'joined': true,
      'completed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleChallengeJoin(ChallengeItem item) async {
    final nextJoined = !item.joined;
    final nextParticipants =
        (item.participants + (nextJoined ? 1 : -1)).clamp(0, 999999);
    await _db.collection('discover_challenges').doc(item.id).set({
      'joined': nextJoined,
      'participants': nextParticipants,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementChallengeSteps(ChallengeItem item, int steps) async {
    await _db.collection('discover_challenges').doc(item.id).set({
      'currentSteps': FieldValue.increment(steps),
      'joined': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleGroupJoin(GroupItem group) async {
    final nextJoined = !group.isJoined;
    final nextCount =
        (group.membersCount + (nextJoined ? 1 : -1)).clamp(0, 999999);
    await _db.collection('discover_groups').doc(group.id).set({
      'isJoined': nextJoined,
      'membersCount': nextCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createGroup(String name, String city) async {
    await _db.collection('discover_groups').add({
      'name': name.trim(),
      'city': city.trim().isEmpty ? 'Sahiwal' : city.trim(),
      'membersCount': 1,
      'weeklySteps': 0,
      'isJoined': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleConnectPerson(SuggestedMemberItem person) async {
    await _db.collection('discover_members').doc(person.id).set({
      'connected': !person.connected,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> publishFeedPost(String content, int stepsSnapshot) async {
    final clean = content.trim();
    if (clean.isEmpty) return;
    await _db.collection('stepsapp_feed').add({
      'authorName': currentUserName,
      'badge': 'Live Walker',
      'content': clean,
      'stepsSnapshot': stepsSnapshot,
      'likesCount': 0,
      'likedByMe': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLikePost(FeedPostItem post) async {
    final nextLiked = !post.likedByMe;
    await _db.collection('stepsapp_feed').doc(post.id).set({
      'likedByMe': nextLiked,
      'likesCount': FieldValue.increment(nextLiked ? 1 : -1),
    }, SetOptions(merge: true));
  }

  Future<void> seedSuiteSampleData() async {
    try {
      isSeeding.value = true;
      final batch = _db.batch();

      final cCommunity =
          _db.collection('discover_challenges').doc('ch_november_sprint');
      batch.set(cCommunity, {
        'title': 'November 100K Community Walk',
        'category': 'community',
        'description': 'Collective step challenge across walkers.',
        'targetSteps': 100000,
        'currentSteps': 54200,
        'participants': 34,
        'joined': true,
        'completed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final cPersonal =
          _db.collection('discover_challenges').doc('ch_personal_10k');
      batch.set(cPersonal, {
        'title': 'Personal 10,000 Daily Steps',
        'category': 'personal',
        'description': 'Build a steady daily step streak.',
        'targetSteps': 10000,
        'currentSteps': 7250,
        'participants': 1,
        'joined': true,
        'completed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final cPlan = _db.collection('discover_challenges').doc('ch_weight_plan');
      batch.set(cPlan, {
        'title': 'Weight Loss & Cardio Step Plan',
        'category': 'plan',
        'description': 'Brisk daily step intervals for calorie burn.',
        'targetSteps': 12000,
        'currentSteps': 5600,
        'participants': 19,
        'joined': false,
        'completed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final cPrev =
          _db.collection('discover_challenges').doc('ch_october_finish');
      batch.set(cPrev, {
        'title': 'October Campus Step Milestone',
        'category': 'previous',
        'description': 'Completed 150,000 steps in October.',
        'targetSteps': 150000,
        'currentSteps': 150000,
        'participants': 22,
        'joined': true,
        'completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final g1 = _db.collection('discover_groups').doc('grp_sahiwal');
      batch.set(g1, {
        'name': 'Sahiwal Morning Striders',
        'city': 'Sahiwal',
        'membersCount': 16,
        'weeklySteps': 184500,
        'isJoined': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final p1 = _db.collection('discover_members').doc('person_ayesha');
      batch.set(p1, {
        'name': 'Ayesha Noor',
        'handle': '@ayesha_walks',
        'todaySteps': 9340,
        'connected': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final t1 = _db.collection('chat_threads').doc('thread_step_squad');
      batch.set(t1, {
        'title': 'Step Squad Chat',
        'lastMessage': 'Let us aim for 10k steps today!',
        'lastSender': 'Ayesha Noor',
        'unreadCount': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(t1.collection('messages').doc('seed_msg_1'), {
        'senderId': 'u_ayesha',
        'senderName': 'Ayesha Noor',
        'text': 'Let us aim for 10k steps today!',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final f1 = _db.collection('stepsapp_feed').doc('feed_post_1');
      batch.set(f1, {
        'authorName': 'Hamza Raza',
        'badge': '10K Club',
        'content': 'Completed a brisk 6.2 km morning walk before 8 AM.',
        'stepsSnapshot': 8120,
        'likesCount': 7,
        'likedByMe': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } finally {
      isSeeding.value = false;
    }
  }
}
