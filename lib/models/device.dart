import 'package:flutter/material.dart';

/// 设备类型枚举
///
/// 定义智能家居系统中可控制的所有设备类型：
/// - door: 门
/// - window: 窗户
/// - led: LED灯
/// - fan: 风扇
/// - rgb: RGB灯带
enum DeviceType {
  door,
  window,
  led,
  fan,
  rgb
}

/// 设备模型类
///
/// 该类用于表示智能家居系统中的各种可控设备，
/// 包括门、窗户、LED灯、激光器和RGB灯带等。
class Device {
  /// 设备唯一标识符
  final String id;
  
  /// 设备名称
  final String name;
  
  /// 设备类型，对应DeviceType枚举
  final DeviceType type;
  
  /// 设备当前状态
  /// true表示开启，false表示关闭
  bool isOn;
  
  /// 设备是否可用
  final bool isEnabled;

  /// 附加数据，用于存储特定设备类型的额外信息
  /// 例如RGB灯带的颜色值
  Map<String, dynamic>? additionalData;

  /// 根据设备类型获取对应的图标
  IconData get icon {
    switch (type) {
      case DeviceType.door:
        return Icons.door_sliding;
      case DeviceType.window:
        return Icons.window;
      case DeviceType.led:
        return Icons.lightbulb_outline;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.rgb:
        return Icons.color_lens_outlined;
      default:
        return Icons.device_unknown;
    }
  }

  /// 构造函数，初始化设备信息
  ///
  /// [id] - 设备唯一标识符
  /// [name] - 设备名称
  /// [type] - 设备类型
  /// [isOn] - 设备初始状态，默认为关闭(false)
  /// [isEnabled] - 设备是否可用，默认为可用(true)
  /// [additionalData] - 设备相关的额外数据
  Device({
    required this.id,
    required this.name,
    required this.type,
    this.isOn = false,
    this.isEnabled = true,
    this.additionalData,
  });

  /// 将Device实例转换为JSON对象
  ///
  /// 返回包含所有设备数据的Map对象，可用于JSON序列化或本地存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'isOn': isOn,
      'isEnabled': isEnabled,
      'additionalData': additionalData,
    };
  }

  /// 从JSON对象创建Device实例的工厂构造函数
  ///
  /// [json] - 包含设备数据的JSON对象
  /// 
  /// 如果设备类型在JSON中不存在或无效，默认使用LED类型
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DeviceType.led,
      ),
      isOn: json['isOn'] ?? false,
      isEnabled: json['isEnabled'] ?? true,
      additionalData: json['additionalData'],
    );
  }
}