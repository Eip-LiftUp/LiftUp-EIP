import 'package:dio/dio.dart';
import 'package:app/core/constants/app_constants.dart';

/// HTTP client configuration and instance
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          print('[API Error] ${error.type}: ${error.message}');
          if (error.response != null) {
            print('[API Error Response] ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Get the Dio instance
  Dio get client => dio;

  /// Static getter for easy access to the Dio instance
  static Dio get instance => ApiClient().client;
}
