import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_api_service.dart';

/// Full profile of a user (GET /users/:id). Invalidate after an update.
final userProfileProvider = FutureProvider.family<UserProfileResponse, String>((ref, userId) {
  return ref.watch(authApiServiceProvider).getUserProfile(userId);
});
