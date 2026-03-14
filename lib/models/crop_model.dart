


/// 作物模型 (Crop Model)
///
/// 此模型与 FastAPI 后端 `crop.py` 中定义的 `Crop` 数据结构完全对齐。
/// 它支持从 JSON 反序列化 (`fromJson`) 和序列化为 JSON (`toJson`)。
///
/// **如何与 Dio 响应解析联动：**
/// 当使用 Dio 发送请求并收到响应后，可以通过以下方式将 JSON 数据转换为 Crop 对象：
/// ```dart
/// final response = await DioClient.instance.get('/crops/{id}');
/// if (response.statusCode == 200) {
///   final Crop crop = Crop.fromJson(response.data);
///   // 现在你可以使用 crop 对象了
/// }
/// ```
class Crop {
  /// 作物ID
  /// 对应后端字段: `id` (Integer, primary_key)
  final int? id;

  /// 作物名称
  /// 对应后端字段: `crop_name` (String, nullable=False)
  final String cropName;

  /// 作物描述
  /// 对应后端字段: `description` (Text, nullable=True)
  final String? description;

  Crop({
    this.id,
    required this.cropName,
    this.description,
  });

  /// 从 JSON 数据创建 Crop 对象的工厂构造函数。
  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as int?,
      cropName: json['crop_name'] as String,
      description: json['description'] as String?,
    );
  }

  /// 将 Crop 对象转换为 JSON 格式的方法。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'Crop(id: $id, cropName: $cropName, description: $description)';
  }
}
