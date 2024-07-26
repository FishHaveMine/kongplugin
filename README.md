# kongplugin

美控热泵调试插件

## Getting Started

依赖插件：
  udp: 5.0.3        https://pub.dev/packages/udp
  wifi_iot: ^0.3.19  https://pub.dev/packages/wifi_iot

注意使用Wi-Fi需要配置安卓的权限，iOS仅能进行Wi-Fi的扫描；

## 使用流程：
   如果手机已经连接了网关（美控设备）的AP：
    第一步、toSearchGayway 进行广播扫描局域网内的设备；
    第二步、toSearchGayway 回返回局域网内搜索到的设备IP列表及token，选择需要配置的IP、token 传入 initUDPservice 方法；
    第三步、调用 getDeviceList、getSceneList、getScheduleList、getCommon 等获取配置文件json进行配置；
    第四步、将配置过的数据 使用 sendDevicesConig 等下发到网关（美控设备）；

### 引入流程：
  1.在flutter项目的 pubspec.yaml 配置文件 dev_dependencies：下面添加

  kongplugin:
     git:
      url: https://github.com/FishHaveMine/kongplugin.git

  等待自动更新、或者使用 flutter pub get 进行更新；

  2.页面上使用：

  import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import 'package:kongplugin/kongplugin.dart';

class kongtest extends StatefulWidget {
  const kongtest({super.key});

  @override
  State<kongtest> createState() => _kongtestState();
}

class _kongtestState extends State<kongtest> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: TextButton(
          onPressed: () async {
            List<dynamic> loadWifiList = await Kongplugin().loadWifiList();
            //  获取Wi-Fi列表
            print('loadWifiList:$loadWifiList');
            for (var element in loadWifiList) {
              print(element.ssid);
            }
            bool toCheckAP = await Kongplugin().toCheckAP();
            print('toCheckAP:$toCheckAP');
          },
          child: Text("测试"),
        ),
      ),
    );
  }
}

