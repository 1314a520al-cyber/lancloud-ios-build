import 'package:shared_preferences/shared_preferences.dart';

/// 文叔叔登录态存储。
class WenshuAuth {
  WenshuAuth._();
  static final WenshuAuth instance = WenshuAuth._();

  static const _keyToken = 'wenshu_token';
  static const _keyUserName = 'wenshu_user_name';
  static const _keyUid = 'wenshu_uid';

  String? _token;
  String? _userName;
  String? _uid;

  String? get token => _token;
  String? get userName => _userName;
  String? get uid => _uid;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 初始化，从本地存储读取。
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _userName = prefs.getString(_keyUserName);
    _uid = prefs.getString(_keyUid);
  }

  /// 保存登录态。
  Future<void> saveLogin({
    required String token,
    String? userName,
    String? uid,
  }) async {
    _token = token;
    _userName = userName;
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (userName != null) await prefs.setString(_keyUserName, userName);
    if (uid != null) await prefs.setString(_keyUid, uid);
  }

  /// 退出登录。
  Future<void> logout() async {
    _token = null;
    _userName = null;
    _uid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUid);
  }
}
