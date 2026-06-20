import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import '../weather_service.dart';
import 'glass_card.dart';

class DailyForecast extends StatefulWidget {
  final List<DailyWeather> daily;
  final Function(DailyWeather) onSelected;

  const DailyForecast({super.key, required this.daily, required this.onSelected});

  @override
  State<DailyForecast> createState() => _DailyForecastState();
}

class _DailyForecastState extends State<DailyForecast> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.daily.length, (i) {
        final day = widget.daily[i];
        final isExpanded = _expanded == i;

        return GestureDetector(
          onTap: () => setState(() => _expanded = isExpanded ? null : i),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          day.day,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(day.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          day.description,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _RainChip(prob: day.rainProbability),
                      const SizedBox(width: 10),
                      Text(
                        '${day.tempMax.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${day.tempMin.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailStat(icon: '💨', label: 'Wind', value: '${day.windSpeed.toStringAsFixed(0)} m/s'),
                        _DetailStat(icon: '☀️', label: 'UV Index', value: '${day.uvIndex.toStringAsFixed(1)} (${WeatherService.uvLabel(day.uvIndex)})'),
                        _DetailStat(icon: '🌧️', label: 'Precip', value: '${day.precipitationSum.toStringAsFixed(1)} mm'),
                      ],
                    ),
                    if (day.sunrise != null && day.sunset != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DetailStat(
                            icon: '🌅',
                            label: 'Sunrise',
                            value: DateFormat('h:mm a').format(day.sunrise!),
                          ),
                          _DetailStat(
                            icon: '🌇',
                            label: 'Sunset',
                            value: DateFormat('h:mm a').format(day.sunset!),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RainChip extends StatelessWidget {
  final int prob;
  const _RainChip({required this.prob});

  @override
  Widget build(BuildContext context) {
    final color = prob > 60
        ? Colors.lightBlueAccent
        : prob > 30
            ? Colors.lightBlueAccent.withValues(alpha: 0.7)
            : Colors.white38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          '$prob%',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _DetailStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
