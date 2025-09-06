import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/device.dart';
import '../../models/sensor_data.dart';
import '../../services/connections/connection_factory.dart';
import '../../services/connections/http_lan_connection.dart';
import 'smart_home_api.dart';

/// 智能家居控制器
///
/// 管理智能家居套件的状态和业务逻辑
class SmartHomeController with ChangeNotifier {
  // --- 私有成员 ---
  late Connection _connection; // 改为非final，以便重新初始化
  late SmartHomeApi _api;
  final String _kitId = 'smart_home'; // 定义本套件的唯一ID

  // 设备列表
  List<Device> _devices = [];

  // 传感器数据
  SensorData? _sensorData;

  // 状态标志
  bool _isInitialized = false; // 新增：初始化完成标志
  bool _isLoading = false; // 仅用于初始加载
  String? _error; // 重新启用
  Timer? _refreshTimer;
  int _refreshInterval = 500; // 默认0.5秒刷新一次（毫秒）
  bool _autoRefreshEnabled = true; // 默认启用自动刷新
  bool _isConnected = false; // 连接状态

  // --- Getters ---
  // 新增一个公共的 getter 以便外部访问Connection对象
  Connection get connection => _connection;
  List<Device> get devices => _devices;
  SensorData? get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  String? get error => _error; // 重新启用

  bool get autoRefreshEnabled => _autoRefreshEnabled;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized; // 新增

  // 新增: 消费错误，使其只显示一次
  String? consumeError() {
    final message = _error;
    _error = null;
    return message;
  }

  /// 获取当前IP地址
  String getCurrentIpAddress() {
    if (_connection is HttpLanConnection) {
      return (_connection as HttpLanConnection).getCurrentIpAddress();
    }
    return '';
  }

  /// 【IP地址管理优化】验证IP地址格式
  /// 使用正则表达式验证IPv4地址格式，确保用户输入的IP地址有效
  /// 支持0.0.0.0到255.255.255.255的完整IPv4地址范围
  bool validateIpAddress(String ipAddress) {
    if (ipAddress.isEmpty) return false;
    
    // 【IP地址管理优化】IPv4地址格式验证正则表达式
    final RegExp ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ipAddress);
  }

  /// 【IP地址管理优化】更新IP地址并重新连接
  /// 这是IP地址管理的核心方法，当ESP32设备IP变化时调用
  /// 实现IP地址验证、保存、连接测试的完整流程
  Future<void> updateIpAddress(String newIpAddress) async {
    // 【IP地址管理优化】首先验证IP地址格式，避免无效输入
    if (!validateIpAddress(newIpAddress)) {
      _error = 'Invalid IP address format, please enter a valid IP address';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 【IP地址管理优化】停止自动刷新，避免在连接切换过程中的干扰
      _stopPeriodicRefresh();
      
      // 【IP地址管理优化】先断开当前连接
      _isConnected = false;
      
      // 【IP地址管理优化】更新连接对象的IP地址并保存到本地存储
      if (_connection is HttpLanConnection) {
        await (_connection as HttpLanConnection).updateIpAddress(newIpAddress);
      }
      
      // 【IP地址管理优化】尝试连接新的IP地址
      final success = await _connection.testConnection();
      _isConnected = success;
      
      if (success) {
        _error = null;
        print('SmartHomeController: 成功更新IP地址并连接 - $newIpAddress');
        
        // 【IP地址管理优化】连接成功后立即刷新一次数据
        await refreshData();
        
        // 检查refreshData是否产生了任何错误（FormatException、SocketException、HttpException等）
        if (_error != null && (
            _error!.contains('Data format error') || 
            _error!.contains('Network connection failed') || 
            _error!.contains('Server request failed') ||
            _error!.contains('Connection timeout')
        )) {
          _isConnected = false;
          print('SmartHomeController: 数据获取错误，连接失败 - $_error');
        } else {
          // 【IP地址管理优化】重新启动自动刷新（如果启用）
          if (_autoRefreshEnabled && _refreshInterval > 0) {
            _startPeriodicRefresh();
          }
        }
      } else {
        _error = 'Unable to connect to the new IP address, please check if the device is online';
        print('SmartHomeController: 连接新IP地址失败 - $newIpAddress');
      }
    } catch (e) {
      _isConnected = false;
      _error = _getUserFriendlyErrorMessage(e);
      print('SmartHomeController: 更新IP地址异常 - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 构造函数和初始化 ---
  SmartHomeController() {
    _initDevices();
    _initController(); // 调用异步初始化
  }

  /// 初始化控制器，加载配置并创建API实例
  Future<void> _initController() async {
    try {
      // 使用工厂创建连接实例
      _connection = ConnectionFactory.create(ConnectionType.httpLan);
      
      // 异步加载此套件的配置，确保IP地址正确加载
      await _connection.loadConfig(_kitId);
      
      // 验证加载的IP地址格式
      final currentIp = getCurrentIpAddress();
      if (currentIp.isNotEmpty && !validateIpAddress(currentIp)) {
        print('SmartHomeController: 检测到无效的IP地址格式: $currentIp，使用默认IP地址');
        // 如果IP地址格式无效，重置为默认值
        if (_connection is HttpLanConnection) {
          await (_connection as HttpLanConnection).updateIpAddress('192.168.4.1');
        }
      }

      // 创建API实例
      _api = SmartHomeApi(_connection);

      print('SmartHomeController: 初始化完成，当前IP地址: ${getCurrentIpAddress()}');

      // 初始化完成后尝试连接并刷新数据
      await connect();

      // 如果启用了自动刷新，则启动定时器
      if (_autoRefreshEnabled && _isConnected) {
        _startPeriodicRefresh();
      }

    } catch (e) {
      _error = _getUserFriendlyErrorMessage(e);
      print('SmartHomeController: 初始化失败 - $e');
    } finally {
      // 标记为已初始化并通知UI
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 使用新设置重新连接
  Future<void> reconnectWithNewSettings() async {
    _isLoading = true;
    notifyListeners();

    // 重新初始化控制器以应用新设置
    await _initController();

    _isLoading = false;
    notifyListeners();
  }

  /// 断开连接
  void disconnect() {
    // 停止自动刷新
    _stopPeriodicRefresh();
    
    // 清除数据
    _sensorData = null;
    _error = null;
    _isConnected = false;
    
    // 重置设备状态
    for (var device in _devices) {
      device.isOn = false;
      if (device.type == DeviceType.rgb) {
        device.additionalData = {'r': 0, 'g': 0, 'b': 0};
      }
    }
    
    print('SmartHomeController: 已断开连接');
    notifyListeners();
  }
  
  /// 初始化设备列表
  void _initDevices() {
    _devices = [
      Device(id: 'door', name: '门', type: DeviceType.door),
      Device(id: 'window', name: '窗户', type: DeviceType.window),
      Device(id: 'led', name: 'LED灯', type: DeviceType.led),
      Device(id: 'fan', name: '风扇', type: DeviceType.fan),
      Device(id: 'rgb', name: 'RGB灯带', type: DeviceType.rgb, additionalData: {'r': 0, 'g': 0, 'b': 0}),
    ];
    notifyListeners();
  }
  

  
  /// 启动定时刷新
  void _startPeriodicRefresh() {
    // 取消现有的计时器
    _stopPeriodicRefresh();
    
    // 只有当刷新间隔大于0时才创建计时器
    if (_refreshInterval > 0) {
      // 创建新的计时器
      _refreshTimer = Timer.periodic(Duration(milliseconds: _refreshInterval), (_) {
        refreshData();
      });
      
      print('SmartHomeController: 启动定时刷新，间隔 $_refreshInterval 毫秒');
    }
  }
  
  /// 停止定时刷新
  void _stopPeriodicRefresh() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
      print('SmartHomeController: 停止定时刷新');
    }
  }
  
  /// 切换自动刷新
  void toggleAutoRefresh(bool enabled) {
    _autoRefreshEnabled = enabled;
    
    if (_autoRefreshEnabled && _refreshInterval > 0) {
      _startPeriodicRefresh();
    } else {
      _stopPeriodicRefresh();
    }
    
    print('SmartHomeController: 自动刷新 ${_autoRefreshEnabled ? "启用" : "禁用"}');
    notifyListeners();
  }
  
  /// 释放资源
  @override
  void dispose() {
    _stopPeriodicRefresh();
    // 移除流控制器关闭
    print('SmartHomeController: 释放资源');
    super.dispose();
  }
  
  /// 获取用户友好的错误信息
  String _getUserFriendlyErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    
    // 处理超时错误
    if (errorMessage.contains('TimeoutException')) {
      return 'Connection timeout, please check if ESP32 is powered on and connected to network';
    }
    
    // 处理网络连接错误
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Connection refused') ||
        errorMessage.contains('Network is unreachable')) {
      return 'Network connection failed, please check network settings';
    }
    
    // 处理HTTP错误
    if (errorMessage.contains('HttpException')) {
      return 'Server request failed, please check if ESP32 is running normally';
    }
    
    // 处理格式错误
    if (errorMessage.contains('FormatException')) {
      return 'Data format error, please check if the connected ESP32 device is correct';
    }
    
    // 默认错误信息
    return 'Connection failed, please check network connection and ESP32 status';
  }
  
  /// 刷新传感器数据
  Future<void> refreshData() async {
    if (!_isInitialized || !_isConnected) return; // 增加保护

    try {
      // 只有在初始加载时才设置全局加载状态
      if (_sensorData == null) {
        _isLoading = true;
        notifyListeners();
      }
      
      _sensorData = await _api.getAllSensorData();
      _error = null;
      
      print('SmartHomeController: 成功获取传感器数据 - $_sensorData');
    } catch (e) {
      _error = _getUserFriendlyErrorMessage(e); // 重新启用
      print('SmartHomeController: 获取传感器数据失败 - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 切换设备状态 (恢复为无节流的乐观更新)
  Future<void> toggleDevice(Device device) async {
    if (!_isInitialized || !_isConnected) return;

    final oldState = device.isOn;
    device.isOn = !oldState;
    notifyListeners();

    try {
      final newState = device.isOn;
      bool success = false;
      
      switch (device.type) {
        case DeviceType.door:
          success = await _api.controlDoor(newState);
          break;
        case DeviceType.window:
          success = await _api.controlWindow(newState);
          break;
        case DeviceType.led:
          success = await _api.controlLED(newState);
          break;
        case DeviceType.fan:
          success = await _api.controlFan(newState);
          break;
        case DeviceType.rgb:
          if (newState) { // 开灯（应用当前颜色）
            final r = device.additionalData?['r'] ?? 0;
            final g = device.additionalData?['g'] ?? 0;
            final b = device.additionalData?['b'] ?? 0;
            success = await _api.controlRGB(r, g, b);
          } else { // 关灯（发送关灯指令）
            success = await _api.controlRGB(0, 0, 0);
          }
          break;
      }

      if (!success) {
        throw Exception('API call returned false');
      }

      print('SmartHomeController: 成功切换设备状态 - ${device.name}');
      
    } catch (e) {
      device.isOn = oldState;
      final errorMessage = _getUserFriendlyErrorMessage(e);
      _error = errorMessage;
      notifyListeners();
      
      print('SmartHomeController: 控制设备异常，已回滚 - $e');
    }
  }

  /// 【性能优化】仅更新本地RGB颜色状态，不发送API请求
  ///
  /// 此方法用于在用户拖动颜色滑块时，实时更新UI显示，
  /// 但不向硬件发送数据，避免了高频请求导致的卡顿和硬件压力。
  void updateLocalRgbColor(int r, int g, int b) {
    if (!_isInitialized) return;

    final rgbDevice = _devices.firstWhere((d) => d.type == DeviceType.rgb);
    rgbDevice.additionalData?['r'] = r;
    rgbDevice.additionalData?['g'] = g;
    rgbDevice.additionalData?['b'] = b;
    
    notifyListeners();
  }

  /// 设置RGB颜色 (恢复为无节流的乐观更新)
  Future<void> setRgbColor(int r, int g, int b) async {
    if (!_isInitialized || !_isConnected) return;

    final rgbDevice = _devices.firstWhere((d) => d.type == DeviceType.rgb);
    
    final oldR = rgbDevice.additionalData?['r'] ?? 0;
    final oldG = rgbDevice.additionalData?['g'] ?? 0;
    final oldB = rgbDevice.additionalData?['b'] ?? 0;

    rgbDevice.additionalData?['r'] = r;
    rgbDevice.additionalData?['g'] = g;
    rgbDevice.additionalData?['b'] = b;
    notifyListeners();

    try {
      final success = await _api.controlRGB(r, g, b);
      if (!success) {
        throw Exception('Failed to set RGB color via API');
      }
      
      // 如果灯是灭的但是用户调整了颜色，就把它打开
      if (!rgbDevice.isOn && (r > 0 || g > 0 || b > 0)) {
        rgbDevice.isOn = true;
      }
      // 如果颜色被设置为全黑，就关掉灯
      else if (rgbDevice.isOn && r == 0 && g == 0 && b == 0) {
        rgbDevice.isOn = false;
      }

      _error = null;
      print('SmartHomeController: 成功设置RGB颜色 - R:$r G:$g B:$b');
      
    } catch (e) {
      rgbDevice.additionalData?['r'] = oldR;
      rgbDevice.additionalData?['g'] = oldG;
      rgbDevice.additionalData?['b'] = oldB;
      final errorMessage = _getUserFriendlyErrorMessage(e);
      _error = errorMessage;
      notifyListeners();
      
      print('SmartHomeController: 设置RGB颜色失败，已回滚 - $e');
    }
  }
  
  /// 测试连接并获取初始数据
  Future<void> connect() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _connection.testConnection();
      _isConnected = success;
      if (success) {
        _error = null;
        // 连接成功后立即刷新一次数据
        await refreshData();
        
        // 检查refreshData是否产生了任何错误（FormatException、SocketException、HttpException等）
        if (_error != null && (
            _error!.contains('Data format error') || 
            _error!.contains('Network connection failed') || 
            _error!.contains('Server request failed') ||
            _error!.contains('Connection timeout')
        )) {
          _isConnected = false;
          disconnect(); // 任何数据获取错误都视为连接失败
        }
      } else {
        _error = 'Connection test failed, please check network and IP settings';
        disconnect(); // 连接失败，进入断开状态
      }
    } catch (e) {
      _isConnected = false;
      _error = _getUserFriendlyErrorMessage(e);
      disconnect(); // 出现异常，进入断开状态
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}