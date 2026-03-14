import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// 自定义 API 异常
class ApiException implements Exception {
  final String message;
  final int? code;

  ApiException(this.message, {this.code});

  @override
  String toString() {
    return 'ApiException: Code \$code, Message: \$message';
  }
}

/// Dio 网络请求客户端
/// 采用单例模式
class DioClient {
  DioClient._(); // 私有构造函数
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late Dio _dio;

  /// 初始化 Dio 客户端
  void init(String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // 连接超时
      receiveTimeout: const Duration(seconds: 10), // 接收超时
    ));

    // 添加拦截器
    _dio.interceptors.add(AppInterceptor());
  }

  /// 通用 GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 通用 POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 统一处理 Dio 异常
  ApiException _handleDioException(DioException error) {
    String message = '未知错误';
    int? statusCode = error.response?.statusCode;

    debugPrint('Dio 异常: \${error.type}, 状态码: \$statusCode, 错误信息: \${error.message}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时，请检查网络设置。';
        break;
      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 401:
            message = '未授权，请重新登录。';
            // TODO: 这里可以添加清除本地 token 并跳转到登录页的逻辑
            break;
          case 404:
            message = '请求的资源不存在。';
            break;
          case 500:
            message = '服务器内部错误。';
            break;
          default:
            message = '请求失败: \${statusCode ?? ''} \${error.response?.statusMessage ?? ''}';
            break;
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消。';
        break;
      case DioExceptionType.unknown:
        if (error.error is ApiException) {
          return error.error as ApiException; // 已经是自定义异常，直接返回
        }
        message = '网络错误，请稍后重试。';
        break;
      default:
        message = '请求发生未知错误。';
        break;
    }
    return ApiException(message, code: statusCode);
  }
}

/// Dio 请求拦截器
class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('请求 [\${options.method}] => PATH: \${options.path}');
    // TODO: 在这里可以添加 Token 注入、请求头配置等
    // options.headers['Authorization'] = 'Bearer your_token';
    handler.next(options); // 继续请求
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('响应 [\${response.requestOptions.method}] => PATH: \${response.requestOptions.path} STATUS: \${response.statusCode}');
    handler.next(response); // 继续响应
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('错误 [\${err.requestOptions.method}] => PATH: \${err.requestOptions.path} ERROR: \${err.message}');
    handler.next(err); // 继续错误处理
  }
}