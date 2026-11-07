import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:url_launcher/url_launcher.dart';

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔取件页（输入取件码下载别人发的文件）。
class WenshuReceivePage extends riverpod.ConsumerStatefulWidget {
  const WenshuReceivePage({super.key});

  @override
  riverpod.ConsumerState<WenshuReceivePage> createState() => _WenshuReceivePageState();
}

class _WenshuReceivePageState extends riverpod.ConsumerState<WenshuReceivePage> {
  final _codeController = TextEditingController();
  final _pwdController = TextEditingController();
  bool _loading = false;
  WenshuShareInfo? _info;
  List<WenshuFile> _files = [];
  late final WenshuClient _client;

  @override
  void initState() {
    super.initState();
    _client = WenshuClient(token: WenshuAuth.instance.token);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  /// 从输入的文本里提取取件码（支持直接粘贴分享链接）
  String _extractSharekey(String input) {
    final t = input.trim();
    // 如果是链接，提取后面的部分
    final match = RegExp(r'wenshushu\.cn/[a-z]+/([A-Za-z0-9]+)').firstMatch(t);
    if (match != null) return match.group(1)!;
    // 否则直接当取件码
    return t;
  }

  Future<void> _query() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;
    final sharekey = _extractSharekey(input);
    final pwd = _pwdController.text.trim();
    setState(() {
      _loading = true;
      _info = null;
      _files = [];
    });
    try {
      final info = await _client.shareInfo(sharekey: sharekey, pwd: pwd);
      final files = await _client.shareFileList(sharekey: sharekey, pwd: pwd);
      if (mounted) {
        setState(() {
          _info = info;
          _files = files;
        });
      }
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

  Future<void> _download(WenshuFile file) async {
    try {
      final url = await _client.downloadSign(ufileid: file.fid);
      if (mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已在浏览器打开下载链接')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('下载链接：$url')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败：$e')),
        );
      }
    }
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
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
            TextField(
              controller: _pwdController,
              decoration: const InputDecoration(
                labelText: '提取码（如果有）',
                hintText: '没有就留空',
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
            if (_info != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_info!.title.isEmpty ? '分享文件' : _info!.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('共 ${_info!.fileCount} 个文件，${_fmtSize(_info!.fileSize)}'),
                      if (_info!.expire.isNotEmpty) Text('有效期：${_info!.expire}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_files.isNotEmpty) ...[
              Text('文件列表', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._files.map((f) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(f.name),
                      subtitle: Text(_fmtSize(f.size)),
                      trailing: IconButton(
                        icon: const Icon(Icons.download_outlined),
                        onPressed: () => _download(f),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
