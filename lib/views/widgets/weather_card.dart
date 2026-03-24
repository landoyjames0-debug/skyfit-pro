import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherCard extends StatelessWidget {
  final WeatherModel weather;
  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Image.network(weather.iconUrl, width: 64, height: 64,
                errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, size: 64)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weather.cityName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${weather.temperature.toStringAsFixed(1)}°C • ${weather.description}',
                      style: Theme.of(context).textTheme.bodyLarge),
                  Text('Humidity: ${weather.humidity.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
