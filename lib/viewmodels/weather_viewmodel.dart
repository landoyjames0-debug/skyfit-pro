import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/user_model.dart';
import '../repositories/weather_repository.dart';
import '../services/activity_engine.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _repo = WeatherRepository();
  WeatherModel? _weather;
  List<ActivitySuggestion> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _city = 'Manila';

  WeatherModel? get weather => _weather;
  List<ActivitySuggestion> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather(UserModel? user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _weather = await _repo.getWeather(_city);
      if (user != null) {
        _activities = ActivityEngine.suggest(
          weather: _weather!,
          user: user,
        );
      }
    } catch (e) {
      _errorMessage = 'Could not load weather. Check your connection.';
    }
    _isLoading = false;
    notifyListeners();
  }

  void setCity(String city) {
    _city = city;
    _repo.clearCache();
  }
}
