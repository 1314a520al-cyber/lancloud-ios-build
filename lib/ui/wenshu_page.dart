import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../core/api/wenshu_auth.dart';
import 'wenshu_login_page.dart';
import 'wenshu_upload_page.dart';
import 'wenshu_receive_page.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔（wenshushu.cn）传输页。
class WenshuPage extends riverpod.ConsumerStatefulWidget {
  const WenshuPage({super.key, this.tabIndex = 0});

  final int tabIndex;

  @override
  riverpod.ConsumerState<WenshuPage> createState() => _WenshuPageState();
}

class _WenshuPageState extends riverpod.ConsumerState<WenshuPage> {
  bool _isLoggedIn = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await WenshuAuth.instance.init();
    setState(() {
      _isLoggedIn = WenshuAuth.instance.isLoggedIn;
      _userName = WenshuAuth.instance.userName ?? '';
    });
  }

  Future<void> _showAccountMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(_isLoggedIn ? _userName : '未登录'),
            ),
            const Divider(),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('退出登录'),
                onTap: () => Navigator.of(context).pop('logout'),
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('登录'),
                onTap: () => Navigator.of(context).pop('login'),
              ),
          ],
        ),
      ),
    );

    if (result == 'login' && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WenshuLoginPage()),
      );
    } else if (result == 'logout' && mounted) {
      await WenshuAuth.instance.logout();
      await _checkLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wenshuTitle),
        actions: [
          // 右上角圆形头像
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showAccountMenu,
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  _userName.isNotEmpty ? _userName.substring(0, 1) : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              l10n.wenshuDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // 上传卡片
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_upload, size: 32),
                title: const Text('上传文件'),
                subtitle: const Text('从其他软件选择文件上传'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuUploadPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 取件卡片
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_download, size: 32),
                title: const Text('取件下载'),
                subtitle: const Text('输入取件码下载文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuReceivePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
