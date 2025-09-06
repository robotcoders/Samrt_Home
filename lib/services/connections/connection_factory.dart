export 'connection.dart';
import 'connection.dart';
import 'http_lan_connection.dart';

/// 连接工厂类
///
/// 使用工厂模式，根据指定的[ConnectionType]创建并返回一个具体的[Connection]实例。
///
/// 这种设计的核心优势在于：
/// 1. **中心化管理**：所有连接实例的创建逻辑都集中在此处，便于维护。
/// 2. **简化使用者代码**：调用者（如Controller）无需关心具体连接类的实现细节，
///    只需通过`ConnectionFactory.create(type)`即可获取一个可用的连接对象。
/// 3. **易于扩展**：当需要支持新的连接方式时（例如蓝牙），只需：
///    a. 创建一个新的`BluetoothConnection`类并实现`Connection`接口。
///    b. 在下面的`create`方法的`switch`语句中添加一个新的`case`分支即可。
class ConnectionFactory {
  /// 根据连接类型创建具体的连接实例
  ///
  /// [type] - 要创建的连接类型
  /// 返回一个实现了[Connection]接口的实例。
  static Connection create(ConnectionType type) {
    switch (type) {
      case ConnectionType.httpLan:
        return HttpLanConnection();
      // 在这里可以添加其他连接类型的实现
      // case ConnectionType.httpAp:
      //   return HttpApConnection();
      // case ConnectionType.bluetooth:
      //   return BluetoothConnection();
      default:
        throw ArgumentError('不支持的连接类型: $type');
    }
  }
} 