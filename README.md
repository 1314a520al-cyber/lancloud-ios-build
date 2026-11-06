# LanCloud iOS

蓝奏云第三方客户端 iOS 版（自签名）。

## 项目介绍

这是 LanCloud 蓝奏云第三方 Flutter 客户端的 iOS 移植版，专为 iPhone 自签安装优化。

### 功能
- **MD 3 设计**：表现力设计、动态取色、自适应布局
- **网盘管理**：上传、下载、分享、新建文件夹、修改信息、移动、删除、搜索、排序
- **分享链接**：支持打开蓝奏云分享链接
- **多账号**：多账号支持
- **回收站**：蓝奏云回收站原生页面（列表、恢复、彻底删除、清空）
- **文叔叔**：文叔叔（wenshushu.cn）原生功能（登录、上传、取件下载）
- **固定目录**：常用网盘目录固定到首页快速访问

### 技术栈
- Flutter 3.47+
- Dart
- material_ui（MD3 设计）
- dio（网络请求）
- shared_preferences（本地存储）
- file_picker（文件选择）
- receive_sharing_intent（接收分享）

## 接口来源

| 服务 | 地址 | 说明 |
| --- | --- | --- |
| 蓝奏云 | https://pc.woozooo.com | 网盘接口、回收站接口 |
| 文叔叔 | https://ap.wenshushu.cn | 文叔叔传输接口 |

## 插件来源

| 插件 | 地址 | 说明 |
| --- | --- | --- |
| Flutter | https://flutter.dev | 跨平台框架 |
| material_ui | https://pub.dev/packages/material_ui | MD3 设计组件 |
| dio | https://pub.dev/packages/dio | 网络请求库 |
| shared_preferences | https://pub.dev/packages/shared_preferences | 本地键值存储 |
| file_picker | https://pub.dev/packages/file_picker | 文件选择器 |
| receive_sharing_intent | https://pub.dev/packages/receive_sharing_intent | 接收系统分享 |

## 参与的仓库

| 仓库 | 说明 |
| --- | --- |
| **lancloud-ios-build**（本仓库） | iOS 构建 + 发行仓库 |
| LanCloud-iOS | 旧构建仓库（已设为私密） |
| LanZouCloud-API | 蓝奏云接口协议参考 |
| lanzouyun-disk | 蓝奏云接口协议参考 |
| lanzouplus | 蓝奏云接口协议参考 |

## 下载

最新版本：[v1.0.3](https://github.com/1314a520al-cyber/lancloud-ios-build/releases/tag/v1.0.3)

下载 `LanCloud-v1.0.3.ipa`，用 AltStore / Sideloadly / TrollStore 等工具自签安装。

> 注意：本应用未经过苹果 App Store 签名，需要自行签名后才能安装。

## 更新日志

### v1.0.3
- **重要** 改成真机模式构建，IPA 可在真机自签安装
- **重要** 安装包大小从 95MB 缩小到 13MB
- **修复** 回收站删除文件后不显示
- **修复** 网盘页面切换后报错乱码
- **修复** 编辑资料时输入框被键盘遮住
- **修复** 多个编译错误（图标不存在、FilePicker 等）
- **新增** 文叔叔页面（登录、上传、取件、头像菜单）
- **新增** 蓝奏云回收站原生页面
- **新增** 固定网盘目录操作入口
- **优化** 我的页面 UI 美化
- **优化** 设置页面改成可折叠卡片
- **优化** 关于页面调整（去掉"应用"标题）
- **优化** 底栏改成两个悬浮

### v1.0.2
- 模拟器 debug 模式构建（不能在真机上正常运行）

### v1.0.0
- 第一个构建版本

## 反馈邮箱
sxewku6006@163.com

## 免责声明

> 本应用是非官方的第三方客户端，与蓝奏云、文叔叔官方无任何关联，也未获得官方授权。应用按「现状」提供，不提供任何担保；因使用本应用造成的账号受限、数据丢失、上传或下载失败等风险，由使用者自行承担。
