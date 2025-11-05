import 'package:flutter/material.dart';
import '../weather_model.dart';

class DailyForecast extends StatelessWidget {
  final List<DailyWeather> daily;
  final void Function(DailyWeather) onSelected;

  const DailyForecast({
    super.key,
    required this.daily,
    required this.onSelected,
  });

  @override
Widget build(BuildContext context) {
  final today = DateTime.now();

  // Filter out today based on date (make sure day.date is a DateTime)
  final forecastDays = daily.where((day) {
    return !(day.date.day == today.day &&
             day.date.month == today.month &&
             day.date.year == today.year);
  }).toList();

  return Column(
    children: forecastDays.map((day) {
      return GestureDetector(
        onTap: () => onSelected(day),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day.day, style: const TextStyle(fontSize: 16)),
                Text('${day.emoji}  ${day.tempMin.toStringAsFixed(1)}° / ${day.tempMax.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
}