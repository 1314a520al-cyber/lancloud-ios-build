import 'package:dio/dio.dart';

/// 文叔叔（wenshushu.cn）API 客户端。
///
/// 接口全部来自 2026-11-06 真实登录抓包，已实测跑通。
class WenshuClient {
  WenshuClient({this.token, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://www.wenshushu.cn',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  final String? token;
  final Dio _dio;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        if (token != null) 'X-TOKEN': token!,
        'prod': 'com.wenshushu.web.pc',
        'Referer': 'https://www.wenshushu.cn/',
      };

  /// 匿名登录，获取临时 token。
  Future<WenshuLoginResult> anonymousLogin() async {
    final resp = await _dio.post(
      '/ap/login/anonymous',
      data: {},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '匿名登录失败');
    }
    return WenshuLoginResult.fromJson(data['data']);
  }

  /// 获取账号信息。
  Future<WenshuUserInfo> userInfo() async {
    final resp = await _dio.post(
      '/ap/user/userinfo',
      data: {},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取用户信息失败');
    }
    return WenshuUserInfo.fromJson(data['data']);
  }

  /// 发送短信验证码。
  Future<void> sendCode(String phone) async {
    final resp = await _dio.post(
      '/ap/login/sendcode',
      data: {
        'coutry_code': '+86',
        'tel': phone,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '发送验证码失败');
    }
  }

  /// 验证码登录。
  Future<WenshuLoginResult> mobileLogin(String phone, String code) async {
    final resp = await _dio.post(
      '/ap/login/mobilecode',
      data: {
        'coutry_code': '+86',
        'tel': phone,
        'code': code,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '登录失败');
    }
    return WenshuLoginResult.fromJson(data['data']);
  }

  /// 创建发送任务。
  Future<WenshuTask> addSend({
    required int fileSize,
    required int fileCount,
    String expire = '3',
    String pwd = '',
  }) async {
    final resp = await _dio.post(
      '/ap/task/addsend',
      data: {
        'sender': '',
        'remark': '',
        'isextension': false,
        'pwd': pwd,
        'expire': expire,
        'recvs': ['social', 'public'],
        'file_size': fileSize,
        'file_count': fileCount,
        'notSaveTo': false,
        'trafficStatus': 0,
        'task_traffic_limit': '',
        'downPreCountLimit': 0,
        'notDownload': false,
        'notPreview': false,
        'fileDisplay': 0,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '创建任务失败');
    }
    return WenshuTask.fromJson(data['data']);
  }

  /// 获取上传ID。
  Future<String> getUploadId({
    required String preid,
    required String boxid,
    required String linkid,
    required int length,
    required int count,
  }) async {
    final resp = await _dio.post(
      '/ap/uploadv2/getupid',
      data: {
        'preid': preid,
        'boxid': boxid,
        'linkid': linkid,
        'utype': 'sendcopy',
        'originUpid': '',
        'length': length,
        'count': count,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取上传ID失败');
    }
    return data['data']['upId'] as String;
  }

  /// 获取上传URL（腾讯云COS直传）。
  Future<String> getUploadUrl({
    required String fname,
    required int fsize,
    required String upId,
  }) async {
    final resp = await _dio.post(
      '/ap/uploadv2/psurl',
      data: {
        'ispart': false,
        'fname': fname,
        'fsize': fsize,
        'upId': upId,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取上传URL失败');
    }
    return data['data']['url'] as String;
  }

  /// 完成上传。
  Future<WenshuFile> completeUpload({
    required String fname,
    required String boxid,
    required String preid,
    required String upId,
  }) async {
    final resp = await _dio.post(
      '/ap/uploadv2/complete',
      data: {
        'ispart': false,
        'fname': fname,
        'location': {
          'boxid': boxid,
          'preid': preid,
        },
        'upId': upId,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '完成上传失败');
    }
    return WenshuFile.fromJson(data['data']);
  }

  /// 生成分享链接。
  Future<WenshuShareLinks> copySend({
    required String tid,
    required String bid,
    required String ufileid,
  }) async {
    final resp = await _dio.post(
      '/ap/task/copysend',
      data: {
        'tid': tid,
        'bid': bid,
        'ufileid': ufileid,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '生成分享链接失败');
    }
    return WenshuShareLinks.fromJson(data['data']);
  }

  /// 获取下载直链。
  Future<String> downloadSign({
    required String ufileid,
    int type = 1,
  }) async {
    final resp = await _dio.post(
      '/ap/dl/sign',
      data: {
        'ufileid': ufileid,
        'type': type,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取下载链接失败');
    }
    return data['data']['url'] as String;
  }

  /// 任务设置（密码/过期时间/下载次数等）。
  Future<void> taskSet({
    required String taskid,
    required String name,
    required String value,
  }) async {
    final resp = await _dio.post(
      '/ap/task/taskset',
      data: {
        'taskid': taskid,
        'name': name,
        'value': value,
      },
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '设置失败');
    }
  }

  /// 获取我发送的文件列表
  Future<List<WenshuTask>> getSendList({int page = 1, int size = 20}) async {
    final resp = await _dio.get(
      '/ag/task/sendlist',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取列表失败');
    }
    final list = data['data']?['list'] as List? ?? [];
    return list.map((e) => WenshuTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取发给我的文件列表
  Future<List<WenshuTask>> getReceiveList({int page = 1, int size = 20}) async {
    final resp = await _dio.get(
      '/ag/task/recelist',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取列表失败');
    }
    final list = data['data']?['list'] as List? ?? [];
    return list.map((e) => WenshuTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取我收集的文件列表
  Future<List<WenshuTask>> getCollectList({int page = 1, int size = 20}) async {
    final resp = await _dio.get(
      '/ag/task/collectlist',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取列表失败');
    }
    final list = data['data']?['list'] as List? ?? [];
    return list.map((e) => WenshuTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取向我收集的文件列表
  Future<List<WenshuTask>> getRecollectList({int page = 1, int size = 20}) async {
    final resp = await _dio.get(
      '/ag/task/recacollectlist',
      queryParameters: {'page': page, 'size': size},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取列表失败');
    }
    final list = data['data']?['list'] as List? ?? [];
    return list.map((e) => WenshuTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 查询取件码信息
  Future<WenshuShareInfo> shareInfo({required String sharekey, String pwd = ''}) async {
    final resp = await _dio.get(
      '/ag/share/info',
      queryParameters: {'sharekey': sharekey, 'pwd': pwd},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '查询取件码失败');
    }
    return WenshuShareInfo.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 获取取件码对应的文件列表
  Future<List<WenshuFile>> shareFileList({required String sharekey, String pwd = ''}) async {
    final resp = await _dio.get(
      '/ag/share/filelist',
      queryParameters: {'sharekey': sharekey, 'pwd': pwd},
      options: Options(headers: _headers),
    );
    final data = resp.data as Map<String, dynamic>;
    if (data['code'] != 0) {
      throw WenshuException(data['message'] ?? '获取文件列表失败');
    }
    final list = data['data']?['list'] as List? ?? [];
    return list.map((e) => WenshuFile.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class WenshuException implements Exception {
  WenshuException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WenshuLoginResult {
  WenshuLoginResult({required this.token});
  factory WenshuLoginResult.fromJson(Map<String, dynamic> json) =>
      WenshuLoginResult(token: json['token'] as String);
  final String token;
}

class WenshuUserInfo {
  WenshuUserInfo({
    required this.uid,
    required this.name,
    required this.bid,
    required this.tel,
    required this.vip,
    this.totalSpace = 20 * 1024 * 1024 * 1024, // 默认20GB
    this.usedSpace = 0,
  });
  factory WenshuUserInfo.fromJson(Map<String, dynamic> json) => WenshuUserInfo(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        bid: json['bid'] as String? ?? '',
        tel: json['tel'] as String? ?? '',
        vip: json['vip'] as String? ?? '',
        totalSpace: int.tryParse(json['totalSpace']?.toString() ?? '') ?? (20 * 1024 * 1024 * 1024),
        usedSpace: int.tryParse(json['userSpace']?.toString() ?? '') ?? 0,
      );
  final String uid;
  final String name;
  final String bid;
  final String tel;
  final String vip;
  final int totalSpace;
  final int usedSpace;
}

class WenshuTask {
  WenshuTask({
    required this.tid,
    required this.bid,
    required this.ufileid,
    required this.socialToken,
  });
  factory WenshuTask.fromJson(Map<String, dynamic> json) => WenshuTask(
        tid: json['tid'] as String,
        bid: json['bid'] as String,
        ufileid: json['ufileid'] as String,
        socialToken: json['social_token'] as String,
      );
  final String tid;
  final String bid;
  final String ufileid;
  final String socialToken;
}

class WenshuFile {
  WenshuFile({
    required this.fid,
    required this.name,
    required this.size,
  });
  factory WenshuFile.fromJson(Map<String, dynamic> json) => WenshuFile(
        fid: json['fid'] as String,
        name: json['fname'] as String? ?? '',
        size: int.tryParse(json['size'].toString()) ?? 0,
      );
  final String fid;
  final String name;
  final int size;
}

class WenshuShareLinks {
  WenshuShareLinks({
    required this.socialUrl,
    required this.publicUrl,
    required this.mgrUrl,
  });
  factory WenshuShareLinks.fromJson(Map<String, dynamic> json) => WenshuShareLinks(
        socialUrl: json['social_url'] as String,
        publicUrl: json['public_url'] as String,
        mgrUrl: json['mgr_url'] as String,
      );
  final String socialUrl;
  final String publicUrl;
  final String mgrUrl;
}

class WenshuShareInfo {
  WenshuShareInfo({
    required this.sharekey,
    required this.title,
    required this.expire,
    required this.pwd,
    required this.fileCount,
    required this.fileSize,
  });
  factory WenshuShareInfo.fromJson(Map<String, dynamic> json) => WenshuShareInfo(
        sharekey: json['sharekey']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        expire: json['expire']?.toString() ?? '',
        pwd: json['pwd']?.toString() ?? '',
        fileCount: int.tryParse(json['file_count']?.toString() ?? '') ?? 0,
        fileSize: int.tryParse(json['file_size']?.toString() ?? '') ?? 0,
      );
  final String sharekey;
  final String title;
  final String expire;
  final String pwd;
  final int fileCount;
  final int fileSize;
}
