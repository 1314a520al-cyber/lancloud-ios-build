import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import 'wenshu_login_page.dart';
import 'wenshu_upload_page.dart';
import 'wenshu_receive_page.dart';
import 'wenshu_task_list_page.dart';
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
  String _uid = '';
  int _totalSpace = 0;
  int _usedSpace = 0;

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
      _uid = WenshuAuth.instance.uid ?? '';
    });
    if (_isLoggedIn) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final client = WenshuClient(token: WenshuAuth.instance.token);
      final info = await client.userInfo();
      if (mounted) {
        setState(() {
          _userName = info.name;
          _uid = info.uid;
          _totalSpace = info.totalSpace;
          _usedSpace = info.usedSpace;
        });
      }
    } catch (_) {}
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
      final success = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WenshuLoginPage()),
      );
      if (success == true && mounted) {
        await _checkLogin();
      }
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
            const SizedBox(height: 16),
            // 用户信息卡片
            if (_isLoggedIn) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              _userName.isNotEmpty ? _userName.substring(0, 1) : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  'UID: $_uid',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 存储空间
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('存储空间'),
                          Text(
                            '${(_usedSpace / 1024 / 1024 / 1024).toStringAsFixed(1)}GB / ${(_totalSpace / 1024 / 1024 / 1024).toStringAsFixed(1)}GB',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalSpace > 0 ? _usedSpace / _totalSpace : 0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // 上传卡片
            Card(
              child: ListTile(
                leading: const Icon(Icons.send, size: 32),
                title: const Text('发文件'),
                subtitle: const Text('上传文件生成分享链接'),
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
                leading: const Icon(Icons.download, size: 32),
                title: const Text('收集文件'),
                subtitle: const Text('创建收集链接让别人上传'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuTaskListPage(title: '收集文件', type: 'collect')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // 我发送的
            Card(
              child: ListTile(
                leading: const Icon(Icons.send_outlined, size: 32),
                title: const Text('我发送的'),
                subtitle: const Text('查看我上传的文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuTaskListPage(title: '我发送的', type: 'send')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 发给我的
            Card(
              child: ListTile(
                leading: const Icon(Icons.call_received, size: 32),
                title: const Text('发给我的'),
                subtitle: const Text('查看别人发给我的文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuTaskListPage(title: '发给我的', type: 'receive')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 我收集的
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder, size: 32),
                title: const Text('我收集的'),
                subtitle: const Text('查看我收集的文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuTaskListPage(title: '我收集的', type: 'collect')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 向我收集的
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder_shared, size: 32),
                title: const Text('向我收集的'),
                subtitle: const Text('查看别人向我收集的文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WenshuTaskListPage(title: '向我收集的', type: 'recollect')),
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
