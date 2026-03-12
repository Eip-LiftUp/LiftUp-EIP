/// API Configuration
class ApiConfig {
  ApiConfig._();

  /// Backend base URL
  /// 
  /// For Android Emulator: use http://10.0.2.2:8080
  /// For Physical Device: use http://<YOUR_MACHINE_IP>:8080
  /// 
  /// Find your machine IP:
  /// - Windows: ipconfig (look for IPv4 on your WiFi/Ethernet adapter)
  /// - Linux: ip addr show (look for inet on your main network interface)
  /// 
  /// Your phone is on 10.73.189.188, so your machine should be on 10.73.189.x
  static const String baseUrl = 'http://10.73.189.87:8080'; // CHANGE THIS to your machine's IP
  
  /// Alternative: Auto-detect based on platform
  /// Uncomment this and remove the above line if you want auto-detection
  // static String get baseUrl {
  //   // Check if running on emulator or real device
  //   // For now, use the manual IP above
  //   return 'http://10.73.189.1:8080';
  // }
}
