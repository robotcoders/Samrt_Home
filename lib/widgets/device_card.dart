import 'package:flutter/material.dart';
import '../models/device.dart';

/// 设备控制卡片组件
///
/// 显示设备信息和控制开关。
class DeviceCard extends StatelessWidget {
  /// 要显示的设备对象
  final Device device;
  
  /// 切换设备状态的回调函数
  final VoidCallback? onToggle;
  
  /// 是否启用控制
  final bool isEnabled;
  
  const DeviceCard({
    Key? key,
    required this.device,
    required this.onToggle,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // 根据设备类型设置图标和颜色
    switch (device.type) {
      case DeviceType.door:
        icon = device.isOn ? Icons.meeting_room : Icons.door_front_door;
        color = Colors.brown;
        break;
      case DeviceType.window:
        icon = device.isOn ? Icons.window : Icons.sensor_window_outlined;
        color = Colors.blue;
        break;
      case DeviceType.led:
        icon = device.isOn ? Icons.lightbulb : Icons.lightbulb_outline;
        color = Colors.amber;
        break;
      case DeviceType.fan:
        icon = Icons.air;
        color = Colors.cyan;
        break;
      case DeviceType.rgb:
        icon = Icons.palette;
        color = Colors.purple;
        break;
    }
    
    // 如果禁用，使用灰色
    if (!isEnabled) {
      color = Colors.grey;
    }

    return Card(
      color: Colors.white.withOpacity(0.2), // 设置卡片背景颜色为半透明白色
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onToggle : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isEnabled && device.isOn ? Colors.white : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Text(
                device.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled && device.isOn ? Colors.white : Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnabled && device.isOn ? color.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEnabled ? (device.isOn ? 'ON' : 'OFF') : 'N/A',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isEnabled && device.isOn ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}