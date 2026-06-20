import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class HourlyForecast extends StatelessWidget {
  final List<HourlyWeather> hourly;

  const HourlyForecast({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = hourly
        .where((h) => h.time.isAfter(now.subtract(const Duration(minutes: 30))))
        .take(24)
        .toList();

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final h = items[index];
          final isCurrent = h.time.hour == now.hour && h.time.day == now.day;
          final time = index == 0 && isCurrent
              ? 'Now'
              : DateFormat('ha').format(h.time);

          return Padding(
            padding: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
            child: GlassCard(
              opacity: isCurrent ? 0.28 : 0.13,
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(h.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 2),
                  Text(
                    '${h.temp.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MiniBadge(
                    icon: Icons.water_drop,
                    value: '${h.rainProbability}%',
                    color: Colors.lightBlueAccent,
                  ),
                  const SizedBox(height: 2),
                  _MiniBadge(
                    icon: Icons.air,
                    value: h.windSpeed.toStringAsFixed(0),
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}
