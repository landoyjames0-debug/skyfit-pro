class WeatherModel {
  final double temperature;
  final double humidity;
  final String condition;
  final String description;
  final String cityName;
  final String iconCode;

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.cityName,
    required this.iconCode,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    return WeatherModel(
      temperature: (main['temp'] as num).toDouble(),
      humidity: (main['humidity'] as num).toDouble(),
      condition: weather['main'] as String,
      description: weather['description'] as String,
      cityName: json['name'] as String,
      iconCode: weather['icon'] as String,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  bool get isExtremeHeat => temperature > 38; // fixed typo
  bool get isClear => condition == 'Clear';
  bool get isRainy => condition == 'Rain' || condition == 'Drizzle';
  bool get isSnowy => condition == 'Snow';
}
