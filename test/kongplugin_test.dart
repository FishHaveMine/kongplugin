import 'package:flutter_test/flutter_test.dart';
import 'package:kongplugin/kongplugin.dart';
import 'package:kongplugin/kongplugin_platform_interface.dart';
import 'package:kongplugin/kongplugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKongpluginPlatform
    with MockPlatformInterfaceMixin
    implements KongpluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KongpluginPlatform initialPlatform = KongpluginPlatform.instance;

  test('$MethodChannelKongplugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKongplugin>());
  });

  test('getPlatformVersion', () async {
    Kongplugin kongpluginPlugin = Kongplugin();
    MockKongpluginPlatform fakePlatform = MockKongpluginPlatform();
    KongpluginPlatform.instance = fakePlatform;

    expect(await kongpluginPlugin.getPlatformVersion(), '42');
  });
}
