
import 'package:intl/intl.dart';

/// 识别记录模型 (Identification Model)
///
/// 此模型与 FastAPI 后端 `crop.py` 中定义的 `Identification` 数据结构完全对齐。
/// 主要用于存储用户的作物识别记录，包括识别出的病害、建议等信息。
///
/// **如何与 Dio 响应解析联动：**
/// 当使用 Dio 发送请求并收到响应后，可以通过以下方式将 JSON 数据转换为 Identification 对象列表：
/// ```dart
/// final response = await DioClient.instance.get('/identifications');
/// if (response.statusCode == 200) {
///   final List<Identification> identifications = (response.data as List)
///       .map((e) => Identification.fromJson(e as Map<String, dynamic>))
///       .toList();
///   // 现在你可以使用 identifications 列表了
/// }
/// ```
class Identification {
  /// 识别记录ID
  /// 对应后端字段: `id` (Integer, primary_key)
  final int? id;

  /// 用户ID
  /// 对应后端字段: `user_id` (Integer, ForeignKey)
  final int? userId;

  /// 作物ID
  /// 对应后端字段: `crop_id` (Integer, ForeignKey)
  final int? cropId;

  /// 图像URL
  /// 对应后端字段: `image_url` (String, nullable=False)
  final String imageUrl;

  /// 病害名称
  /// 对应后端字段: `disease_name` (String, nullable=True)
  final String? diseaseName;

  /// 防治建议
  /// 对应后端字段: `advice` (Text, nullable=True)
  final String? advice;

  /// 识别置信度
  /// 对应后端字段: `confidence` (Float, nullable=True)
  final double? confidence;

  /// 持续时间 (如果适用)
  /// 对应后端字段: `duration` (Integer, nullable=True)
  final int? duration;

  /// 创建时间
  /// 对应后端字段: `create_time` (DateTime, server_default=func.now())
  final DateTime? createTime;

  Identification({
    this.id,
    this.userId,
    this.cropId,
    required this.imageUrl,
    this.diseaseName,
    this.advice,
    this.confidence,
    this.duration,
    this.createTime,
  });

  /// 从 JSON 数据创建 Identification 对象的工厂构造函数。
  factory Identification.fromJson(Map<String, dynamic> json) {
    return Identification(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      cropId: json['crop_id'] as int?,
      imageUrl: json['image_url'] as String,
      diseaseName: json['disease_name'] as String?,
      advice: json['advice'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      duration: json['duration'] as int?,
      createTime: json['create_time'] != null
          ? DateTime.parse(json['create_time'] as String)
          : null,
    );
  }

  /// 将 Identification 对象转换为 JSON 格式的方法。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'crop_id': cropId,
      'image_url': imageUrl,
      'disease_name': diseaseName,
      'advice': advice,
      'confidence': confidence,
      'duration': duration,
      'create_time': createTime?.toIso8601String(),
    };
  }

  /// 示例：格式化创建时间
  /// 这是一个“特殊处理”方法，用于将 createTime 格式化为可读的字符串。
  String get formattedCreateTime {
    if (createTime == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(createTime!);
  }

  @override
  String toString() {
    return 'Identification(id: $id, userId: $userId, cropId: $cropId, diseaseName: $diseaseName, createTime: $createTime)';
  }
}
