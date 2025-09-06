import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置类
///
/// 负责管理智能家居应用的配置信息，包括IP地址和端口设置。
/// 使用SharedPreferences进行本地持久化存储，保证应用重启后配置不丢失。
class AppConfig {
  /// 存储IP地址的键名
  static const String _ipAddressKey = 'ip_address';
  
  /// 存储端口的键名
  static const String _portKey = 'port';

  /// 获取IP地址
  ///
  /// [defaultIp] - 如果未设置，返回的默认IP地址
  static Future<String> getIpAddress({String defaultIp = '192.168.4.1'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipAddressKey) ?? defaultIp;
  }

  /// 设置IP地址
  ///
  /// [ipAddress] - 要设置的IP地址
  static Future<void> setIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipAddressKey, ipAddress);
  }

  /// 获取端口
  ///
  /// [defaultPort] - 如果未设置，返回的默认端口号
  static Future<int> getPort({int defaultPort = 80}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? defaultPort;
  }

  /// 设置端口
  ///
  /// [port] - 要设置的端口号
  static Future<void> setPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_portKey, port);
  }
}