import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';

class HourlyForecast extends StatelessWidget {
  final List<HourlyWeather> hourly;

  const HourlyForecast({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {

    final now = DateTime.now();

    // 🔹 Filter: show only hours from current time
    final filteredHourly = hourly.where((h) {
      return h.time.isAfter(now.subtract(const Duration(minutes: 30)));
    }).toList();

    return SizedBox(
      height: 110,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredHourly.length,

        itemBuilder: (context, index) {

          final h = filteredHourly[index];

          final time = DateFormat('hh a').format(h.time);

          // 🔹 Check if this is current hour
          final isCurrentHour =
              h.time.hour == now.hour && h.time.day == now.day;

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),

            decoration: BoxDecoration(
              color: isCurrentHour
                  ? Colors.orange.withOpacity(0.35)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: isCurrentHour
                  ? Border.all(color: Colors.orange, width: 2)
                  : null,
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  h.emoji,
                  style: const TextStyle(fontSize: 26),
                ),

                const SizedBox(height: 6),

                Text(
                  "${h.temp.toStringAsFixed(0)}°",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}