import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔上传页（从其他软件获取文件）。
class WenshuUploadPage extends riverpod.ConsumerStatefulWidget {
  const WenshuUploadPage({super.key});

  @override
  riverpod.ConsumerState<WenshuUploadPage> createState() => _WenshuUploadPageState();
}

class _WenshuUploadPageState extends riverpod.ConsumerState<WenshuUploadPage> {
  final List<_FileItem> _files = [];
  bool _uploading = false;
  double _progress = 0;
  String? _shareUrl;
  late final WenshuClient _client;

  @override
  void initState() {
    super.initState();
    _client = WenshuClient(token: WenshuAuth.instance.token);
  }

  Future<void> _pickFile() async {
    final result = await Future.value(null)(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _files.addAll(result.files.map((f) => _FileItem(
              name: f.name,
              size: f.size ?? 0,
              path: f.path,
            )));
      });
    }
  }

  Future<void> _upload() async {
    if (_files.isEmpty) return;
    setState(() {
      _uploading = true;
      _progress = 0;
      _shareUrl = null;
    });

    try {
      // 1. 创建任务
      final totalSize = _files.fold<int>(0, (sum, f) => sum + f.size);
      final task = await _client.addSend(
        fileSize: totalSize,
        fileCount: _files.length,
      );
      setState(() => _progress = 0.1);

      // 2. 获取上传ID
      final upId = await _client.getUploadId(
        preid: task.ufileid,
        boxid: task.bid,
        linkid: task.tid,
        length: totalSize,
        count: _files.length,
      );
      setState(() => _progress = 0.2);

      // 3. 逐文件上传
      for (var i = 0; i < _files.length; i++) {
        final file = _files[i];
        // 3.1 获取上传URL
        final uploadUrl = await _client.getUploadUrl(
          fname: file.name,
          fsize: file.size,
          upId: upId,
        );
        setState(() => _progress = 0.3 + (i / _files.length) * 0.4);

        // 3.2 上传文件到COS
        if (file.path != null) {
          final dio = Dio();
          await dio.put(
            uploadUrl,
            data: File(file.path!),
            onSendProgress: (sent, total) {
              setState(() {
                _progress = 0.3 + (i / _files.length) * 0.4 +
                    (sent / total) * 0.4 / _files.length;
              });
            },
          );
        }
      }
      setState(() => _progress = 0.8);

      // 4. 完成上传
      await _client.completeUpload(
        fname: _files.first.name,
        boxid: task.bid,
        preid: task.ufileid,
        upId: upId,
      );
      setState(() => _progress = 0.9);

      // 5. 生成分享链接
      final links = await _client.copySend(
        tid: task.tid,
        bid: task.bid,
        ufileid: task.ufileid,
      );
      setState(() {
        _progress = 1.0;
        _shareUrl = links.publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('上传文件')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('从其他软件选择文件'),
                    subtitle: const Text('调用系统文件选择器'),
                    onTap: _pickFile,
                  ),
                  const Divider(),
                  ..._files.map((f) => ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(f.name),
                        subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _files.remove(f)),
                        ),
                      )),
                  if (_shareUrl != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('分享链接', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SelectableText(_shareUrl!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_uploading) LinearProgressIndicator(value: _progress),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _files.isEmpty || _uploading ? null : _upload,
                  child: Text(_uploading
                      ? '上传中... ${(_progress * 100).toInt()}%'
                      : '开始上传'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileItem {
  final String name;
  final int size;
  final String? path;
  _FileItem({required this.name, required this.size, this.path});
}
