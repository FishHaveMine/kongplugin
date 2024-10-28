// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';

/**
 * 热泵接口
 */

List IPTokenList = [];

String token = '';
String ipAddress = ''; // 搜索并链接的VRF设备IP

class KongpluginHp {
  late RawDatagramSocket _socket;
  int udpport = 48102;
  String user = 'admin';
  String password = '123AB@ab';
  int seq = 0;

  /// 通用方法
  Future<String?> getWifiAddress() async {
    final networkInfo = NetworkInfo();
    return await networkInfo.getWifiIP(); // 获取设备的Wi-Fi IP
  }

  sendCommand(message, address, port) {
    _socket.send(message, address, port);
  }

  String md5Hash(String input) {
    // 将输入字符串转换为字节列表
    var bytes = utf8.encode(input);

    // 计算 MD5 哈希值
    var digest = md5.convert(bytes);

    // 将哈希值转换为十六进制字符串
    return digest.toString();
  }

  Map completermap = {};
  Future<dynamic> post(Map<String, dynamic> data) async {
    var localIp = await getWifiAddress();
    print("_initUdp start localIp： $localIp  $udpport");
    seq++;
    data["seq"] = seq;
    data["isAck"] = 0;
    data["token"] = token;
    data["sign"] = md5Hash('$seq$token$user$password${data["op"]}' + "0");
    String message = jsonEncode(data);
    RawDatagramSocket socket = Platform.isAndroid
        ? await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            udpport,
            reuseAddress: true,
            // reusePort: true,
          )
        : await RawDatagramSocket.bind(
            InternetAddress(localIp!), // 在 iOS 上绑定具体的 Wi-Fi IP
            udpport,
            reuseAddress: true,
            reusePort: true,
          );

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true; // 允许读取事件
    socket.writeEventsEnabled = true; // 允许写入事件次接收相同的广播数据包
    socket.multicastLoopback = true;
    completermap[seq] = Completer<dynamic>();
    Timer timer = Timer(const Duration(seconds: 5), () {
      completermap[seq].completeError('Timeout');
      try {
        socket.close();
      } catch (e) {}
    });
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
        if (datagram != null) {
          timer.cancel();
          String message = utf8.decode(datagram.data);
          completermap[seq].complete(jsonDecode(message));
          try {
            socket.close();
          } catch (e) {}
        }
      }
    });
    Future.delayed(const Duration(microseconds: 100), () {
      socket.send(utf8.encode(message), InternetAddress(ipAddress), 8101);
    });

    return completermap[seq].future;
  }

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

  /// 连接WiFi
  Future<bool> toConnectAP(ssid, pass) async {
    print("尝试连接WiFi");

    var _isConnected = await WiFiForIoTPlugin.isConnected();
    if (_isConnected) {
      String? conssid = await WiFiForIoTPlugin.getBSSID();
      if (conssid == ssid) {
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
      bool connect =
          await WiFiForIoTPlugin.connect(ssid, password: pass, joinOnce: true);
      return connect;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// 搜索网关 返回 [{host: 192.168.100.165, token: token}]
  Future<List> searhGayway() async {
    await initsearchingUdp();
    IPTokenList = [];
    ipAddress = '';
    seq = Random().nextInt(100) + 50;
    token = '';
    String message = jsonEncode({
      "op": "gettoken",
      "seq": seq,
      "isAck": 0,
      "data": {},
      "token": "",
      "sign": ""
    });
    sendCommand(utf8.encode(message), InternetAddress('255.255.255.255'), 8101);

    var value = 0;
    Future.doWhile(() async {
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
      sendCommand(
          utf8.encode(message), InternetAddress('255.255.255.255'), 8101);
      if (value == 10) {
        return false;
      }
      return true;
    });

    await Future.delayed(const Duration(seconds: 5));

    print("IPTokenList: $IPTokenList");
    return List.from(IPTokenList);
  }

  /// 连接网关 返回 udp服务
  Future<bool> connectGayway(host) async {
    print("IPTokenList: ${IPTokenList}");
    if (IPTokenList.isEmpty) {
      return false;
    }
    var _select = IPTokenList.firstWhere((element) => element["host"] == host);
    if (_select == null) {
      return false;
    }
    token = _select["token"];
    ipAddress = _select["host"]; // 搜索并链接的VRF设备IP

    return true;
  }

  /// 创建udp服务
  Future<RawDatagramSocket?> initsearchingUdp() async {
    try {
      _socket.close();
    } catch (e) {}
    try {
      var localIp = await getWifiAddress();
      print("_initUdp start localIp： $localIp  $udpport");
      _socket = Platform.isAndroid
          ? await RawDatagramSocket.bind(
              InternetAddress.anyIPv4,
              udpport,
              reuseAddress: true,
              // reusePort: true,
            )
          : await RawDatagramSocket.bind(
              InternetAddress(localIp!), // 在 iOS 上绑定具体的 Wi-Fi IP
              udpport,
              reuseAddress: true,
              reusePort: true, // 允许重用端口
            );
      _socket.broadcastEnabled = true;
      _socket.readEventsEnabled = true; // 允许读取事件
      _socket.writeEventsEnabled = true; // 允许写入事件次接收相同的广播数据包
      _socket.multicastLoopback = true;

      _socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          // 一直读取直到缓冲区为空
          Datagram? datagram = _socket.receive();
          if (datagram != null) {
            String message = String.fromCharCodes(datagram.data).trim();
            if (message != '') {
              try {
                var backJson = jsonDecode(message);
                if (backJson['isAck'] == '1' &&
                    (backJson['errorCode'] != null &&
                        backJson['errorCode'] != '0')) {}
                if (backJson['op'] == 'gettoken') {
                  bool hasHost = IPTokenList.where(
                          (element) => element['host'] == datagram.address.host)
                      .isEmpty;
                  if (hasHost) {
                    IPTokenList.add({
                      'host': datagram.address.host,
                      'name': backJson['name'],
                      'token': backJson['token']
                    });
                  }
                } else {
                  // 其他数据处理
                }
                if (backJson['seq'] == seq) {
                  seq++;
                }
              } catch (e) {}
            } else {}
          }
        }
      }, onDone: () {});
      return _socket;
    } catch (e) {
      return null;
    }
  }

  /// 发送指令
  Future<dynamic> getGaywayStatus() async {
    try {
      var back = await post({
        "op": "get_device_status",
        "data": {},
      });
      try {
        if (back["data"] != null && back["data"]["dev_info"] != null) {
          return back["data"];
        }
      } catch (e) {
        return {};
      }
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> getPoint() async {
    try {
      var _totalback = await post({
        "op": "get_points",
        "data": {"offset": 0, "type": 1},
      });
      try {
        if (_totalback["data"] != null) {
          List firstIndexes = [];
          int _total = _totalback["data"]["total"];
          var _pointsMap = {};
          // 每个小数组的长度为 100
          int chunkSize = _totalback["data"]["offset"] == 0
              ? _totalback["data"]["points"].length
              : 50;

          List<int> originalList = List.generate(_total, (index) => index);
          // 保存所有小数组的第一个下标
          // 循环切割数组
          for (int i = 0; i < originalList.length; i += chunkSize) {
            // 通过 sublist 方法切割
            List<int> chunk = originalList.sublist(
                i,
                (i + chunkSize > originalList.length)
                    ? originalList.length
                    : i + chunkSize);

            // 获取每个小数组的第一个下标
            firstIndexes.add(chunk.first);

            for (var element in firstIndexes) {
              _pointsMap[element] = await getbyoffset(offset: element);
            }
          }
          return _pointsMap;
        }
      } catch (e) {
        return {};
      }
    } catch (e) {
      return e;
    }
  }

  getbyoffset({offset}) async {
    try {
      var back = await post({
        "op": "get_points",
        "data": {"offset": offset, "type": 1},
      });
      try {
        if (back["data"] != null) {
          return back["data"];
        }
      } catch (e) {
        return {};
      }
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> setPointVal(poindN, pointVal) async {
    try {
      var back = await post({
        "op": "set_point",
        "data": {"n": poindN, "v": pointVal},
      });
      return back;
    } catch (e) {
      return e;
    }
  }
}
