import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import 'common.dart';

/// 文叔叔任务列表页（我发送的/发给我的/我收集的/向我收集的）。
class WenshuTaskListPage extends ConsumerStatefulWidget {
  const WenshuTaskListPage({
    super.key,
    required this.title,
    required this.type,
  });

  final String title;
  final String type; // send / receive / collect / recollect

  @override
  ConsumerState<WenshuTaskListPage> createState() => _WenshuTaskListPageState();
}

class _WenshuTaskListPageState extends ConsumerState<WenshuTaskListPage> {
  List<WenshuTask> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = WenshuClient(token: WenshuAuth.instance.token);
      List<WenshuTask> tasks;
      switch (widget.type) {
        case 'send':
          tasks = await client.getSendList();
          break;
        case 'receive':
          tasks = await client.getReceiveList();
          break;
        case 'collect':
          tasks = await client.getCollectList();
          break;
        case 'recollect':
          tasks = await client.getRecollectList();
          break;
        default:
          tasks = [];
      }
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('加载失败：$_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(task.name),
                          subtitle: Text('大小: ${(task.size / 1024 / 1024).toStringAsFixed(1)}MB'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: 打开任务详情
                          },
                        );
                      },
                    ),
    );
  }
}
