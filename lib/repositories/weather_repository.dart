import '../models/weather_model.dart';
import '../services/api_service.dart';

class WeatherRepository {
  final ApiService _api = ApiService();
  WeatherModel? _cachedWeather;
  DateTime? _cacheTime;
  String? _cachedKey; // tracks what was last fetched
  static const _cacheDuration = Duration(minutes: 15);

  bool _isCacheValid(String key) =>
      _cachedWeather != null &&
      _cacheTime != null &&
      _cachedKey == key &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  Future<WeatherModel> getWeather(String city) async {
    final key = 'city:$city';
    if (_isCacheValid(key)) return _cachedWeather!;
    final weather = await _api.fetchWeatherByCity(city);
    _setCache(weather, key);
    return weather;
  }

  Future<WeatherModel> getWeatherByCoords(double lat, double lon) async {
    final key = 'coords:$lat,$lon';
    if (_isCacheValid(key)) return _cachedWeather!;
    final weather = await _api.fetchWeatherByCoords(lat, lon);
    _setCache(weather, key);
    return weather;
  }

  void _setCache(WeatherModel weather, String key) {
    _cachedWeather = weather;
    _cacheTime = DateTime.now();
    _cachedKey = key;
  }

  void clearCache() {
    _cachedWeather = null;
    _cacheTime = null;
    _cachedKey = null;
  }
}
