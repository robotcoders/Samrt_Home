import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../kits/smart_home/smart_home_controller.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import '../config/app_config.dart';
import '../widgets/custom_numeric_keyboard.dart';

/// 智能家居屏幕
///
/// 显示智能家居套件的详细信息和控制界面，包括传感器数据显示和设备控制。
/// 界面分为左右两部分：左侧显示传感器数据，右侧提供设备控制功能。
class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  bool _isRefreshing = false;
  final _ipController = TextEditingController();

  final _connectionKey = GlobalKey<PopupMenuButtonState>();
  
  // 跟踪按钮按下状态
  final Map<String, bool> _buttonPressedStates = {};
  
  // 悬浮提示状态
  bool _showFloatingMessage = false;
  String _floatingMessageText = "The device is not connected yet";
  Color _floatingMessageColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    // 【IP地址管理优化】加载保存的IP地址，确保应用启动时显示上次使用的IP
    _loadSavedIp();

    
    final controller = Provider.of<SmartHomeController>(context, listen: false);

    // 监听初始化状态的改变
    controller.addListener(_onControllerUpdate);
    
    // 移除流订阅
  }

  void _onControllerUpdate() {
      final controller = Provider.of<SmartHomeController>(context, listen: false);
    // 当控制器首次初始化完成后，刷新一次数据
    if (controller.isInitialized) {
      // 移除监听器，避免重复调用
      controller.removeListener(_onControllerUpdate);
      if (mounted) {
      setState(() => _isRefreshing = true);
        controller.refreshData().then((_) {
          if (mounted) {
      setState(() => _isRefreshing = false);
          }
    });
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    Provider.of<SmartHomeController>(context, listen: false).removeListener(_onControllerUpdate);
    super.dispose();
  }

  // 【IP地址管理优化】加载保存的IP地址
  // 应用启动时自动加载上次保存的IP地址到输入框，实现IP地址持久化显示
  Future<void> _loadSavedIp() async {
    final ip = await AppConfig.getIpAddress(defaultIp: '192.168.x.x');
    _ipController.text = ip;
  }





  // 【IP地址管理优化】连接到ESP32 - 优化版本，确保IP地址保存和连接同步
  // 实现IP地址验证、保存、连接的完整流程，支持IP地址覆盖更新
  Future<void> _connect() async {
    Navigator.pop(context); // 关闭弹出菜单
    
    final ipAddress = _ipController.text.trim();
    if (ipAddress.isEmpty) return;

    // 验证IP地址格式，避免无效连接尝试
    final controller = Provider.of<SmartHomeController>(context, listen: false);
    if (!controller.validateIpAddress(ipAddress)) {
      _showErrorSnackBar('Invalid IP address format, please enter a valid IP address');
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      // 使用控制器的updateIpAddress方法，确保IP地址保存和连接同步
      await controller.updateIpAddress(ipAddress);
      
      // 检查连接结果并显示相应提示
      if (controller.isConnected) {
        _showConnectionSuccessMessage();
      } else {
        _showConnectionFailedMessage();
      }

    } catch (e) {
      // 连接过程中出现异常，显示失败提示
      _showConnectionFailedMessage();
    } finally {
      // 控制器状态的改变会触发UI更新，但这里的刷新状态需要手动管理
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
  
  // 断开连接
  void _disconnect() {
    final controller = Provider.of<SmartHomeController>(context, listen: false);
    controller.disconnect();
    Navigator.pop(context); // 关闭弹出菜单
  }

  // 处理自定义键盘输入
  void _onKeyboardInput(String key) {
    setState(() {
      _ipController.text += key;
    });
  }

  // 处理退格键
  void _onBackspace() {
    setState(() {
      if (_ipController.text.isNotEmpty) {
        _ipController.text = _ipController.text.substring(0, _ipController.text.length - 1);
      }
    });
  }

  // 显示错误 SnackBar
  void _showErrorSnackBar(String message) {
    // 确保在 build 方法之后执行，此时 context 是完全可用的
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          // 调整 margin 使其更窄，并离底部更远
          margin: const EdgeInsets.symmetric(horizontal: 250, vertical: 20),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 【性能优化】将listen设置为false，避免整个页面在notifyListeners时重构
    final controller = Provider.of<SmartHomeController>(context, listen: false);

    // 在 build 完成后检查并消费错误
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorMessage = controller.consumeError();
      if (errorMessage != null && mounted) {
        _showErrorSnackBar(errorMessage);
      }
    });

    // 移除初始化检查，直接显示智能家居界面
    
    // 【性能优化】将需要根据controller变化而更新的部分，交由Consumer来构建
    // 这样可以确保只有真正需要更新的Widget才会重构，而不是整个页面
    return Scaffold(
      backgroundColor: Colors.transparent, // 设置背景为透明
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Opacity(
              opacity: 0.8, // 调整背景透明度为80%
              child: Image.asset(
                'assets/images/home_background1.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 页面内容
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 【性能优化】操作栏使用Consumer来更新连接状态和刷新状态
                Consumer<SmartHomeController>(
                  builder: (context, controller, child) {
                    return _buildActionBar(context, controller, controller.isConnected);
                  }
                ),
                // 主内容区域
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // 这里依然可以使用无监听的controller来调用方法
                      setState(() => _isRefreshing = true);
                      await controller.refreshData();
                      setState(() => _isRefreshing = false);
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 【性能优化】主内容区域使用Consumer来构建
                        return Consumer<SmartHomeController>(
                          builder: (context, controller, child) {
                            final sensorData = controller.sensorData;
                            final isConnected = controller.isConnected;
                            if (constraints.maxWidth > 1000) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1000),
                                  child: _buildBody(sensorData, isConnected), // 移除controller参数
                                ),
                              );
                            }
                            return _buildBody(sensorData, isConnected); // 移除controller参数
                          }
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, SmartHomeController controller, bool isConnected) {
    return Padding(
      // 为操作栏本身添加内边距，使其不贴近屏幕边缘
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧占位，保持标题居中
          SizedBox(width: 48),
          // 居中的Smart Home标题
          Text(
            'Smart Home',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700), // 金黄色
            ),
          ),
          // 右侧按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isRefreshing
                  ? Container(
                      padding: const EdgeInsets.all(12.0),
                      width: 48,
                      height: 48,
                      child: const CircularProgressIndicator(strokeWidth: 2.5),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新数据',
                      visualDensity: VisualDensity.compact, // 使按钮更紧凑
                  onPressed: () async {
                    setState(() => _isRefreshing = true);
                    await controller.refreshData();
                    setState(() => _isRefreshing = false);
                  },
                ),
          PopupMenuButton(
            key: _connectionKey,
            tooltip: '连接',
                padding: EdgeInsets.zero, // 减少内边距使其更紧凑
            icon: Image.asset(
              isConnected 
                ? 'assets/images/button_backgrounds/wifi_connected.png'
                : 'assets/images/button_backgrounds/wifi_disconnect.png',
              width: 24,
              height: 24,
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              if (!isConnected) ...[
                PopupMenuItem(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  enabled: false,
                  child: SizedBox(
                    width: 400, // 增加宽度以确保4个按钮完整显示
                    child: TextField(
                      controller: _ipController,
                      readOnly: true, // 设置为只读，只能通过自定义键盘输入
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        hintText: '192.168.4.1',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  height: 180, // 由于按键高度减少，可以进一步减少整体高度
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  enabled: false,
                  child: SizedBox(
                    width: 600, // 扩大到红色框标示的区域大小
                    child: CustomNumericKeyboard(
                      onKeyPressed: _onKeyboardInput,
                      onBackspace: _onBackspace,
                      onConnect: (_isRefreshing || _ipController.text.trim().isEmpty) ? null : _connect,
                      showConnectButton: true,
                      isConnecting: _isRefreshing,
                    ),
                  ),
                ),
              ],
              if (isConnected) ...[
                PopupMenuItem(
                  enabled: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 40,
                  child: Text(
                    'Connected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
              ],
              if (isConnected) ...[
                PopupMenuItem(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _disconnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(40),
                      ),
                          child: Text('Disconnect', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
        ],
      ),
    );
  }

  /// 构建主内容区域
  Widget _buildBody(SensorData? sensorData, bool isConnected) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), // 将顶部间距从8减小到4
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：传感器数据显示
                Expanded(
                  flex: 10, // 传感器数据占10份
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.5),
                    child: _buildSensorDisplayPanel(sensorData, isConnected), // 移除controller参数
                  ),
                ),
                const SizedBox(width: 21),
                // 右侧：设备控制
                Expanded(
                  flex: 17, // 控制面板占17份（按钮区域8份+RGB区域9份）
                  child: _buildControlPanel(isConnected), // 移除controller参数
                ),
              ],
            ),
          ),
        ),
        // 悬浮提示消息
        if (_showFloatingMessage)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _floatingMessageColor.withOpacity(0.8),
                      _floatingMessageColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _floatingMessageColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  _floatingMessageText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// 显示悬浮提示消息
  void _showDisconnectedMessage() {
    _displayFloatingMessage("The device is not connected yet", Colors.orange);
  }
  
  void _showConnectionSuccessMessage() {
    _displayFloatingMessage("Device connected successfully!", Colors.green);
  }
  
  void _showConnectionFailedMessage() {
    _displayFloatingMessage("Connection failed, please check your settings", Colors.red);
  }
  
  void _displayFloatingMessage(String message, Color color) {
    setState(() {
      _showFloatingMessage = true;
      _floatingMessageText = message;
      _floatingMessageColor = color;
    });
    
    // 3秒后自动隐藏
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showFloatingMessage = false;
        });
      }
    });
  }

  /// 左侧 - 传感器数据显示面板 (新)
  Widget _buildSensorDisplayPanel(SensorData? data, bool isConnected) {
    return Consumer<SmartHomeController>(
      builder: (context, controller, child) {
        final rgbDevice = controller.devices.firstWhere((d) => d.type == DeviceType.rgb);
        final r = rgbDevice.additionalData?['r'] ?? 0;
        final g = rgbDevice.additionalData?['g'] ?? 0;
        final b = rgbDevice.additionalData?['b'] ?? 0;
        
        return GestureDetector(
          onTap: !isConnected ? _showDisconnectedMessage : null,
          child: AspectRatio(
            aspectRatio: 7 / 8, // 设置7:8的宽高比
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/button_backgrounds/sensor_data.png'),
                  fit: BoxFit.contain, // 改为contain确保图片完整显示且居中
                ),
              ),
              child: Card(
                color: Colors.transparent, // 设置卡片背景为透明
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.3), // 添加半透明黑色遮罩以提高文字可读性
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                        crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isConnected && data != null 
                            ? _buildSensorInfoRowWithColor("Light", '${data.light.toStringAsFixed(0)} %', data.light.toDouble())
                            : _buildSensorInfoRow("Light", "N/A"),
                          isConnected && data != null 
                            ? _buildSensorInfoRowWithIcon("Motion", data.pir 
                                ? 'assets/images/button_backgrounds/somebody.png' 
                                : 'assets/images/button_backgrounds/nobody.png')
                            : _buildSensorInfoRow("Motion", "N/A"),
                          isConnected && data != null 
                            ? _buildSensorInfoRowWithColor("Rain", '${data.raindrop} %', data.raindrop.toDouble())
                            : _buildSensorInfoRow("Rain", "N/A"),
                          isConnected && data != null 
                              ? _buildSensorInfoRowWithColor("Temperature", '${data.temperature.toStringAsFixed(1)} °C', data.temperature)
                              : _buildSensorInfoRow("Temperature", "N/A"),
                          isConnected && data != null 
                             ? _buildSensorInfoRowWithColor("Humidity", '${data.humidity.toStringAsFixed(1)} %', data.humidity)
                             : _buildSensorInfoRow("Humidity", "N/A"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  /// 右侧 - 控制面板 (修改为2行2列布局)
  Widget _buildControlPanel(bool isConnected) {
    // Consumer将提供最新的controller实例
    return Consumer<SmartHomeController>(
      builder: (context, controller, child) {
        final nonRgbDevices = controller.devices.where((d) => d.type != DeviceType.rgb).toList();
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 控制面板的左侧：2x2网格按钮
            Expanded(
              flex: 7, // 按钮区域占7份空间
              child: Column(
                children: [
                  // 第一行：两个按钮
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                          child: _buildSquareDeviceButton(nonRgbDevices.isNotEmpty ? nonRgbDevices[0] : null, controller, isConnected),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: _buildSquareDeviceButton(nonRgbDevices.length > 1 ? nonRgbDevices[1] : null, controller, isConnected),
                        ),
                      ),
                    ],
                  ),
                  // 第二行：两个按钮
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0, top: 8.0),
                          child: _buildSquareDeviceButton(nonRgbDevices.length > 2 ? nonRgbDevices[2] : null, controller, isConnected),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 8.0),
                          child: _buildSquareDeviceButton(nonRgbDevices.length > 3 ? nonRgbDevices[3] : null, controller, isConnected),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // 控制面板的右侧：RGB控制
            Expanded(
              flex: 10, // RGB区域占10份空间
              child: Padding(
                padding: const EdgeInsets.only(right: 0.5),
                child: _buildRGBSection(controller, isConnected),
              ),
            ),
          ],
        );
      }
    );
  }
  
  /// 创建传感器信息行 (新)
  Widget _buildSensorInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 改为居中对齐
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  /// 创建带图标的传感器信息行
  Widget _buildSensorInfoRowWithIcon(String label, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  /// 创建带颜色的传感器信息行
  Widget _buildSensorInfoRowWithColor(String label, String value, double numericValue) {
    Color valueColor;
    if (numericValue >= 0 && numericValue <= 30) {
      valueColor = Colors.green;
    } else if (numericValue > 30 && numericValue <= 60) {
      valueColor = Colors.yellow;
    } else {
      valueColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }


  

  
  /// 检查PNG资源是否存在
  Future<bool> _loadPngAsset(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      print('PNG资源加载失败: $assetPath - $e');
      return false;
    }
  }

  /// 获取按钮背景图片路径
  String _getButtonBackgroundPath(Device device, bool isPressed) {
    final deviceTypeName = device.type.toString().split('.').last;
    // 根据设备状态选择on或off图片
    final state = device.isOn ? 'on' : 'off';
    final path = 'assets/images/button_backgrounds/${deviceTypeName.substring(0, 1).toUpperCase()}${deviceTypeName.substring(1)}_$state.png';
    print('按钮背景路径: $path, 设备: ${device.name}, 按下: $isPressed, 开启: ${device.isOn}');
    return path;
  }

  /// 创建方形设备控制按钮 (2x2网格布局)
  Widget _buildSquareDeviceButton(Device? device, SmartHomeController controller, bool isConnected) {
    if (device == null) {
      // 如果设备为空，返回空的占位符
      return Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.1),
        ),
      );
    }
    
    final bool isEnabled = isConnected;
    final bool isPressed = _buttonPressedStates[device.id] ?? false;
    final String backgroundPath = _getButtonBackgroundPath(device, isPressed);
    
    return GestureDetector(
      onTapDown: isEnabled ? (_) {
        setState(() {
          _buttonPressedStates[device.id] = true;
        });
      } : null,
      onTapUp: (_) {
        setState(() {
          _buttonPressedStates[device.id] = false;
        });
        if (isEnabled) {
          controller.toggleDevice(device);
        } else {
          _showDisconnectedMessage();
        }
      },
      onTapCancel: () {
        setState(() {
          _buttonPressedStates[device.id] = false;
        });
      },
      child: AspectRatio(
        aspectRatio: 1.0, // 确保按钮是正方形
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
        child: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder(
                      future: _loadPngAsset(backgroundPath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Image.asset(
                            backgroundPath,
                            fit: BoxFit.fill,
                          );
                        } else {
                          // PNG加载失败或不存在时显示备用背景
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: device.isOn 
                                  ? [Colors.green.withOpacity(0.6), Colors.green.withOpacity(0.4)]
                                  : [Colors.grey.withOpacity(0.4), Colors.grey.withOpacity(0.2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: device.isOn ? Colors.green : Colors.grey,
                                width: 2,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ),
            ),
            // 内容已移除 - 只保留背景图片
          ],
        ),
      ),
      ),
    );
  }

  /// 创建矩形设备控制按钮 (保留备用)
  Widget _buildRectangularDeviceButton(Device device, SmartHomeController controller, bool isConnected) {
    final bool isEnabled = isConnected;
    final bool isPressed = _buttonPressedStates[device.id] ?? false;
    final String backgroundPath = _getButtonBackgroundPath(device, isPressed);
    
    return GestureDetector(
      onTapDown: isEnabled ? (_) {
        setState(() {
          _buttonPressedStates[device.id] = true;
        });
      } : null,
      onTapUp: isEnabled ? (_) {
        setState(() {
          _buttonPressedStates[device.id] = false;
        });
        controller.toggleDevice(device);
      } : null,
      onTapCancel: () {
        setState(() {
          _buttonPressedStates[device.id] = false;
        });
      },
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder(
                      future: _loadPngAsset(backgroundPath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Image.asset(
                            backgroundPath,
                            fit: BoxFit.fill,
                          );
                        } else {
                          // PNG加载失败或不存在时显示备用背景
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: device.isOn 
                                  ? [Colors.green.withOpacity(0.6), Colors.green.withOpacity(0.4)]
                                  : [Colors.grey.withOpacity(0.4), Colors.grey.withOpacity(0.2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: device.isOn ? Colors.green : Colors.grey,
                                width: 2,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ),
            ),
            // 内容已移除 - 只保留背景图片
          ],
        ),
      ),
    );
  }
  

  


  // --- 旧的构建方法，将被新的取代或整合 ---

  /// 原 _buildSensorSection，现在的数据直接显示在 _buildSensorDisplayPanel 中
  // Widget _buildSensorSection(SensorData? data, bool isConnected) { ... }

  /// 原 _buildDevicesSection，逻辑已移至 _buildControlPanel 和 _buildDeviceToggleButton
  // Widget _buildDevicesSection(SmartHomeController controller, bool isConnected) { ... }

  /// RGB 控制部分 (整合到统一容器)
  Widget _buildRGBSection(SmartHomeController controller, bool isConnected) {
    return Consumer<SmartHomeController>(
      builder: (context, controller, child) {
        final rgbDevice = controller.devices.firstWhere((d) => d.type == DeviceType.rgb);
        final r = rgbDevice.additionalData?['r'] as int? ?? 0;
        final g = rgbDevice.additionalData?['g'] as int? ?? 0;
        final b = rgbDevice.additionalData?['b'] as int? ?? 0;
        
        return Card(
          elevation: 4,
          color: Colors.white.withOpacity(0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 彩灯控制开关
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RGB Switch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    Switch(
                      value: rgbDevice.isOn,
                      onChanged: isConnected ? (_) => controller.toggleDevice(rgbDevice) : (_) => _showDisconnectedMessage(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // RGB滑块
                _buildColorSlider(
                  "R", r, Colors.red, isConnected,
                  (value) {
                    controller.updateLocalRgbColor(value.toInt(), g, b);
                  },
                  (value) {
                    if (rgbDevice.isOn) {
                      controller.setRgbColor(value.toInt(), g, b);
                    }
                  },
                ),
                const SizedBox(height: 1),
                _buildColorSlider(
                  "G", g, Colors.green, isConnected,
                  (value) {
                    controller.updateLocalRgbColor(r, value.toInt(), b);
                  },
                  (value) {
                    if (rgbDevice.isOn) {
                      controller.setRgbColor(r, value.toInt(), b);
                    }
                  },
                ),
                const SizedBox(height: 1),
                _buildColorSlider(
                  "B", b, Colors.blue, isConnected,
                  (value) {
                    controller.updateLocalRgbColor(r, g, value.toInt());
                  },
                  (value) {
                    if (rgbDevice.isOn) {
                      controller.setRgbColor(r, g, value.toInt());
                    }
                  },
                ),
                const SizedBox(height: 8),
                // RGB数值显示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildRgbValueDisplay(r, g, b),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  /// 构建颜色滑动条 (紧凑版)
  Widget _buildColorSlider(String label, int value, Color color, bool isEnabled, ValueChanged<double> onChanged, ValueChanged<double> onChangeEnd) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: isEnabled ? onChanged : (value) {
              _showDisconnectedMessage();
            },
            onChangeEnd: isEnabled ? onChangeEnd : (value) {
              _showDisconnectedMessage();
            },
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(value.toString(), style: const TextStyle(color: Colors.black, fontSize: 12), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  /// RGB数值显示 (新)
  Widget _buildRgbValueDisplay(int r, int g, int b) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('R: $r', style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
        Text('G: $g', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
        Text('B: $b', style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
      ],
    );
  }
}