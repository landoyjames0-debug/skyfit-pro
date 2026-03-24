import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../repositories/weather_repository.dart';
import '../services/activity_engine.dart';

// M3/M5 - WeatherViewModel: fetches weather and generates health suggestions
class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _repo = WeatherRepository();

  WeatherModel? _weather;
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _city = 'Manila';

  WeatherModel? get weather => _weather;
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather(UserModel? user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _weather = await _repo.getWeather(_city);
      if (user != null) {
        // FIX: Use ActivityEngine instead of inline logic so all
        // weather classes (thunderstorm, mist, extreme heat, etc.) work
        final suggestions = ActivityEngine.suggest(
          weather: _weather!,
          user: user,
        );
        // Convert ActivitySuggestion → ActivityModel
        _activities = suggestions
            .map((s) => ActivityModel(
                  title: s.name,
                  description: s.description,
                  emoji: s.emoji,
                  intensity: s.intensity,
                  videoUrl: s.videoAsset ?? '',
                  durationMinutes: s.durationMinutes,
                ))
            .toList();
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
