import 'package:flutter/material.dart';

/// 自定义数字键盘组件
/// 用于IP地址输入，提供0-9数字、小数点和退格功能
class CustomNumericKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onConnect;
  final bool showConnectButton;
  final bool isConnecting;

  const CustomNumericKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.onConnect,
    this.showConnectButton = false,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0), // 进一步减少容器内边距
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：1 2 3 4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 改为spaceEvenly以增加按键间距
            children: [
              _buildKeyButton('1'),
              _buildKeyButton('2'),
              _buildKeyButton('3'),
              _buildKeyButton('4'),
            ],
          ),
          const SizedBox(height: 12), // 增加行间距
          // 第二行：5 6 7 8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 改为spaceEvenly以增加按键间距
            children: [
              _buildKeyButton('5'),
              _buildKeyButton('6'),
              _buildKeyButton('7'),
              _buildKeyButton('8'),
            ],
          ),
          const SizedBox(height: 12), // 增加行间距
          // 第三行：9 0 . 退格
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 改为spaceEvenly以增加按键间距
            children: [
              _buildKeyButton('9'),
              _buildKeyButton('0'),
              _buildKeyButton('.'),
              _buildBackspaceButton(),
            ],
          ),
          if (showConnectButton) ...[
            const SizedBox(height: 12),
            // 连接按钮
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isConnecting ? null : onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyButton(String key) {
    return Expanded(
      child: Container(
        height: 45, // 增加高度，让按键更大
        margin: const EdgeInsets.symmetric(horizontal: 4.0), // 增加水平间距
        child: ElevatedButton(
          onPressed: () => onKeyPressed(key),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 18,  // 增大字体
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Expanded(
      child: Container(
        height: 45, // 增加高度，让按键更大
        margin: const EdgeInsets.symmetric(horizontal: 4.0), // 增加水平间距
        child: ElevatedButton(
          onPressed: onBackspace,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Icon(
            Icons.backspace,
            size: 20,  // 增大图标
          ),
        ),
      ),
    );
  }
}