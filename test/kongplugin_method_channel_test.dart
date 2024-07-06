import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongplugin/kongplugin_method_channel.dart';

void main() {
  MethodChannelKongplugin platform = MethodChannelKongplugin();
  const MethodChannel channel = MethodChannel('kongplugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
