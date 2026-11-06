import 'dart:async';

import 'package:material_ui/material_ui.dart' hide Icons;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔网页登录页（和蓝奏云一样，用 WebView 登录后自动获取 token）。
class WenshuLoginPage extends ConsumerStatefulWidget {
  const WenshuLoginPage({super.key});

  @override
  ConsumerState<WenshuLoginPage> createState() => _WenshuLoginPageState();
}

class _WenshuLoginPageState extends ConsumerState<WenshuLoginPage> {
  final String _loginUrl = 'https://www.wenshushu.cn/login';

  bool _checking = false;
  bool _done = false;
  double _progress = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文叔叔登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ),
            onProgressChanged: (controller, progress) {
              setState(() => _progress = progress / 100);
            },
            onLoadStop: (controller, url) async {
              // 页面加载完成后，检查是否登录成功
              if (_done) return;
              await _tryCapture(controller);
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress),
          if (_checking)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _tryCapture(InAppWebViewController controller) async {
    if (_checking || _done) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      // 从 Cookie 里获取 token
      final cookies = await CookieManager().getCookies(url: WebUri('https://www.wenshushu.cn'));
      String? token;
      for (final cookie in cookies) {
        if (cookie.name == 'token' || cookie.name == 'X-TOKEN') {
          token = cookie.value;
          break;
        }
      }
      // 也从 localStorage 里获取
      if (token == null) {
        final result = await controller.evaluateJavascript(source: '''
          localStorage.getItem('token') || localStorage.getItem('X-TOKEN');
        ''');
        if (result != null && result.toString().isNotEmpty) {
          token = result.toString().replaceAll('"', '');
        }
      }
      if (token != null && token.isNotEmpty) {
        // 保存 token
        await WenshuAuth.instance.init(token);
        setState(() => _done = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录成功')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _checking = false);
      }
    } catch (e) {
      setState(() {
        _error = '登录失败：$e';
        _checking = false;
      });
    }
  }
}
