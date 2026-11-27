import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_track/services/auth_service.dart';

class InviteFriendHelper {
  static const String _boxName = 'steptrack_auth_box';
  static const String _currentUserKey = 'current_user_json';

  static String _generateInviteToken(String seed) {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buf = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buf.write(chars[random.nextInt(chars.length)]);
    }
    final cleanSeed = seed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleanSeed.isNotEmpty
        ? cleanSeed.substring(0, min(4, cleanSeed.length))
        : 'st';
    return '${buf.toString()}$suffix';
  }

  static Future<String> getOrCreateInviteLink({
    required AuthService authService,
    FirebaseFirestore? firestore,
  }) async {
    final currentUser = authService.currentUser;
    final cached = (currentUser != null
            ? authService.getCachedUserByUid(currentUser.uid)
            : null) ??
        authService.getCachedUser();

    final uid = currentUser?.uid ?? cached?.uid ?? 'guest_user';
    final inviteKey = 'invite_link_$uid';

    String? link;
    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box(_boxName);
      final existing = box.get(inviteKey)?.toString();
      if (existing != null && existing.trim().isNotEmpty) {
        link = existing.trim();
      } else {
        final token = _generateInviteToken(uid);
        link = 'https://invite.steps.app/$token';
        await box.put(inviteKey, link);
      }

      final Map<String, dynamic> updatedUserMap = {
        ...?cached?.toMap(),
        'uid': uid,
        'name': cached?.name ?? currentUser?.displayName ?? 'StepTrack User',
        'email': cached?.email ?? currentUser?.email ?? '',
        'createdAt': cached?.createdAt.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'inviteLink': link,
      };
      await box.put(_currentUserKey, jsonEncode(updatedUserMap));
      await box.put('user_$uid', jsonEncode(updatedUserMap));
    } else {
      link = 'https://invite.steps.app/${_generateInviteToken(uid)}';
    }

    if (currentUser != null) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        await db.collection('users').doc(currentUser.uid).set({
          'inviteLink': link,
          'inviteUpdatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return link;
  }

  static Future<void> shareInviteLink({
    required AuthService authService,
    String? senderName,
    FirebaseFirestore? firestore,
  }) async {
    final inviteLink = await getOrCreateInviteLink(
      authService: authService,
      firestore: firestore,
    );

    final who = (senderName != null && senderName.trim().isNotEmpty)
        ? senderName.trim()
        : (authService.currentUser?.displayName?.trim().isNotEmpty == true
            ? authService.currentUser!.displayName!.trim()
            : 'A friend');

    final shareMessage =
        '$who invited you to join StepTrack! Walk, compete in challenges, and track steps together:\n$inviteLink';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareMessage,
          subject: 'Join me on StepTrack',
        ),
      );
    } catch (_) {
      unawaited(
        Future.value(
          Get.snackbar(
            'Invite Link',
            inviteLink,
            snackPosition: SnackPosition.BOTTOM,
          ),
        ),
      );
    }
  }
}