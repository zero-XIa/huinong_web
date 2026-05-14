
import 'package:intl/intl.dart';
import '../config/app_config.dart';

/// 识别记录模型
///
/// 对应后端 FastAPI /crops/identify 接口返回的 data 字段
/// 字段名使用 snake_case 与后端对齐

class Identification {
  /// 识别记录ID
  final int? id;

  /// 用户ID
  final int? userId;

  /// 图片路径（后端存储的相对路径或完整 URL）
  final String imageUrl;

  /// 作物名称（AI 识别结果，可能为"未知作物"）
  final String? cropName;

  /// 病害名称（AI 识别结果，可能为"未知病害"）
  final String? diseaseName;

  /// 病害特征描述（Dify 工作流返回的详细特征说明）
  final String? characteristics;

  /// 识别置信度（0.0 ~ 1.0 的小数）
  final double? confidence;

  /// 持续时间
  final int? duration;

  /// 创建时间
  final DateTime? createTime;

  Identification({
    this.id,
    this.userId,
    required this.imageUrl,
    this.cropName,
    this.diseaseName,
    this.characteristics,
    this.confidence,
    this.duration,
    this.createTime,
  });

  factory Identification.fromJson(Map<String, dynamic> json) {
    return Identification(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      imageUrl: json['image_url'] as String,
      cropName: json['crop_name'] as String?,
      diseaseName: json['disease_name'] as String?,
      characteristics: json['characteristics'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      duration: json['duration'] as int?,
      createTime: json['create_time'] != null
          ? DateTime.parse(json['create_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'crop_name': cropName,
      'disease_name': diseaseName,
      'characteristics': characteristics,
      'confidence': confidence,
      'duration': duration,
      'create_time': createTime?.toIso8601String(),
    };
  }

  /// 拼接完整图片 URL（相对路径自动补全静态资源域名）
  String get fullImageUrl {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${AppConfig.staticBaseUrl}$imageUrl';
  }

  /// 格式化创建时间为 yyyy-MM-dd 用于列表展示
  String get formattedCreateTime {
    if (createTime == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd').format(createTime!);
  }

  @override
  String toString() {
    return 'Identification(id: $id, userId: $userId, diseaseName: $diseaseName, createTime: $createTime)';
  }
}
