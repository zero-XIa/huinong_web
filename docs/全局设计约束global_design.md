本文件定义慧农 App 前端开发的全局强制性约束。每个模块的详细设计文档必须基于本文件，不得违背其中任何条款。
---
## 1. 技术栈与基础环境
| 项目 | 技术选型 | 版本/要求 |
|------|----------|-----------|
| 跨平台框架 | Flutter | 3.24+ |
| 语言 | Dart | 3.x，启用空安全 |
| 状态管理 | Provider | 配合 ChangeNotifier |
| 网络请求 | Dio | 5.0+，单例模式 |
| 本地安全存储 | flutter_secure_storage | 所有 token 及敏感信息 |
| 图片选择 | image_picker | 拍照/相册 |
| 图片压缩（可选） | flutter_image_compress | 上传前压缩 ≤10MB |
| HTML 渲染（资讯正文） | flutter_html | 仅当后端返回 HTML |
**禁止**：  
- 直接使用 `SharedPreferences` 存储 token  
- 在 `build` 方法中发起任何网络请求  
- 使用已废弃的按钮组件（`RaisedButton` 等）
---
## 2. 项目目录结构（强制）
```text
lib/  
├── api/ # Dio 单例 + 各模块 API 类  
│ ├── dio_client.dart # 单例，拦截器配置  
│ ├── user_api.dart  
│ ├── news_api.dart  
│ ├── identify_api.dart  
│ └── chat_api.dart  
├── models/ # 数据模型（fromJson/toJson）  
│ ├── user_model.dart  
│ ├── news_model.dart  
│ ├── identification_model.dart  
│ ├── chat_model.dart  
│ └── common/ # 分页响应、统一响应等  
│ └── paginated_response.dart  
├── provider/ # 全局/页面 Provider  
│ ├── app_provider.dart # 用户信息、适老化模式、退出登录  
│ ├── chat_provider.dart # 问诊模块状态  
│ └── identify_provider.dart # 识别模块状态  
├── pages/ # 页面 Widget  
│ ├── login/  
│ ├── register/  
│ ├── home/  
│ ├── news_detail/  
│ ├── identify/  
│ ├── identify_history/  
│ ├── chat/  
│ ├── sessions/  
│ └── profile/  
├── widgets/ # 全局复用组件  
│ ├── loading_indicator.dart  
│ ├── empty_view.dart  
│ ├── error_view.dart  
│ └── elder_scaffold.dart # 可选，自动注入适老化监听  
├── utils/ # 工具类  
│ ├── app_routes.dart # 路由常量  
│ ├── app_theme.dart # 双主题定义  
│ ├── error_handler.dart # 错误码映射  
│ ├── date_formatter.dart # UTC -> 本地显示  
│ └── validators.dart # 表单校验  
└── main.dart # 入口，配置 MultiProvider
```

---
## 3. 主题与适老化规范
### 3.1 两套主题强制定义
在 `lib/utils/app_theme.dart` 中必须提供两个 `ThemeData`：
- **默认主题**  
  - 主色：`#2E7D32`  
  - 背景色：`#FFFFFF`  
  - 表面色（卡片）：`#F8F9FA`  
  - 正文：`#212121`，副文本：`#757575`  
  - 标题：18sp，正文：14sp，按钮：14sp
- **适老主题**  
  - 主色不变  
  - 背景色：`#F5F5DC`  
  - 表面色：`#FFF8E7`  
  - 文字：`#333333`（主要），`#555555`（次要）  
  - 标题：≥20sp，正文：≥18sp，按钮文字：≥19sp  
  - 按钮 `minimumSize`：高度 ≥50，圆角 12  
  - 输入框内边距垂直 ≥12
### 3.2 主题切换机制
- `AppProvider` 必须暴露 `elderMode`（bool），并在 `updateElderMode(bool)` 中调用后端 `PUT /users/me` 更新 `elder_mode` 字段。  
- `main.dart` 中的 `MaterialApp` 必须使用 `Consumer<AppProvider>` 包裹，动态返回 `theme`。  
- 所有自定义 `TextStyle` 不应写死字号，而应使用 `Theme.of(context).textTheme` 的变体，或通过 `elderMode` 条件赋值。  
- 禁止使用 `MediaQuery.textScaleFactor` 进行全局缩放，必须按上述字体表显式控制。
---
## 4. 网络层强制规范
### 4.1 Dio 单例配置
- `baseURL` 固定为 `http://127.0.0.1:8000/api/v1`  
- 超时时间：连接 10s，接收 30s  
- 必须添加以下拦截器：
```dart
// 请求拦截器：添加 Authorization 头
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
// 响应拦截器：统一解析 { code, message, data }
if (statusCode == 200) {
  final Map<String, dynamic> body = data;
  if (body['code'] == 200) {
    return body['data'];
  } else {
    throw ApiException(code: body['code'], message: body['message']);
  }
}
```
- 全局 401 处理：在响应拦截器中捕获 401 状态或业务码 40101，调用 `AppProvider.logout()` 并跳转登录页。
### 4.2 统一响应解析（强制）

所有接口返回的原始 JSON 结构均为：
```json
{ "code": 200, "message": "success", "data": { ... } }
```
Dio 响应拦截器**只返回 `data` 字段的内容**给上层调用方。上层（API 类）收到的是已经剥离后的对象。

### 4.3 错误码映射表

必须在 `lib/utils/error_handler.dart` 中定义映射函数，将业务码转为用户友好文案：

|业务码|用户提示|
|---|---|
|40101|登录已过期，请重新登录|
|40301|权限不足|
|40001|输入信息有误：{具体原因}|
|40401|内容不存在，请刷新|
|50003|AI 服务异常，请稍后重试|
|其他|网络错误，请检查连接|

### 4.4 Token 安全存储

- 使用 `flutter_secure_storage` 存储 `access_token` 及用户基本信息（`userId`, `role`, `elder_mode`）。
- 登录成功后立即写入。
- 退出登录时立即删除。
- 禁止在日志中打印 token。

---
## 5. 状态管理规范

### 5.1 全局 AppProvider（必须实现）
```dart
class AppProvider extends ChangeNotifier {
  User? _currentUser;
  bool _elderMode = false;

  User? get currentUser => _currentUser;
  bool get elderMode => _elderMode;
  bool get isLoggedIn => _currentUser != null;

  Future<void> login(User user, String token) async { ... }
  Future<void> logout() async { ... }
  Future<void> updateElderMode(bool value) async { ... }
  Future<void> updateUser(User updatedUser) async { ... }
}
```
- `_elderMode` 必须与 `_currentUser.elder_mode` 始终保持一致。
- 每次更新 `elder_mode` 后调用 `notifyListeners()`，触发全局主题重建。
### 5.2 页面级 Provider

对于复杂模块（问诊、识别），应创建独立的 `ChangeNotifier` 子类，例如 `ChatProvider` 管理当前会话的消息列表、发送状态等。这些 Provider 的作用域限定在对应页面或其父级 `MultiProvider` 中。

## 6. 路由与页面跳转规范

### 6.1 路由常量（`lib/utils/app_routes.dart`）
```dart
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String newsDetail = '/news/detail';
  static const String identify = '/identify';
  static const String identifyHistory = '/identify/history';
  static const String chat = '/chat';
  static const String chatSessions = '/chat/sessions';
  static const String profile = '/profile';
}
```
### 6.2 命名路由注册

在 `main.dart` 的 `MaterialApp` 中配置 `routes` 或使用 `onGenerateRoute`。所有页面跳转必须使用 `Navigator.pushNamed(context, routeName, arguments: args)`，禁止直接 `Navigator.push` 使用 `MaterialPageRoute`（便于统一拦截）。

### 6.3 参数传递

- 传递参数时使用 `arguments`，目标页面在 `build` 方法中通过 `ModalRoute.of(context)!.settings.arguments` 提取。
- 复杂参数应定义专用类（如 `ChatPageArguments`）。
## 7. 通用组件定义

以下组件必须在 `lib/widgets/` 中实现，并支持适老化（通过 `Consumer<AppProvider>` 或从 `Theme` 获取字号）：

| 组件名                 | 用途            | 适老化要求       |
| ------------------- | ------------- | ----------- |
| `LoadingIndicator`  | 全屏/局部加载       | 进度圈尺寸 40→48 |
| `EmptyView`         | 列表无数据         | 提示文字 ≥18sp  |
| `ErrorView`         | 加载失败，带重试按钮    | 按钮高度 50     |
| `ElderScaffold`（可选） | 自动监听适老化的脚手架包装 | -           |

---

## 8. 分页与列表加载规范

- 所有列表接口统一使用 `skip` 和 `limit` 参数，默认值分别为 0 和 10（问诊会话列表默认 20）。
- 响应格式固定为 `{ "total": int, "list": [...] }`。
- 前端维护：
    - `items = <T>[]`
    - `skip` 当前偏移量
    - `hasMore = true`
    - `isLoading = false`
- 下拉刷新：重置 `skip=0`，清空 `items`，重载第一页。
- 上拉加载更多：`skip += items.length`，仅当 `hasMore && !isLoading` 时发起请求。
- 列表构建必须使用 `ListView.builder`，指定 `itemCount`。
## 9. 文件上传规范

- 所有上传接口字段名必须为 `file`，使用 `multipart/form-data`。
- 前端必须校验：图片格式 jpg/png，大小 ≤10MB。
- 推荐压缩：超过 2MB 时可调用 `flutter_image_compress`。
- 上传时必须传递 `CancelToken`，允许用户在加载时取消。
- 上传进度（可选）可通过 `onSendProgress` 回调显示。

---

## 10. 日期与时间处理

- 后端所有时间字段均为 ISO 8601 UTC 字符串（例如 `2026-04-27T10:00:00Z`）。
- 前端必须使用 `DateTime.parse()` 解析为 `DateTime` 对象。
- 显示时需转换为本地时区并格式化：比如 `yyyy-MM-dd HH:mm`。
- 提供统一工具函数 `formatDateTime(DateTime utcTime)`。

---

## 11. 表单校验规则（全局）

|字段|规则|错误提示|
|---|---|---|
|用户名|3-50 字母/数字/下划线|请输入3-50位字母、数字或下划线|
|密码|8-20 位，必须同时包含字母和数字|密码需8-20位，包含字母和数字|
|确认密码|与密码一致|两次输入密码不一致|
|手机号（可选）|11 位数字，以 1 开头|请输入正确的手机号|

前端校验必须在提交前执行，避免无效请求。

---

## 12. 空安全与 Dart 编码约束

- 变量默认非空，可空类型显式声明 `?`。
- 使用 `?.` 安全访问，避免空指针。
- 禁止使用 `new`、`List()`、`Map()` 构造函数。
- 异步一律使用 `async/await`，避免 `.then`。
- 使用 `int.tryParse` 而非 `int.parse`（除非明确保证不会异常）。
- 所有 `build` 方法不得包含网络请求、文件操作等副作用。

---

## 13. 错误处理与用户体验规范

- 所有 `Future` 调用必须 `try-catch`，捕获异常后：
    1. 调用 `ErrorHandler.getUserFriendlyMessage(error)` 获取提示文本。
    2. 使用 `ScaffoldMessenger.showSnackBar` 显示提示（适老模式下 SnackBar 内字体 ≥18sp）。
    3. 如果是 401，调用 `AppProvider.logout` 并跳转。
- 列表加载失败时，应在列表位置显示 `ErrorView`，并提供“重试”按钮。
- 所有按钮在异步操作期间必须禁用（`onPressed = isLoading ? null : ...`）。

---

## 14. 开发顺序与集成检查点

基于本约束文档，后续模块设计文档必须覆盖以下检查点：

- 所有页面均已继承或手动监听适老化主题
- 所有 API 调用都经过 Dio 单例且认证头自动注入
- 所有错误都使用统一错误处理器
- 所有列表均实现分页、下拉刷新、上拉加载、空状态
- 所有表单均做前端校验
- 所有 token 操作均使用 `flutter_secure_storage`

---

**附录：与模块设计文档的关系**

本文件为**顶层约束**。每个模块（如问诊、识别、资讯）的详细设计文档必须显式声明“遵守全局设计约束”，并仅描述该模块特有的页面布局、交互流程图、API 调用顺序以及页面间跳转逻辑。模块文档中不得重复全局约束中的基础设施规范（如主题定义、Dio 封装方式等），但可以引用具体章节编号。