# Dart 编码约束

> 适用于 Flutter 3.x + Dart 3，启用空安全。

## 核心语法约束
- 禁止使用 `new` 关键字
- 禁止使用已弃用的组件：`RaisedButton` → `ElevatedButton`，`FlatButton` → `TextButton`，`OutlineButton` → `OutlinedButton`
- 禁止使用 `List()` 构造函数，改用 `[]` 或 `List.filled`
- 禁止使用 `Map()` 构造函数，改用 `{}`
- 禁止使用 `int.parse()` 不捕获异常，推荐 `int.tryParse`
- 异步操作必须使用 `async/await`，避免 `.then`
- **方法签名变更后必须同步所有调用方**：当修改公共方法参数时，应使用 IDE 的“查找引用”或运行静态分析来定位所有调用处。
- **空安全规则**：对于非空类型变量，禁止使用 `?.` 操作符；只有声明为 `可空类型?` 的变量才允许使用 `?.` 或 `!`。非空类型直接访问成员。
- **及时清理未使用的导入**：避免警告累积，保持代码整洁。

## 空安全规则
- 变量默认非空，可空类型需显式声明 `?`，例如 `String? name`
- 访问可空变量时使用 `?.` 或 `!`（确保非空）
- 使用 `late` 修饰延迟初始化的非空变量

## UI 编码规范
- 按钮：`ElevatedButton`、`TextButton`、`OutlinedButton`
- 列表：使用 `ListView.builder` 并指定 `itemCount`
- 图片：`Image.network`、`Image.asset`、`Image.file`
- 路由：`Navigator.pushNamed` / `pushReplacementNamed`
- 状态管理：使用 `Provider` 或 `setState`，避免复杂全局变量

## 导入规范
- 材料设计：`import 'package:flutter/material.dart';`
- 网络请求：使用项目中已封装的 `Dio` 单例，不直接创建 `Dio` 实例

## 示例正确代码片段
```dart
// 按钮
ElevatedButton(
  onPressed: _isLoading ? null : () => _login(),
  child: _isLoading ? CircularProgressIndicator() : Text('登录'),
)

// 异步
Future<void> fetchData() async {
  try {
    final data = await api.getUser();
    // 处理数据
  } catch (e) {
    debugPrint('错误: $e');
  }
}
```

# 前端开发关键注意事项（基于后端最新设计）
## 1. 认证方式
- **文档位置**：`short_spec.md` → 二、后端接口基础信息 → 认证方式
- **要点**：
  - 登录成功后，后端返回 `access_token`（JWT），有效期 2 小时。
  - 所有需要认证的接口（除注册、登录外）必须在请求头中携带：
    ```
    Authorization: Bearer <access_token>
    ```
  - 前端需在本地存储 `access_token`（如 `SharedPreferences` / `localStorage`），并在每次请求时自动添加到请求头。
  - Token 过期后（后端返回 401），前端应引导用户重新登录。
## 2. 基础 URL 与版本
- **文档位置**：`short_spec.md` → 二、后端接口基础信息
- **要点**：
  - 基础 URL：`http://127.0.0.1:8000/api/v1`
  - 所有接口路径以 `/api/v1` 开头，文档中仅列出相对路径（如 `/users/register`），实际请求需拼接基础 URL。
## 3. 统一响应格式
- **文档位置**：`short_spec.md` → 三、统一响应格式
- **约束**：
  - 所有响应均为 `{ "code": 200, "message": "success", "data": {...} }` 结构。
  - 成功时 `code=200`；失败时 `code` 为非 200（如 40001、40101、40301、40401、50003 等）。
  - 前端应优先判断 `code` 是否为 200，否则展示 `message` 中的错误信息。
  - HTTP 状态码与业务 `code` 的对应关系见文档中的映射表。
## 4. 分页参数
- **文档位置**：`short_spec.md` → 五、通用校验规则 以及 `api_short.md` 中的具体接口
- **要点**：
  - 分页统一使用 `skip`（偏移量）和 `limit`（每页条数）。
  - 默认值：`skip=0`, `limit=10`（部分接口默认 20）。
  - 列表响应统一为 `{ "total": int, "list": [...] }`。
## 5. 文件上传
- **文档位置**：`short_spec.md` → 五、通用校验规则（图片上传）
- **要点**：
  - 文件字段名固定为 `file`。
  - 支持格式：jpg / jpeg / png，大小 ≤ 10 MB。
  - 请求头必须使用 `multipart/form-data`。
  - 上传图片的接口（如病害识别、问诊图片）需要携带认证头。
## 6. 会话管理（问诊模块）
- **文档位置**：`api_short.md` → 问诊模块
- **要点**：
  - `POST /chat/message` 和 `POST /chat/message_with_image` 都支持 `session_id` 参数（可选）。
  - 首次对话**不传** `session_id`，后端会创建新会话并返回 `session_id`。
  - 后续对话必须携带该 `session_id`，以保持上下文连续。
  - `GET /chat/sessions` 获取当前用户的所有会话列表。
  - `GET /chat/sessions/{session_id}/messages` 获取某个会话的历史消息。
  - `DELETE /chat/sessions/{session_id}` 删除会话。
## 7. 错误码处理
- **文档位置**：`short_spec.md` → 四、错误码表
- **前端应特别处理的常见错误码**：
  - `40101`：Token 无效或过期 → 清除本地 token，跳转登录页。
  - `40301`：权限不足（普通用户访问管理员接口）→ 提示无权限。
  - `40001`：参数校验失败 → 根据 `message` 提示用户。
  - `40401`：资源不存在 → 提示用户刷新或返回。
  - `50003`：AI 服务异常 → 提示稍后重试。
## 8. 跨域（CORS）
- 后端已配置 CORS，开发环境允许所有域名，生产环境需限制。
## 9. WebSocket（当前未使用）
- 问诊模块使用 **HTTP 一次性返回**（非 WebSocket），暂无 WebSocket 接口。
## 10. 数据类型与时间格式
- 所有时间字段均为 ISO 8601 UTC 字符串（如 `2026-04-27T10:00:00Z`）。
- 整数、浮点数、布尔值按标准 JSON 解析。
