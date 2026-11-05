import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔取件页（输入取件码下载）。
class WenshuReceivePage extends riverpod.ConsumerStatefulWidget {
  const WenshuReceivePage({super.key});

  @override
  riverpod.ConsumerState<WenshuReceivePage> createState() => _WenshuReceivePageState();
}

class _WenshuReceivePageState extends riverpod.ConsumerState<WenshuReceivePage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  List<_FileItem> _files = [];
  late final WenshuClient _client;

  @override
  void initState() {
    super.initState();
    _client = WenshuClient(token: WenshuAuth.instance.token);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _files = [];
    });
    try {
      // TODO: 解析取件码，调 sharekey/info + file_list
      // 临时：假设输入的是 ufileid
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _files = [_FileItem(name: 'test.txt', size: 1024, ufileid: 'test123')];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(_FileItem file) async {
    try {
      final url = await _client.downloadSign(ufileid: file.ufileid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载链接：$url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('取件')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '取件码或链接',
                hintText: '输入取件码或粘贴分享链接',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _query(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _query,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('查询'),
            ),
            const SizedBox(height: 24),
            if (_files.isNotEmpty) ...[
              Text('文件列表', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._files.map((f) => ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(f.name),
                    subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => _download(f),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileItem {
  final String name;
  final int size;
  final String ufileid;
  _FileItem({required this.name, required this.size, required this.ufileid});
}
