import 'package:flutter/material.dart';
import '../weather_model.dart';

class DayDetailPage extends StatelessWidget {
  final DailyWeather dayWeather;

  const DayDetailPage({super.key, required this.dayWeather});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${dayWeather.day} Forecast'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayWeather.day,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  dayWeather.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  '${dayWeather.tempMin.toStringAsFixed(1)}°C - ${dayWeather.tempMax.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Min / Max Temperature',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}