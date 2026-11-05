# 文叔叔（wenshushu.cn）接口抓取文档
# 抓取时间：2026-11-06，已用登录账号实测全部跑通

## 基础信息
- API 域名：`https://ap.wenshushu.cn`（也可走 `https://www.wenshushu.cn/ap/` 同源）
- GET 接口前缀：`/ag`；POST 接口前缀：`/ap`
- 必带请求头：
  - `X-TOKEN: <login_token>`（登录后从 localStorage.getItem('login_token') 拿）
  - `prod: com.wenshushu.web.pc`（PC端）或 `com.wenshushu.web.mobile`（移动端）
  - `Content-Type: application/json`
- 匿名登录：`POST /ap/login/anonymous` body `{}` → 返回 `{code:0, data:{token:"wss:xxxx"}}`

## 账号信息
- `POST /ap/user/userinfo` → 返回 uid/name/bid/phone/vip 等完整信息
- `POST /ap/user/storage` → 返回存储用量

## 上传链路（完整 7 步）
### 1. 创建发送任务
`POST /ap/task/addsend`
```json
{
  "sender": "",
  "remark": "",
  "isextension": false,
  "pwd": "",
  "expire": "3",
  "recvs": ["social", "public"],
  "file_size": 27,
  "file_count": 1,
  "notSaveTo": false,
  "trafficStatus": 0,
  "task_traffic_limit": "",
  "downPreCountLimit": 0,
  "notDownload": false,
  "notPreview": false,
  "fileDisplay": 0
}
```
返回：`{tid: "任务ID", bid: "盒子ID", ufileid: "文件ID", social_token: "分享token"}`

### 2. 获取上传ID
`POST /ap/uploadv2/getupid`
```json
{
  "preid": "<上一步的 ufileid>",
  "boxid": "<上一步的 bid>",
  "linkid": "<上一步的 tid>",
  "utype": "sendcopy",
  "originUpid": "",
  "length": 27,
  "count": 1
}
```
返回：`{upId: "上传ID"}`

### 3. 秒传检查（可选）
`POST /ap/uploadv2/fast`
```json
{
  "hash": {
    "cm1": "<MD5>",
    "cs1": "<SHA1>",
    "cm": "<MD5>"
  },
  "uf": {
    "name": "文件名",
    "boxid": "<bid>",
    "preid": "<ufileid>"
  },
  "upId": "<upId>"
}
```
返回：`{status: 0, ufile: null}`（status=1 表示秒传成功，跳过实际上传）

### 4. 获取上传地址
`POST /ap/uploadv2/psurl`
```json
{
  "ispart": false,
  "fname": "文件名",
  "fsize": 27,
  "upId": "<upId>"
}
```
返回：`{url: "腾讯云COS直传URL"}`

### 5. 实际上传
`PUT <返回的 url>`，body 是文件二进制。

### 6. 完成上传
`POST /ap/uploadv2/complete`
```json
{
  "ispart": false,
  "fname": "文件名",
  "location": {
    "boxid": "<bid>",
    "preid": "<ufileid>"
  },
  "upId": "<upId>"
}
```
返回：`{fid: "文件ID", size: "27", ...}`

### 7. 生成分享链接
`POST /ap/task/copysend`
```json
{
  "tid": "<tid>",
  "bid": "<bid>",
  "ufileid": "<ufileid>"
}
```
返回：
```json
{
  "social_url": "https://www.wenshushu.cn/t/xxxx",
  "public_url": "https://c.wss.ink/f/xxxx",
  "mgr_url": "https://www.wenshushu.cn/t/xxxx",
  "social_token": "xxxx"
}
```

## 取件/下载链路
### 1. 下载签名
`POST /ap/dl/sign`
```json
{
  "ufileid": "<文件ID>",
  "type": 1
}
```
返回：
```json
{
  "url": "https://down.wss.show/xxxx?cdn_sign=...&exp=240",
  "ttCount": "0",
  "ttNeed": "0",
  "ticket": "",
  "remainRestore": 3,
  "isRisk": 0
}
```
直接 GET 这个 url 就能下载文件。

## 分片规则（来自前端 JS）
- ≤ 2MB：单片上传
- 2MB ~ 1GB：分片 2MB
- 1GB ~ 20GB：分片 6MB
- 20GB ~ 50GB：分片 10MB
- > 50GB：分片 14MB

## 关键发现
1. 上传不强制加密！实测请求体是明文 JSON，之前以为要 DES 是误判。
2. 上传链路是标准 REST：addsend → getupid → psurl → COS直传 → complete → copysend。
3. 下载直接走 dl/sign 拿直链，不需要二次加密。
4. 所有 POST 接口都不需要额外的签名头，只要 X-TOKEN 正确。
5. 匿名 token 只能查账号信息，上传/取件需要登录态。
