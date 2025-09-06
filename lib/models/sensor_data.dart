/// 传感器数据模型类
///
/// 该类用于存储并表示来自ESP32的各种传感器数据，
/// 包括温度、湿度、光照强度、人体感应、雨滴检测等数据。
class SensorData {
  /// 温度值，单位为摄氏度
  final double temperature;
  
  /// 湿度值，单位为百分比（0-100%）
  final double humidity;
  
  /// 光照强度，数值范围通常为0-4095
  /// 数值越小表示光照越强
  final int light;
  
  /// 人体感应状态
  /// true表示检测到人体，false表示未检测到
  final bool pir;
  
  /// 雨滴检测值，单位为百分比（0-100%）
  /// 数值范围为0-100，表示雨量的百分比
  final int raindrop;

  /// 构造函数，初始化所有传感器数据
  ///
  /// [temperature] - 温度值（摄氏度）
  /// [humidity] - 湿度值（百分比）
  /// [light] - 光照强度值
  /// [pir] - 人体感应状态
  /// [raindrop] - 雨滴检测值（百分比）
  SensorData({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.pir,
    required this.raindrop,
  });

  /// 从JSON对象创建SensorData实例的工厂构造函数
  ///
  /// [json] - 包含传感器数据的JSON对象，ESP32返回的格式为：
  /// {
  ///   "Temperature": 25.5,
  ///   "Humidity": 60.0,
  ///   "Photoresistor": 500,
  ///   "Human": 1,
  ///   "Raindrop": 0
  /// }
  /// 
  /// ESP32通常以0/1表示布尔值，在这里会转换成true/false
  factory SensorData.fromJson(Map<String, dynamic> json) {
    // 安全解析函数，避免格式错误导致异常
    double parseDoubleValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        print('解析错误: $e, 值: $value');
        return 0.0;
      }
    }
    
    int parseIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      try {
        return int.parse(value.toString());
      } catch (e) {
        print('解析错误: $e, 值: $value');
        return 0;
      }
    }
    
    bool parseBoolValue(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true';
      }
      return false;
    }
    
    // 处理ESP32返回的字段名与Flutter应用中字段名的差异
    return SensorData(
      temperature: parseDoubleValue(json['Temperature'] ?? json['temperature']),
      humidity: parseDoubleValue(json['Humidity'] ?? json['humidity']),
      light: parseIntValue(json['Photoresistor'] ?? json['light']),
      pir: parseBoolValue(json['Human'] ?? json['pir']),
      raindrop: parseIntValue(json['Raindrop'] ?? json['raindrop']),
    );
  }

  /// 创建一个包含默认值的SensorData实例
  ///
  /// 当无法从ESP32获取数据时，可以使用此方法创建一个默认值的实例
  factory SensorData.defaultValues() {
    return SensorData(
      temperature: 0,
      humidity: 0,
      light: 0,
      pir: false,
      raindrop: 0,
    );
  }

  /// 将SensorData实例转换为JSON对象
  ///
  /// 返回包含所有传感器数据的Map对象，可用于JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'pir': pir ? 1 : 0,
      'raindrop': raindrop,
    };
  }
  
  @override
  String toString() {
    return 'SensorData(温度: $temperature°C, 湿度: $humidity%, 光照: $light, 人体: ${pir ? "有" : "无"}, 雨滴: $raindrop%)';
  }
}