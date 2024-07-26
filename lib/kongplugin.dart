// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:udp/udp.dart';
import 'kongplugin_platform_interface.dart';

import 'package:wifi_iot/wifi_iot.dart';

const String AP_DEFAULT_SSID = "HUAWELMK_ZT";
const String AP_DEFAULT_PASSWORD = "Kong2023";

class Kongplugin {
  UdpService? udpService;

  /// 获取Wi-Fi列表
  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = <WifiNetwork>[];
    }

    return htResultNetwork;
  }

  toConnectAP() async {
    print("尝试连接WiFi");
    try {
      bool connect = await WiFiForIoTPlugin.connect(AP_DEFAULT_SSID,
          password: AP_DEFAULT_PASSWORD, joinOnce: true);
      return connect;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// 查看Wi-Fi列表内是否存在 悟空ap
  Future<bool> toCheckAP() async {
    print("查看Wi-Fi列表内是否存在 悟空ap : $AP_DEFAULT_SSID");
    bool isconect = false;
    bool isOpen = false;
    var _isEnabled = await WiFiForIoTPlugin.isEnabled();
    var _isConnected = await WiFiForIoTPlugin.isConnected();
    if (_isEnabled) {
      List<WifiNetwork> htResultNetwork = await loadWifiList();
      htResultNetwork.forEach((element) async {
        if (element.ssid != null && element.ssid != '') {
          if (AP_DEFAULT_SSID == element.ssid) {
            isOpen = true; //返回是否连接设备WiFi状态：true 成功链接     false 失败
          }
        }
      });
      if (isOpen) {
        isconect = await toConnectAP();
      }
      return isconect;
    }
    return isconect;
  }

  Future<List?> toSearchGayway() async {
    List IPToken = [];
    try {
      final RawDatagramSocket socketSet =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8000);

      socketSet.broadcastEnabled = true;
      socketSet.readEventsEnabled = true; // 允许读取事件
      socketSet.writeEventsEnabled = true; // 允许写入事件次接收相同的广播数据包

      socketSet.listen((RawSocketEvent event) {
        Datagram? datagram = socketSet.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data).trim();
          if (message != '') {
            try {
              var backJson = jsonDecode(message);
              if (backJson['isAck'] == '1' &&
                  (backJson['errorCode'] != null &&
                      backJson['errorCode'] != '0')) {}
              if (backJson['seq'] == seq) {
                seq++;
              }
              if (backJson['op'] == 'gettoken') {
                bool hasHost = IPToken.where(
                        (element) => element['host'] == datagram.address.host)
                    .isEmpty;
                if (hasHost) {
                  IPToken.add({
                    'host': datagram.address.host,
                    'token': backJson['token']
                  });
                }
                // Get.to(vrfsettting());
              }
            } catch (e) {}
          } else {}
        }
      });

      String message = jsonEncode({
        "op": "gettoken",
        "seq": seq,
        "isAck": 0,
        "data": {},
        "token": "",
        "sign": ""
      });
      socketSet!
          .send(utf8.encode(message), InternetAddress('255.255.255.255'), 8101);

      var value = 0;
      await Future.doWhile(() async {
        value++;
        await Future.delayed(const Duration(milliseconds: 450));
        message = jsonEncode({
          "op": "gettoken",
          "seq": Random().nextInt(100) + 50,
          "isAck": 0,
          "data": {},
          "token": "",
          "sign": ""
        });
        socketSet!.send(
            utf8.encode(message), InternetAddress('255.255.255.255'), 8101);
        if (value == 10) {
          return false;
        }
        return true;
      });
    } catch (e) {}
    return IPToken.isEmpty ? null : IPToken;
  }
}

int seq = 0;
String token = '';
String ipAddress = ''; // 搜索并链接的VRF设备IP

class UdpService {
  final InternetAddress address;
  final int port;

  UdpService({required this.address, required this.port});

  Future<dynamic> post(Map<String, dynamic> data) async {
    seq++;
    data["seq"] = seq;
    data["isAck"] = 0;
    data["token"] = token;
    data["sign"] = '$seq$token';
    final String message = jsonEncode(data);
    final RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    socket.send(utf8.encode(message), address, port);
    socket.readEventsEnabled = true; // 允许读取事件
    socket.writeEventsEnabled = true; // 允许写入事件次接收相同的广播数据包
    final Completer<dynamic> completer = Completer<dynamic>();
    Timer timer = Timer(const Duration(seconds: 5), () {
      completer.completeError('Timeout');
      socket.close();
    });
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
        if (datagram != null) {
          timer.cancel();
          String message = utf8.decode(datagram.data);
          completer.complete(jsonDecode(message));
          socket.close();
        }
      }
    });

    return completer.future;
  }
}
