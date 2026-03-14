# 慧农 Web (huinong_web)

一个基于 Flutter 和大语言模型 (LLM) 开发的智慧农业服务平台客户端。

## 项目简介

本项目旨在为农业生产者提供由大语言模型 (LLM) 驱动的智能化移动解决方案。核心功能如作物识别和专家咨询，都通过先进的 LLM 技术实现，为用户提供快速、智能的农业生产辅助。

## 主要功能

- **用户模块**: 支持用户登录、注册和个人信息管理。
- **智能作物识别**: 用户可以上传作物图片，通过后端集成的大语言模型进行智能识别，分析作物病虫害或生长状况。
- **LLM 专家问答**: 提供一个由大语言模型驱动的智能问答平台，用户可以随时就农业生产问题进行提问，并获得即时、专业的解答。

## 技术栈

- **框架**: [Flutter](https://flutter.dev/)
- **核心智能**: 大语言模型 (Large Language Model, LLM)
- **状态管理**: [Provider](https://pub.dev/packages/provider)
- **网络请求**: [Dio](https://pub.dev/packages/dio)

## 如何开始

### 环境要求

- 确保您已经安装并配置好了 [Flutter SDK](https://docs.flutter.dev/get-started/install)。

### 运行步骤

1.  **克隆项目**
    ```bash
    git clone <your-repository-url>
    cd huinong_web
    ```

2.  **安装依赖**
    ```bash
    flutter pub get
    ```

3.  **配置后端服务**
    本项目需要连接到集成了大语言模型的后端服务器才能正常工作。请确保后端服务正在运行，并且客户端可以访问到。

    根据项目文档，后端基础 URL 为：
    `http://127.0.0.1:8000/api/v1`

    请在 `lib/api/dio_client.dart` (或相关网络配置文件) 中检查并确认 baseURL 配置正确。

4.  **运行应用**
    ```bash
    flutter run
    ```

## 项目结构

```
huinong_web/
├── lib/
│   ├── api/         # 存放与后端接口交互的 API 文件
│   ├── models/      # 数据模型
│   ├── pages/       # 应用的主要页面
│   ├── provider/    # Provider 状态管理
│   └── main.dart    # 应用入口
├── pubspec.yaml     # 项目依赖和配置文件
└── README.md        # 项目说明
```
