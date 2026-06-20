import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import '../weather_service.dart';

class DayDetailPage extends StatelessWidget {
  final DailyWeather dayWeather;

  const DayDetailPage({super.key, required this.dayWeather});

  @override
  Widget build(BuildContext context) {
    final sunrise = dayWeather.sunrise;
    final sunset = dayWeather.sunset;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          dayWeather.day,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(dayWeather.emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 8),
                Text(
                  '${dayWeather.tempMax.toStringAsFixed(0)}° / ${dayWeather.tempMin.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayWeather.description,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                _detailGrid(context, sunrise, sunset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailGrid(BuildContext context, DateTime? sunrise, DateTime? sunset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _row('🌧️', 'Rain Probability', '${dayWeather.rainProbability}%'),
              _row('💨', 'Max Wind', '${dayWeather.windSpeed.toStringAsFixed(0)} m/s'),
              _row('☀️', 'UV Index', '${dayWeather.uvIndex.toStringAsFixed(1)} — ${WeatherService.uvLabel(dayWeather.uvIndex)}'),
              _row('🌧️', 'Expected Precipitation', '${dayWeather.precipitationSum.toStringAsFixed(1)} mm'),
              if (sunrise != null)
                _row('🌅', 'Sunrise', DateFormat('h:mm a').format(sunrise)),
              if (sunset != null)
                _row('🌇', 'Sunset', DateFormat('h:mm a').format(sunset)),
              if (sunrise != null && sunset != null) ...[
                _row(
                  '⏳',
                  'Day Length',
                  () {
                    final d = sunset.difference(sunrise);
                    return '${d.inHours}h ${d.inMinutes % 60}m';
                  }(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
