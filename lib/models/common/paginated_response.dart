/// 分页响应模型
/// 用于解析后端返回的分页数据 {total, list}
class PaginatedResponse<T> {
  final int total;
  final List<T> list;

  PaginatedResponse({
    required this.total,
    required this.list,
  });

  /// 从 JSON 解析 PaginatedResponse
  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    final listData = json['list'] as List<dynamic>;
    return PaginatedResponse<T>(
      total: json['total'] as int,
      list: listData.map((item) => fromJson(item)).toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'list': list,
    };
  }

  @override
  String toString() {
    return 'PaginatedResponse(total: $total, listLength: ${list.length})';
  }
}