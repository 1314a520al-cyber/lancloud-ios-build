#!/usr/bin/env python3
"""文叔叔（wenshushu.cn）接口探测脚本。

用途：验证 ap.wenshushu.cn 上哪些接口在不登录、不加密的情况下可直接调用，
为 LanCloud 的文叔叔页面决定"哪些功能能做原生、哪些只能走网页"。

结论来自 2026-11 抓取前端 app.1b8781951d.js 与 /ag/gls 配置。

已确认：
  1. 域名 ap.wenshushu.cn；GET 走 /ag 前缀，POST 走 /ap 前缀。
  2. 请求头必带：X-TOKEN、prod: com.wenshushu.web.pc。
  3. /ap/login/anonymous 可匿名换取 token（wss:xxxx）。
  4. /ag/time 返回服务端时间（DES 加密的密钥来源）。
  5. 部分接口不加密直接可用：/ap/user/userinfo。
  6. 需要登录态（token 权限不足会返回 1135 TR_TP_NOPOWER）：
       /ap/sharekey/info、/ap/sharekey/file_list、/ap/uploadv2/*。
  7. 上传/取件等 POST 接口在请求未带登录态时返回 1003 TR_PARA_ERO / 1135。

所以：文叔叔的「发送/收取」必须登录账号，且上传链路还叠了 DES-CBC 请求体加密
（key = iv = /ag/time 的 time 字符串，且加密函数 window.gp 是动态注入的独立脚本，
线上无法离线复现密钥派生）。这类能力不适合在客户端硬做，走官方页面更稳。
"""

import json
import urllib.request

BASE = "https://ap.wenshushu.cn"
PROD = "com.wenshushu.web.pc"


def call(method: str, path: str, body: dict | None = None, token: str | None = None):
    """method=GET 走 /ag，method=POST 走 /ap（与前端 axios 拦截器一致）。"""
    prefix = "/ag" if method == "GET" else "/ap"
    url = f"{BASE}{prefix}{path}"
    data = json.dumps(body or {}).encode() if method == "POST" else None
    headers = {"Content-Type": "application/json", "prod": PROD}
    if token:
        headers["X-TOKEN"] = token
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except Exception as exc:  # noqa: BLE001 - 探测脚本，失败即输出
        return {"error": str(exc)}


def main():
    # 1. 匿名登录拿 token
    anon = call("POST", "/login/anonymous", {})
    token = (anon.get("data") or {}).get("token")
    print("anonymous login:", anon)
    if not token:
        return

    # 2. 服务端时间（DES 加密的密钥来源）
    print("server time:", call("GET", "/time", token=token))

    # 3. 不加密就能用的接口
    print("userinfo:", call("POST", "/user/userinfo", {}, token))

    # 4. 需要登录态的接口（匿名 token 会被拒）
    print("sharekey/info:", call("POST", "/sharekey/info", {"key": "xxxx"}, token))
    print(
        "uploadv2/getupid:",
        call(
            "POST",
            "/uploadv2/getupid",
            {
                "preid": "",
                "boxid": "",
                "linkid": "",
                "utype": "copyfrom",
                "length": 12345,
                "count": 1,
            },
            token,
        ),
    )


if __name__ == "__main__":
    main()
