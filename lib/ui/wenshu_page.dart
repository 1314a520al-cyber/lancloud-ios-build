import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

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
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wenshuTitle)),
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
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('文叔叔功能开发中'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
