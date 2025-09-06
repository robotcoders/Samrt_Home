import '../../services/connections/connection.dart';
import '../../models/sensor_data.dart';

/// 智能家居API
///
/// 提供与智能家居套件通信的API方法
class SmartHomeApi {
  final Connection _connection;

  SmartHomeApi(this._connection);

  /// 获取所有传感器数据
  Future<SensorData> getAllSensorData() async {
    try {
      final data = await _connection.getData('all');
      print('SmartHomeApi: 获取传感器数据成功 - $data');
      return SensorData.fromJson(data);
    } catch (e) {
      print('SmartHomeApi: 获取传感器数据失败 - $e');
      rethrow;
    }
  }

  /// 控制设备
  Future<bool> _controlDevice(String endpoint, bool state) async {
    try {
      print('SmartHomeApi: 控制 $endpoint - ${state ? '开启' : '关闭'}');
      final result =
          await _connection.sendCommand(endpoint, {'level': state ? 1 : 0});
      return result['success'] ?? false;
    } catch (e) {
      print('SmartHomeApi: 控制 $endpoint 失败 - $e');
      return false;
    }
  }

  /// 控制门
  Future<bool> controlDoor(bool isOpen) => _controlDevice('door', isOpen);

  /// 控制窗户
  Future<bool> controlWindow(bool isOpen) => _controlDevice('window', isOpen);

  /// 控制LED灯
  Future<bool> controlLED(bool isOn) => _controlDevice('led', isOn);

  /// 控制风扇
  Future<bool> controlFan(bool isOn) => _controlDevice('fan', isOn);

  /// 控制RGB灯带
  Future<bool> controlRGB(int r, int g, int b) async {
    try {
      print('SmartHomeApi: 控制RGB灯带 - R:$r G:$g B:$b');
      final result =
          await _connection.sendCommand('rgb', {'r': r, 'g': g, 'b': b});
      return result['success'] ?? false;
    } catch (e) {
      print('SmartHomeApi: 控制RGB灯带失败 - $e');
      return false;
    }
  }
}