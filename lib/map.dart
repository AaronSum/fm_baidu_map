import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:io';
import './over_types/types.dart';
import './over_types/base.dart';

typedef void FmBaiduMapStatus(FmMapStatusInfo info);
typedef void FmBaiduMessage(String name, Object arg);

/// 地图
class FmBaiduMap {
  static const MethodChannel _channel = const MethodChannel('fm_baidu_map');
  Widget _map;
  MethodChannel _eventChannel;
  String _name;

  /// 构造
  FmBaiduMap() {
    var uuid = new Uuid();
    _name = uuid.v1();
    _map = Platform.isIOS
        ? UiKitView(
            viewType: "FmBaiduMapView",
            creationParams: {"name": _name},
            creationParamsCodec: StandardMessageCodec(),
          )
        : AndroidView(
            viewType: "FmBaiduMapView",
            creationParams: {"name": _name},
            creationParamsCodec: StandardMessageCodec(),
          );
  }
  /*
   * 获取2点距离
   */
  static Future<double> getDistance(
    FmMapPoint p1,
    FmMapPoint p2,
  ) async {
    try {
      return await _channel.invokeMethod("getDistance", {
        "latitude1": p1.latitude,
        "longitude1": p1.longitude,
        "latitude2": p2.latitude,
        "longitude2": p2.longitude,
      });
    } catch (e) {
      print(e);

      return 100;
    }
  }

  /*
   * 初始化并监听
   */
  void init({
    FmBaiduMessage onMessage,
    // 坐标状态开始改变时
    FmBaiduMapStatus onMapStatusChangeStart,
    // 坐标状态改变中
    FmBaiduMapStatus onMapStatusChange,
    // 坐标状态改变结束
    FmBaiduMapStatus onMapStatusChangeFinish,
  }) {
    _eventChannel = new MethodChannel(_name)
      ..setMethodCallHandler((MethodCall methodCall) {
        if (methodCall.method == "onMapStatusChange" &&
            onMapStatusChange != null) {
          onMapStatusChange(FmMapStatusInfo.create(methodCall.arguments));
        }
        if (methodCall.method == "onMapStatusChangeStart" &&
            onMapStatusChangeStart != null) {
          onMapStatusChangeStart(FmMapStatusInfo.create(methodCall.arguments));
        }
        if (methodCall.method == "onMapStatusChangeFinish" &&
            onMapStatusChangeFinish != null) {
          onMapStatusChangeFinish(FmMapStatusInfo.create(methodCall.arguments));
        }
        if (onMessage != null) {
          onMessage(methodCall.method, methodCall.arguments as Map);
        }
      });
  }

  /// 视图
  Widget get view => _map;
  /*
   * 添加一个标注
   */
  Future<FmMapOverlays> addOverlay(FmMapOverlays object) async {
    object.map = this;

    try {
      await _eventChannel.invokeMethod("addOverlays", {
        "objects": [object.toMap()],
      });
      return object;
    } catch (e) {
      print(e);

      return null;
    }
  }

  /*
   * 添加一组标注
   */
  Future<List<FmMapOverlays>> addOverlays(List<FmMapOverlays> objects) async {
    try {
      await _eventChannel.invokeMethod(
        "addOverlays",
        {"objects": FmMapOverlays.toList(objects)},
      );
      FmBaiduMap t = this;
      objects.forEach((it) {
        it.map = t;
      });
      return objects;
    } catch (e) {
      print(e);

      return null;
    }
  }

  /*
   * 更新一条记录
   */
  Future update(FmMapOverlays object) async {
    await updates([object]);
  }

  /*
   * 更新多条记录
   */
  Future updates(List<FmMapOverlays> objects) async {
    try {
      await _eventChannel.invokeMethod(
        "updateOverlays",
        {"objects": FmMapOverlays.toList(objects)},
      );
    } catch (e) {
      print(e);
    }
  }

  /*
   * 移除标注
   */
  Future removeOverlays({String id, String layer}) async {
    Map m = {};
    if (id != null) {
      m["id"] = id;
    }
    if (layer != null) {
      m["layer"] = layer;
    }

    try {
      await _eventChannel.invokeMethod("removeOverlays", m);
    } catch (e) {
      print(e);
    }
  }

  /*
   * 移除所有标注
   */
  Future clear() async {
    try {
      await _eventChannel.invokeMethod("clear");
    } catch (e) {
      print(e);
    }
  }

  /*
   * 设置标注的顺序
   */
  Future setOverlaysZIndex({String id, String layer, int zIndex}) async {
    Map m = {"zIndex": zIndex};
    if (id != null) {
      m["id"] = id;
    }
    if (layer != null) {
      m["layer"] = layer;
    }

    try {
      await _eventChannel.invokeMethod("setOverlaysIndex", m);
    } catch (e) {
      print(e);
    }
  }

  /*
   * 设置显示或隐藏
   */
  Future setOverlaysVisible({
    String id,
    String layer,
    bool visible = true,
  }) async {
    Map m = {"visible": visible};
    if (id != null) {
      m["id"] = id;
    }
    if (layer != null) {
      m["layer"] = layer;
    }

    try {
      await _eventChannel.invokeMethod("setOverlaysVisible", m);
    } catch (e) {
      print(e);
    }
  }

  /*
  * 设置地图定位点
  * @param obj
  * String name, 对象名称
  * double latitude, 经度
  * double longitude, 纬度
  * float direction, 方向
  * float accuracy 圈直径大小
  */
  Future setCurrentPoint(
    FmMapPoint point, {
    double direction = 0,
    double accuracy = 500,
  }) async {
    try {
      await _eventChannel.invokeMethod("setCurrentPoint", {
        "latitude": point.latitude,
        "longitude": point.longitude,
        "direction": direction,
        "accuracy": accuracy
      });
    } catch (e) {
      print(e);
    }
  }

  /*
  * 设置地图定位到指定点
  * @param obj
  * latitude
  * longitude
  * overlook
  * rotate
  * zoom
  */
  Future setCenter(
    FmMapPoint point, {
    double overlook = 1,
    double rotate = 360,
    double zoom = 0,
  }) async {
    try {
      await _eventChannel.invokeMethod("setCenter", {
        "latitude": point.latitude,
        "longitude": point.longitude,
        "overlook": overlook,
        "rotate": rotate,
        "zoom": zoom
      });
    } catch (e) {
      print(e);
    }
  }

  /*
   * String city 城市名称
   */
  Future addPolygonByName(
    String city, {
    bool showLine = false,
    int linewidth = 1,
    int lineColor = 0,
    bool showPolygon = true,
    int borderWidth = 1,
    int borderColor = 0,
    int fillColor = 0xAAFFFF00,
    bool fitScreen = false,
  }) async {
    await _eventChannel.invokeMethod(
      "addPolygonByName",
      {
        "name": city,
        "showLine": showLine,
        "linewidth": linewidth,
        "lineColor": lineColor,
        "showPolygon": showPolygon,
        "borderWidth": borderWidth,
        "borderColor": borderColor,
        "fillColor": fillColor,
        "fitScreen": fitScreen,
      },
    );
  }

  // public static final int MAP_TYPE_NORMAL = 1;
  // public static final int MAP_TYPE_SATELLITE = 2;
  // public static final int MAP_TYPE_NONE = 3;
  Future setMapType(int type) async {
    try {
      await _eventChannel.invokeMethod(
        "setMapType",
        {"type": type},
      );
    } catch (e) {
      print(e);
    }
  }
}
