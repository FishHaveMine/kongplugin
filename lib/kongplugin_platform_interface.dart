import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kongplugin_method_channel.dart';

abstract class KongpluginPlatform extends PlatformInterface {
  /// Constructs a KongpluginPlatform.
  KongpluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static KongpluginPlatform _instance = MethodChannelKongplugin();

  /// The default instance of [KongpluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelKongplugin].
  static KongpluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KongpluginPlatform] when
  /// they register themselves.
  static set instance(KongpluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
