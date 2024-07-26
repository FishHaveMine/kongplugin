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

const String AP_DEFAULT_SSID = "HUAWEI_MK_ZT";
const String AP_DEFAULT_PASSWORD = "Kong2023";

Map<int, String> deviceType = {
  1: 'devtype_xye_idu',
  2: 'devtype_x1x2_idu',
  3: 'devtype_wenkongqi_idu',
  5: 'devtype_wkq_86m_idu',
  6: 'devtype_x1x2ToRtu',
  7: 'devtype_xye_v6_idu',
  10: 'devtype_awm2611_sensor',
  9: 'devtype_dds_sensor',
  11: 'devtype_ksm_sensor',
  12: 'devtype_mk3200',
  13: 'devtype_mkb2',
};
Map<String, List> deviceTypeLimit = {
  'deviceType-ac': [1, 2, 3, 5, 6, 7],
  'deviceType-light': [12, 13],
  'deviceType-sensor': [10, 11, 9]
};

class Kongplugin {
  UdpService? udpService;
  int _sendConigError = 0;

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

  Future<bool> toConnectAP() async {
    print("尝试连接WiFi");

    var _isConnected = await WiFiForIoTPlugin.isConnected();
    if (_isConnected) {
      String? conssid = await WiFiForIoTPlugin.getBSSID();
      if (conssid == AP_DEFAULT_SSID) {
        return true;
      } else {
        bool isdisconnect = await WiFiForIoTPlugin.disconnect();
        print("断开已有Wi-Fi，连接 悟空ap : $isdisconnect");
        if (!isdisconnect) {
          return false;
        }
      }
    }
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

//设置udp服务的host和token
  initUDPservice(host, token) {
    udpService =
        UdpService(address: InternetAddress(host), port: 8101, token: token);
  }

//获取硬件的设备列表
  getDeviceList() async {
    try {
      var back = await udpService?.post({
        "op": "get_config_deviceList",
        "data": {},
      });

      List baseData = jsonDecode(jsonEncode(back['data']['deviceList']));
      // idx=devtype*100000+a1*100+a2,
      if (baseData.isNotEmpty) {
        for (var element in baseData) {
          if (element['idx'] != null) {
            int idx = int.parse(element['idx'].toString());
            element['t'] = idx ~/ 100000;

            int a2 = int.parse(idx
                .toString()
                .substring(idx.toString().length - 1, idx.toString().length));
            double a = ((idx - element['t'] * 100000) - a2) / 100;
            element['a'] = a.toInt();
            if (element['t'] == 12) element['a2'] = a2;

            element['type'] = '--';
            int tKey = int.parse(element['t'].toString());
            if (deviceTypeLimit['deviceType-ac']!.contains(tKey)) {
              element['type'] = 'AC';
            }
            if (deviceTypeLimit['deviceType-light']!.contains(tKey)) {
              element['type'] = 'Light';
            }
            if (deviceTypeLimit['deviceType-sensor']!.contains(tKey)) {
              element['type'] = 'Sensor';
            }
          }
        }
      }

      const sortLimit = ['AC', 'Light', 'Sensor'];
      baseData.sort((a, b) =>
          sortLimit.indexOf(a['type']) - sortLimit.indexOf(b['type']));

      return baseData;
    } catch (e) {
      return [];
    }
  }

//获取硬件的场景列表
  getSceneList() async {
    try {
      var back = await udpService?.post({
        "op": "get_config_sceneList",
        "data": {},
      });
      return back['data']['sceneList'];
    } catch (e) {
      return [];
    }
  }

//获取硬件的日程列表
  getScheduleList() async {
    try {
      var back = await udpService?.post({
        "op": "get_config_scheduleList",
        "data": {},
      });

      List baseData = jsonDecode(jsonEncode(back['data']['scheduleList']));
      // BIT 0 1 2 3 4 5 6 7
      //     0 6 5 7 3 2 1 7
      List weekIN = [0, 6, 5, 4, 3, 2, 1, 7];
      if (baseData.isNotEmpty) {
        for (var element in baseData) {
          if (element['weekdays'] != null) {
            //                  0  6  5  4  3  2  1  7
            List wdaysString = [0, 0, 0, 0, 0, 0, 0, 0];
            for (int days = 1; days < weekIN.length; days++) {
              if (element['weekdays'].contains(weekIN[days].toString())) {
                wdaysString[days] = 1;
              }
            }

            int wdays = int.parse(wdaysString.join(), radix: 2);
            element['wdays'] = wdays;
          } else if (element['weekdays'] == null && element['wdays'] != null) {
            String binary =
                int.parse(element['wdays'].toString()).toRadixString(2);
            if (binary.length < 8) binary = binary.padLeft(8, '0');
            List week = binary.split('');
            element['weekdays'] = '';
            for (int days = 1; days < weekIN.length; days++) {
              if (week[days] == '1') {
                element['weekdays'] =
                    element['weekdays'] + weekIN[days].toString();
              }
            }
          }
        }
      }
      return jsonDecode(jsonEncode(baseData));
    } catch (e) {
      return [];
    }
  }

//获取硬件的基本配置
  getCommon() async {
    try {
      var back = await udpService?.post({
        "op": "get_config_common",
        "data": {},
      });
      return back['data']['common'];
    } catch (e) {
      return [];
    }
  }

//更新硬件的时间
  Future<bool> setDateTime() async {
    try {
      DateTime now = DateTime.now();

      int year = now.year;
      int month = now.month;
      int day = now.day;
      int weekday = now.weekday; // 1 = Monday, 7 = Sunday
      int hour = now.hour;
      int minute = now.minute;
      int second = now.second;
      var back = await udpService?.post({
        "op": "setdatetime",
        "data": {
          'year': year,
          'month': month,
          'day': day,
          'wday': weekday,
          'hour': hour,
          'minute': minute,
          'second': second,
        },
      });
      return true;
    } catch (e) {
      return false;
    }
  }

//下发devices数据到硬件
  Future<bool> sendDevicesConig(devices) async {
    try {
      List device_List = [];
      if (devices) {
        for (var devices in devices) {
          device_List.add({
            "n": devices['n'],
            "idx": devices['idx'],
          });
        }
      }
      var back = await udpService?.post({
        "op": "set_config_deviceList",
        "data": {"deviceList": device_List},
      });
      return true;
    } catch (e) {
      return false;
    }
  }

//下发 scenes 数据到硬件
  Future<bool> sendScenesConig(scenes) async {
    try {
      var back = await udpService?.post({
        "op": "set_config_sceneList",
        "data": {"sceneList": scenes},
      });
      return true;
    } catch (e) {
      return false;
    }
  }

//下发 schedule 数据到硬件
  Future<bool> sendScheduleConig(schedule) async {
    try {
      List sendScenes = [];
      if (schedule) {
        for (var schedule in schedule) {
          sendScenes.add({
            "n": schedule['n'],
            "t": schedule['t'],
            "wdays": schedule['wdays'],
            "scIdx": schedule['scIdx']
          });
        }
      }
      var back = await udpService?.post({
        "op": "set_config_scheduleList",
        "data": {"scheduleList": sendScenes},
      });
      return true;
    } catch (e) {
      return false;
    }
  }

//下发 common 数据到硬件
  Future<bool> sendCommonConig(common) async {
    try {
      var back = await udpService?.post({
        "op": "set_config_common",
        "data": {"common": common}
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

int seq = 0;
String ipAddress = ''; // 搜索并链接的VRF设备IP

class UdpService {
  final InternetAddress address;
  final int port;
  final String token;

  UdpService({required this.address, required this.port, required this.token});

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
