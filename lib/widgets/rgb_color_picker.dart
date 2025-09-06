import 'package:flutter/material.dart';

/// RGB颜色选择器组件
///
/// 允许用户选择RGB颜色，并通过回调函数返回所选颜色。
class RGBColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  
  const RGBColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<RGBColorPicker> createState() => _RGBColorPickerState();
}

class _RGBColorPickerState extends State<RGBColorPicker> {
  late int r;
  late int g;
  late int b;
  List<Color> _presetColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];
  
  @override
  void initState() {
    super.initState();
    // 初始化RGB值
    r = widget.initialColor.red;
    g = widget.initialColor.green;
    b = widget.initialColor.blue;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 颜色预览
        Row(
          children: [
        Container(
              width: 60,
              height: 60,
          decoration: BoxDecoration(
                color: Color.fromRGBO(r, g, b, 1.0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R: $r, G: $g, B: $b',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 预设颜色
        const Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((color) {
            return InkWell(
              onTap: () {
            setState(() {
                  r = color.red;
                  g = color.green;
                  b = color.blue;
                });
                _notifyColorChanged();
          },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (r == color.red && g == color.green && b == color.blue)
                        ? Colors.white 
                        : Colors.grey.shade300,
                    width: (r == color.red && g == color.green && b == color.blue) ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // RGB滑块
        _buildColorSlider('R', r, Colors.red, (value) {
          setState(() => r = value.toInt());
          _notifyColorChanged();
        }),
        _buildColorSlider('G', g, Colors.green, (value) {
          setState(() => g = value.toInt());
          _notifyColorChanged();
        }),
        _buildColorSlider('B', b, Colors.blue, (value) {
          setState(() => b = value.toInt());
          _notifyColorChanged();
        }),
      ],
    );
  }
  
  /// 构建颜色滑动条
  Widget _buildColorSlider(String label, int value, Color color, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.2),
                thumbColor: Colors.white,
                overlayColor: color.withOpacity(0.3),
              ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _notifyColorChanged() {
    widget.onColorChanged(Color.fromRGBO(r, g, b, 1.0));
  }
}