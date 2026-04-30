import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:huinong_web/provider/app_provider.dart';
import 'package:huinong_web/utils/secure_storage.dart';

/// 自定义 API 异常
class ApiException implements Exception {
  final String message;
  final int? code;

  ApiException(this.message, {this.code});

  @override
  String toString() {
    return 'ApiException: Code $code, Message: $message';
  }
}

/// Dio 网络请求客户端
/// 采用单例模式
class DioClient {
  DioClient._(); // 私有构造函数
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;
  late Dio _dio;
  static AppProvider? _appProvider;
  
  /// 设置 AppProvider 实例
  static void setAppProvider(AppProvider provider) {
    _appProvider = provider;
  }

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

  /// 通用 PUT 请求
  Future<T?> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    debugPrint('DioClient.put called: path=$path, data=$data');
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      debugPrint('DioClient.put success: status=${response.statusCode}');
      return response.data;
    } on DioException catch (e) {
      debugPrint('DioClient.put DioException: ${e.type}, message: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('DioClient.put unknown error: $e');
      rethrow;
    }
  }

  /// 通用 DELETE 请求
  Future<T?> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 统一处理 Dio 异常
    ApiException _handleDioException(DioException error) {
    String message = '未知错误';
    int? statusCode = error.response?.statusCode;

    debugPrint('Dio 异常: ${error.type}, 状态码: $statusCode, 错误信息: ${error.message}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时，请检查网络设置。';
        break;
      case DioExceptionType.badResponse:
        switch (statusCode) {
          case 400:
            // 尝试从响应体中获取更详细的错误信息
            final responseData = error.response?.data;
            String detailMessage = '';
            if (responseData is Map<String, dynamic>) {
              detailMessage = responseData['detail'] as String? ?? responseData['message'] as String? ?? '';
            }
            if (detailMessage.isNotEmpty) {
              message = detailMessage;
            } else {
              message = '请求参数错误，请检查输入信息。';
            }
            break;
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
            message = '请求失败，请稍后重试。';
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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    debugPrint('请求拦截器开始 [${options.method}] => PATH: ${options.path}');
    try {
      if (options.path == '/users/login') {
        final loginData = options.data;
        if (loginData is Map<String, dynamic>) {
          final safeData = Map<String, dynamic>.from(loginData);
          safeData['password'] = '******';
          debugPrint('登录请求体: $safeData');
        }
      }
      debugPrint('开始获取 token...');
      final token = await SecureStorage.instance.getToken();
      debugPrint('获取 token 完成: ${token != null ? '有 token' : '无 token'}');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('添加 Authorization header: Bearer ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('请求拦截器异常: $e');
    } finally {
      debugPrint('调用 handler.next(options)，请求继续');
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('响应 [${response.requestOptions.method}] => PATH: ${response.requestOptions.path} STATUS: ${response.statusCode}');
    
    // 解析响应结构 {code, message, data}
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as int?;
        if (code == 200) {
          // 只返回 data 字段给上层
          response.data = data['data'];
        } else {
          // 业务错误，抛出 ApiException
          final message = data['message'] as String? ?? '请求失败';
          final apiError = ApiException(message, code: code);
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: apiError,
            type: DioExceptionType.badResponse,
          ));
          return;
        }
      }
    }
    handler.next(response); // 继续响应
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('错误 [${err.requestOptions.method}] => PATH: ${err.requestOptions.path} ERROR: ${err.message}');
    
    // 处理 401 错误
    if (err.response?.statusCode == 401) {
      // 调用 AppProvider.logout() 并跳转登录页
      if (DioClient._appProvider != null) {
        DioClient._appProvider!.logout();
      }
    }
    
    handler.next(err); // 继续错误处理
  }
}
