import 'package:flutter/material.dart';
import '../weather_model.dart';

class DailyForecast extends StatelessWidget {
  final List<DailyWeather> daily;
  final Function(DailyWeather) onSelected;

  const DailyForecast({
    super.key,
    required this.daily,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: daily.map((day) {

        return InkWell(

          onTap: () => onSelected(day),

          child: Container(
            margin: const EdgeInsets.only(bottom: 10),

            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [

                Expanded(
                  child: Text(
                    day.day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  day.emoji,
                  style: const TextStyle(fontSize: 24),
                ),

                const SizedBox(width: 20),

                Text(
                  "${day.tempMax.toStringAsFixed(0)}°",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  "${day.tempMin.toStringAsFixed(0)}°",
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

              ],
            ),
          ),
        );

      }).toList(),
    );
  }
}