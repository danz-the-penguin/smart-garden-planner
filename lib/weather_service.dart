import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "245e61086f10e261acfedd303c73261c"; 
  final String city = "Kota Kinabalu"; 

  Future<Map<String, dynamic>> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final condition = data['weather'][0]['main'];
        final double rawTemp = (data['main']['temp'] as num).toDouble();
        final int humidity = data['main']['humidity'] as int;

        // --- NEW: RAIN EXTRACTION LOGIC (Matches Data Dictionary) ---
        double rainMm = 0.0;
        if (data.containsKey('rain')) {
          // OpenWeather uses '1h' or '3h' keys; prioritizing the most recent hour
          rainMm = (data['rain']['1h'] ?? data['rain']['3h'] ?? 0.0).toDouble();
        }

        return {
          'temp': rawTemp.toStringAsFixed(1),
          'temp_c': rawTemp, // raw double for database storage
          'condition': condition,
          'rain_mm': rainMm, // numerical value for Module 4 triggers
          'humidity': humidity,
          'icon': _getIcon(condition),
          'advice': _getAdvice(condition, rainMm),
          'raw_json': response.body, // stored for audit purposes
        };
      }
    } catch (e) {
      print("Weather API Error: $e");
    }
    // Updated Fallback for data consistency
    return {
      'temp': '--', 
      'temp_c': 0.0,
      'condition': 'Offline', 
      'rain_mm': 0.0, 
      'humidity': 0,
      'icon': '☁️', 
      'advice': 'Check connection.'
    };
  }

  String _getIcon(String condition) {
    if (condition.contains('Rain')) return '🌧️';
    if (condition.contains('Cloud')) return '☁️';
    return '☀️';
  }

  // UPDATED: Advice now reacts to numerical rain data
  String _getAdvice(String condition, double rain) {
    if (rain > 5.0) return "Heavy rain detected ($rain mm). Postpone irrigation and fertilization.";
    if (condition.contains('Rain')) return "High humidity detected. Watch for fungal leaf spots.";
    return "Weather is stable. Ideal for fertilizer application.";
  }
}
