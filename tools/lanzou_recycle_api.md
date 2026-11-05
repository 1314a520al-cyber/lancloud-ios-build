# 蓝奏云回收站接口抓取文档
# 抓取时间：2026-11-06，已用真实 cookie 实测

## 基础信息
- 域名：`https://pc.woozooo.com`
- 认证方式：Cookie（ylogin / ylogins / lanzou_ifo / phpdisk_info / PHPSESSID / uag）
- 回收站是纯 HTML 页面，不是 JSON API，需要解析 HTML 提取文件列表。

## 回收站接口
### 1. 回收站文件列表
`GET mydisk.php?item=recycle&action=files`
- 返回 HTML 页面，包含所有回收站文件
- 每个文件有：file_id、文件名、大小、删除时间、恢复按钮、删除按钮

### 2. 恢复单个文件
`GET mydisk.php?item=recycle&action=file_restore&file_id=xxx`
- 直接 GET 即可恢复，返回操作结果页面

### 3. 彻底删除单个文件
`GET mydisk.php?item=recycle&action=file_delete_complete&file_id=xxx`
- 直接 GET 即可彻底删除（不可恢复）

### 4. 清空回收站
`GET mydisk.php?item=recycle&action=delete_all`
- 直接 GET 即可清空所有回收站文件

## 实测文件数
当前账号回收站有 15 个文件，file_id 从 245929251 到 246428872。

## 注意事项
1. 回收站接口是 GET 请求，不是 POST。
2. 不需要额外的 CSRF token，直接带 cookie 即可。
3. 列表是 HTML 格式，需要解析 table 提取文件信息。
4. 恢复和删除操作后会跳转到操作结果页，需要判断是否成功。
