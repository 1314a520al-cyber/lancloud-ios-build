import 'package:flutter_test/flutter_test.dart';
import 'package:lancloud/core/app_environment.dart';
import 'package:lancloud/core/transfer/transfer_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'transfer_dependencies_test.dart'
    show buildTransferManagerForEnvironment;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  TransferTask uploadTask({TransferStatus status = TransferStatus.queued}) {
    return TransferTask(
      id: 'u1',
      kind: TransferKind.upload,
      name: 'old.bin',
      accountUid: '',
      folderId: '1',
    )..status = status;
  }

  test('排队中的上传任务可以改名，改名后是云端文件名', () async {
    final environment = AppEnvironment();
    addTearDown(environment.dispose);
    final manager = buildTransferManagerForEnvironment(environment);
    final task = uploadTask();
    manager.tasks.add(task);

    final message = manager.renameTask('u1', '  new.bin  ');

    expect(message, '');
    expect(task.name, 'new.bin');
  });

  test('传输已开始的任务拒绝改名', () {
    final environment = AppEnvironment();
    addTearDown(environment.dispose);
    final manager = buildTransferManagerForEnvironment(environment);
    final task = uploadTask(status: TransferStatus.running);
    manager.tasks.add(task);

    final message = manager.renameTask('u1', 'new.bin');

    expect(message, isNull);
    expect(task.name, 'old.bin');
  });

  test('空名字不生效', () {
    final environment = AppEnvironment();
    addTearDown(environment.dispose);
    final manager = buildTransferManagerForEnvironment(environment);
    final task = uploadTask();
    manager.tasks.add(task);

    final message = manager.renameTask('u1', '   ');

    expect(message, '');
    expect(task.name, 'old.bin');
  });
}
