import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import 'connection.dart';

/// HTTP局域网连接实现类
///
/// 实现了[Connection]接口，用于通过HTTP协议在局域网（LAN）中与设备通信。
///
/// 主要职责：
/// - 专注于IP地址管理，简化配置逻辑
/// - 实现数据的GET和POST请求
/// - 提供连接测试功能
/// - 支持动态IP地址更新
class HttpLanConnection implements Connection {
  String _ipAddress = '192.168.4.1'; // 默认IP地址
  static const int _defaultPort = 80; // 固定端口，简化配置
  final Duration _timeout = const Duration(seconds: 5); // 超时设置
  
  // SharedPreferences存储键
  static const String _ipAddressKey = 'ip_address_smart_home';

  // 简化地址获取，固定使用80端口
  @override
  String get address => 'http://$_ipAddress:$_defaultPort';

  @override
  String get ipAddress => _ipAddress;
  @override
  int get port => _defaultPort;
  String get baseUrl => 'http://$_ipAddress:$_defaultPort';

  /// 构造函数 - 保持简单
  HttpLanConnection();

  /// 动态更新IP地址 - 简化版本
  /// 
  /// 【IP地址管理优化】核心方法，允许在运行时更新IP地址并保存到本地存储
  /// 简化逻辑：使用统一的存储键，不再依赖kitId
  /// 这是IP地址管理功能的核心实现，支持用户在ESP32设备IP变化时快速更新
  /// [newIpAddress] - 新的IP地址
  Future<void> updateIpAddress(String newIpAddress) async {
    try {
      // 【IP地址管理优化】立即更新内存中的IP地址
      _ipAddress = newIpAddress;
      // 【IP地址管理优化】持久化保存到SharedPreferences，确保应用重启后能加载
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipAddressKey, newIpAddress);
      debugPrint('HttpLanConnection: 动态更新IP地址 - $newIpAddress');
    } catch (e) {
      debugPrint('HttpLanConnection: 更新IP地址失败 - $e');
      rethrow;
    }
  }



  /// 获取当前IP地址
  String getCurrentIpAddress() => _ipAddress;

  /// 加载配置 - 简化版，只加载IP地址
  /// 【IP地址管理优化】移除对kitId的依赖，使用统一的存储键
  /// 应用启动时自动加载上次保存的IP地址，实现IP地址持久化
  @override
  Future<void> loadConfig(String kitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 【IP地址管理优化】从SharedPreferences加载保存的IP地址，如果没有则使用默认值
      _ipAddress = prefs.getString(_ipAddressKey) ?? _ipAddress;
      debugPrint('HttpLanConnection: 加载IP地址 - $_ipAddress');
    } catch (e) {
      debugPrint('HttpLanConnection: 加载配置失败 - $e');
      rethrow;
    }
  }

  /// 保存IP地址配置 - 简化版，只保存IP地址
  /// 移除对kitId的依赖，使用统一的存储键
  Future<void> saveConfig(String ipAddress) async {
    try {
      _ipAddress = ipAddress;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ipAddressKey, ipAddress);
      debugPrint('HttpLanConnection: 保存IP地址 - $ipAddress');
    } catch (e) {
      debugPrint('HttpLanConnection: 保存IP地址失败 - $e');
      rethrow;
    }
  }

  /// 测试连接 - 实现自Connection接口
  @override
  Future<bool> testConnection() async {
    debugPrint('HttpLanConnection: 测试连接到 $address/all');
    try {
      final response = await http.get(Uri.parse(address)).timeout(_timeout);
      final isConnected = response.statusCode == 200;
      debugPrint('HttpLanConnection: 连接测试 ${isConnected ? '成功' : '失败'}');
      return isConnected;
    } catch (e) {
      debugPrint('HttpLanConnection: 连接测试异常 - $e');
      return false;
    }
  }

  /// 发送GET请求 - 实现自Connection接口
  @override
  Future<Map<String, dynamic>> getData(String endpoint) async {
    final url = Uri.parse('$address${endpoint.isEmpty ? '' : '/$endpoint'}');
    var client = http.Client(); // 为本次请求创建新实例

    try {
      debugPrint('HttpLanConnection: 发送GET请求 - $url');
      final response = await client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      debugPrint('HttpLanConnection: 收到响应 - 状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          return {'success': true}; // 响应体为空，但请求成功
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('HttpLanConnection: GET请求失败 - $e');
      rethrow;
    } finally {
      client.close(); // 确保客户端被关闭
    }
  }

  /// 发送POST请求 - 实现自Connection接口
  @override
  Future<Map<String, dynamic>> sendCommand(
      String endpoint, Map<String, dynamic> data) async {
    // 根据ESP32的实现，我们的POST请求应该将参数作为查询参数附加到URL上
    final url = Uri.parse('$address/$endpoint').replace(queryParameters: {
      'level': data['level']?.toString(),
      'r': data['r']?.toString(),
      'g': data['g']?.toString(),
      'b': data['b']?.toString(),
    });
    var client = http.Client(); // 为本次请求创建新实例

    try {
      debugPrint('HttpLanConnection: 发送POST(GET)请求 - $url');
      final response = await client.post(url).timeout(_timeout);

      debugPrint('HttpLanConnection: 收到响应 - 状态码: ${response.statusCode}');

      // 只要HTTP状态码是200，就认为成功，并返回一个固定的成功响应
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        // 如果状态码不为200，则抛出异常
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      // 捕获并重新抛出任何异常（例如超时）
      debugPrint('HttpLanConnection: POST请求失败 - $e\n${e.toString()}');
      rethrow;
    } finally {
      client.close(); // 确保客户端被关闭
    }
  }
}