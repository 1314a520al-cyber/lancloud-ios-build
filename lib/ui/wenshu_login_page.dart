import 'package:material_ui/material_ui.dart' hide Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';

import '../core/api/wenshu_auth.dart';
import '../core/api/wenshu_client.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'm3e.dart';

/// 文叔叔登录页（手机号+验证码）。
class WenshuLoginPage extends riverpod.ConsumerStatefulWidget {
  const WenshuLoginPage({super.key});

  @override
  riverpod.ConsumerState<WenshuLoginPage> createState() => _WenshuLoginPageState();
}

class _WenshuLoginPageState extends riverpod.ConsumerState<WenshuLoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  int _countdown = 0;
  late final WenshuClient _client;

  @override
  void initState() {
    super.initState();
    _client = WenshuClient();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }
    try {
      await _client.sendCode(_phoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送')),
        );
        setState(() => _countdown = 60);
        // 倒计时
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted && _countdown > 0) {
            setState(() => _countdown--);
            return _countdown > 0;
          }
          return false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$e')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6位验证码')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _client.mobileLogin(
        _phoneController.text,
        _codeController.text,
      );
      // 保存 token 到本地
      await WenshuAuth.instance.saveLogin(token: result.token);
      // 获取用户信息
      try {
        final userInfo = await _client.userInfo();
        await WenshuAuth.instance.saveLogin(
          token: result.token,
          userName: userInfo.name,
          uid: userInfo.uid,
        );
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录成功，欢迎 ${WenshuAuth.instance.userName ?? ""}')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('登录文叔叔')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Center(
              child: Icon(Icons.cloud_outlined, size: 64),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '文叔叔账号登录',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号',
                prefixText: '+86 ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      hintText: '请输入验证码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(_countdown > 0 ? '$_countdown秒' : '获取验证码'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }
}
