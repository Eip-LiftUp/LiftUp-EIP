import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_api_service.dart';

/// Full profile of a user (GET /users/:id). Invalidate after an update.
///
/// The last profile received is kept on the device and shown when the
/// server cannot be reached.
final userProfileProvider = FutureProvider.family<UserProfileResponse, String>((ref, userId) async {
  final api = ref.watch(authApiServiceProvider);
  final key = profileCacheKey(userId);
  final prefs = await SharedPreferences.getInstance();
  try {
    final profile = await api.getUserProfile(userId);
    await prefs.setString(key, jsonEncode(profile.toJson()));
    return profile;
  } catch (_) {
    final cached = prefs.getString(key);
    if (cached == null) rethrow;
    return UserProfileResponse.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }
});

String profileCacheKey(String userId) => 'profile.$userId';
