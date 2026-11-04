import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/services/workout_api_service.dart';

/// Answers every request with a Wi-Fi login page, like a captive portal.
class _PortalAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString('<html>Connexion au Wi-Fi</html>', 200, headers: {
        Headers.contentTypeHeader: ['text/html'],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a Wi-Fi portal page is a failure to retry later, not a crash', () async {
    final api = WorkoutApiService(dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = _PortalAdapter());
    final retryable = isA<ApiRequestException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue);

    await expectLater(api.getUserWorkouts(userId: 'u1'), throwsA(retryable));
    await expectLater(
      api.createWorkout(userId: 'u1', request: CreateWorkoutRequest(name: 'Jambes')),
      throwsA(retryable),
    );
  });
}
