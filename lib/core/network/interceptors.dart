import 'package:auth_app/domain/repository/auth.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/data/source/token_manager.dart';

/// This interceptor is used to show request and response logs
class LoggerInterceptor extends Interceptor {
  Logger logger = Logger(printer: PrettyPrinter(methodCount: 0, colors: true,printEmojis: true));

  @override
  void onError( DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final requestPath = '${options.baseUrl}${options.path}';
    logger.e('${options.method} request ==> $requestPath'); //Error log
    logger.d('Error type: ${err.error} \n '
        'Error message: ${err.message}'); //Debug log
    handler.next(err); //Continue with the Error
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestPath = '${options.baseUrl}${options.path}';
    logger.i('${options.method} request ==> $requestPath'); //Info log
    handler.next(options); // continue with the Request
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('STATUSCODE: ${response.statusCode} \n '
        'STATUSMESSAGE: ${response.statusMessage} \n'
        'HEADERS: ${response.headers} \n'
        'Data: ${response.data}'); // Debug log
    handler.next(response); // continue with the Response
  }
}

/// Interceptor that refreshes access token on 401 and retries the request.
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;

  // Ensure only one refresh is in-flight; others await the same future.
  static Future<bool>? _refreshing;

  TokenRefreshInterceptor(this._dio);

  bool _isRefreshRequest(RequestOptions options) {
    // Protect against loops: don't try to refresh when calling the refresh endpoint itself
    final path = options.path;
    return path == ApiUrls.refreshToken || path.endsWith(ApiUrls.refreshToken);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final req = err.requestOptions;

    if (response?.statusCode != 401 || _isRefreshRequest(req) == true) {
      handler.next(err);
      return;
    }

    // Avoid infinite retry loops
    if (req.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    // Kick off or await the shared refresh
    _refreshing ??= TokenManager().refreshToken();
    final success = await _refreshing!;
    // Reset the future so subsequent 401s can trigger new refreshes later
    _refreshing = null;

    if (!success) {
      // Propagate original error; caller can handle logout
      sl<AuthRepository>().logout();
      handler.next(err);
      return;
    }

    try {
      // Read the new token
      final prefs = await SharedPreferences.getInstance();
      final newToken = prefs.getString('accessToken');

      // Clone request & mark as retried
      final Options retryOptions = Options(
        method: req.method,
        headers: {
          ...req.headers,
          if (newToken != null && newToken.isNotEmpty)
            'Authorization': 'Bearer $newToken',
        },
        responseType: req.responseType,
        contentType: req.contentType,
        followRedirects: req.followRedirects,
        validateStatus: req.validateStatus,
        receiveDataWhenStatusError: req.receiveDataWhenStatusError,
        sendTimeout: req.sendTimeout,
        receiveTimeout: req.receiveTimeout,
        extra: {
          ...req.extra,
          'retried': true,
        },
      );

      final Response retryResponse = await _dio.request(
        req.path,
        data: req.data,
        queryParameters: req.queryParameters,
        options: retryOptions,
        cancelToken: req.cancelToken,
        onReceiveProgress: req.onReceiveProgress,
        onSendProgress: req.onSendProgress,
      );

      handler.resolve(retryResponse);
    } catch (e) {
      handler.next(err);
    }
  }
}