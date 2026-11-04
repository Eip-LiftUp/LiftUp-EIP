import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/user_profile_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/utils/local_user_data.dart';

class _FlakyAuthApi extends AuthApiService {
  bool offline = false;

  @override
  Future<UserProfileResponse> getUserProfile(String userId) async {
    if (offline) throw Exception('Connection error');
    return UserProfileResponse(
      userId: userId,
      email: 'testeur@liftup.test',
      username: 'testeur',
      birthDate: DateTime(1998, 4, 12),
      heightCm: 178,
      weightKg: 74.5,
      fitnessLevel: FitnessLevel.intermediate,
      activityFrequency: ActivityFrequency.veryActive,
      injuredZones: const ['Genou'],
      onboardingCompleted: true,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 11, 1),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('deleting an account removes all of its data from the device, and only its data', () async {
    SharedPreferences.setMockInitialValues({
      for (final user in ['u1', 'u2']) ...{
        'workouts.$user': '[]',
        'sync.$user': '[]',
        'sync.$user.at': '2026-11-02T10:00:00.000',
        'reviews.$user': <String>['20261102|squat|80'],
        'program.$user': 'LiftUp|20261102|6|4',
        'profile.$user': '{}',
      },
    });

    await clearLocalUserData('u1');

    final keys = (await SharedPreferences.getInstance()).getKeys();
    expect(keys.where((k) => k.contains('u1')), isEmpty);
    expect(keys.where((k) => k.contains('u2')), hasLength(6));
  });

  test('the last profile is shown when the server cannot be reached', () async {
    final api = _FlakyAuthApi();
    final container = ProviderContainer(overrides: [authApiServiceProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final online = await container.read(userProfileProvider('u1').future);

    api.offline = true;
    container.invalidate(userProfileProvider('u1'));
    final cached = await container.read(userProfileProvider('u1').future);

    expect(cached.toJson(), online.toJson());
    expect(cached.activityFrequency, ActivityFrequency.veryActive);
  });

  test('without a saved profile, the loading error is kept', () async {
    final api = _FlakyAuthApi()..offline = true;
    final container = ProviderContainer(overrides: [authApiServiceProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    await expectLater(container.read(userProfileProvider('u1').future), throwsException);
  });
}
