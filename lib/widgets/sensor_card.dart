import 'package:flutter/material.dart';

/// 传感器数据卡片组件
///
/// 显示单个传感器的数据，包括图标、标题和值。
class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const SensorCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // 恢复阴影
      color: Colors.white, // 设置卡片背景颜色为白色
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color, // 将图标颜色恢复为传入的颜色
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87, // 将标题颜色调整为深灰色
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color, // 将数值颜色恢复为传入的颜色
              ),
            ),
          ],
        ),
      ),
    );
  }
} 