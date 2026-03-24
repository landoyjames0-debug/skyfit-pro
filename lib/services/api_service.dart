import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/env_config.dart';

class ApiService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const _timeout = Duration(seconds: 10);

  Future<WeatherModel> fetchWeatherByCity(String city) async {
    final uri = Uri.parse(
      '$_baseUrl/weather?q=$city&appid=${EnvConfig.openWeatherApiKey}&units=metric',
    );
    try {
      final response = await http.get(uri).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<WeatherModel> fetchWeatherByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&appid=${EnvConfig.openWeatherApiKey}&units=metric',
    );
    try {
      final response = await http.get(uri).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  WeatherModel _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return WeatherModel.fromJson(jsonDecode(response.body));
      case 401:
        throw Exception('Invalid API key.');
      case 404:
        throw Exception('City not found.');
      case 429:
        throw Exception('API rate limit exceeded.');
      default:
        throw Exception('Unexpected error: ${response.statusCode}');
    }
  }
}
