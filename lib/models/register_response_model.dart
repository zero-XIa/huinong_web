import 'package:huinong_web/models/user_model.dart';

/// 注册接口响应模型
class RegisterResponseModel {
  final int code;
  final String message;
  final User? data;

  RegisterResponseModel({
    required this.code,
    required this.message,
    this.data,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null ? User.fromJson(json['data']) : null,
    );
  }
}
