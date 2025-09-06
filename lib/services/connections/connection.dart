/// 连接类型的枚举
///
/// 用于在ConnectionFactory中标识和创建不同类型的连接实例。
enum ConnectionType {
  httpLan, // 基于HTTP的局域网连接
  // future: bluetooth,
  // future: accessPoint,
}

/// 连接层抽象类 (接口)
///
/// 定义了所有连接方式必须遵守的“契约”。
/// 任何新的连接方式（如蓝牙、AP热点、MQTT等）都应该实现这个类。
/// 这样做可以将业务逻辑（Controller）与具体的连接实现完全解耦。
abstract class Connection {
  /// 连接的目标地址 (例如 IP地址, 蓝牙MAC地址)
  String get address;

  /// The IP address of the device, if applicable.
  String? get ipAddress;

  /// The port of the device, if applicable.
  int? get port;

  /// Loads the connection configuration for a specific kit.
  Future<void> loadConfig(String kitId);

  /// Tests the connection to the device.
  Future<bool> testConnection();

  /// Retrieves data from a specified endpoint.
  Future<Map<String, dynamic>> getData(String endpoint);

  /// Sends a command and data to a specified endpoint.
  Future<Map<String, dynamic>> sendCommand(
      String endpoint, Map<String, dynamic> data);
} 