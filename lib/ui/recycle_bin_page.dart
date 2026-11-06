import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../core/account_state.dart';
import '../core/api/lanzou_client.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 蓝奏云回收站原生页面。
class RecycleBinPage extends riverpod.ConsumerStatefulWidget {
  const RecycleBinPage({super.key});

  @override
  riverpod.ConsumerState<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends riverpod.ConsumerState<RecycleBinPage> {
  bool _loading = true;
  List<_RecycleFile> _files = [];
  String? _cookie;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 从 account_state 获取当前账号的 cookie
      final accountState = ref.read(accountStateProvider);
      final account = accountState.store.active;
      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先登录蓝奏云账号')),
          );
        }
        return;
      }
      _cookie = account.cookie;
      final dio = Dio();
      final resp = await dio.get(
        'https://pc.woozooo.com/mydisk.php?item=recycle&action=files',
        options: Options(
          headers: {
            'Cookie': _cookie ?? '',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      // HTML 解析：提取回收站文件列表
      final html = resp.data.toString();
      final List<_RecycleFile> files = [];
      // 正则提取 file_id 和文件名（改进版）
      final regex = RegExp(r'file_id=(\d+)[^>]*>.*?<a[^>]*>([^<]+)</a>', dotAll: true);
      for (final match in regex.allMatches(html)) {
        files.add(_RecycleFile(
          id: match.group(1)!,
          name: match.group(2)!.trim(),
          size: '',
        ));
      }
      // 如果上面的正则没匹配到，用更宽松的正则
      if (files.isEmpty) {
        final regex2 = RegExp(r'file_id=(\d+)');
        for (final match in regex2.allMatches(html)) {
          files.add(_RecycleFile(
            id: match.group(1)!,
            name: '文件 ${match.group(1)}',
            size: '',
          ));
        }
      }
      setState(() {
        _files = files;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreFile(String fileId) async {
    try {
      final dio = Dio();
      await dio.get(
        'https://pc.woozooo.com/mydisk.php?item=recycle&action=file_restore&file_id=$fileId',
        options: Options(
          headers: {
            'Cookie': _cookie ?? '',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败：$e')),
        );
      }
    }
  }

  Future<void> _deleteFile(String fileId) async {
    try {
      final dio = Dio();
      await dio.get(
        'https://pc.woozooo.com/mydisk.php?item=recycle&action=file_delete_complete&file_id=$fileId',
        options: Options(
          headers: {
            'Cookie': _cookie ?? '',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已彻底删除')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要清空回收站吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final dio = Dio();
        await dio.get(
          'https://pc.woozooo.com/mydisk.php?item=recycle&action=delete_all',
          options: Options(
            headers: {
              'Cookie': _cookie ?? '',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('回收站已清空')),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清空失败：$e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recycleBin),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: '清空回收站',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('回收站是空的'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final f = _files[index];
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file),
                        title: Text(f.name),
                        subtitle: Text(f.size),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.restore),
                              tooltip: '恢复',
                              onPressed: () => _restoreFile(f.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              tooltip: '彻底删除',
                              onPressed: () => _deleteFile(f.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RecycleFile {
  final String id;
  final String name;
  final String size;
  _RecycleFile({required this.id, required this.name, required this.size});
}
