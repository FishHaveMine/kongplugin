import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kongplugin/kongplugin.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'kongplugin_platform_interface.dart';

/// An implementation of [KongpluginPlatform] that uses method channels.
class MethodChannelKongplugin extends KongpluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kongplugin');
  Kongplugin unit = Kongplugin();

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<WifiNetwork>> getWifiList() async {
    return unit.loadWifiList();
  }
}
