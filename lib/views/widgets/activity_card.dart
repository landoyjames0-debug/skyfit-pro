import 'package:flutter/material.dart';
import '../../models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  const ActivityCard({super.key, required this.activity});

  Color _intensityColor(String intensity) {
    switch (intensity) {
      case 'High':
        return const Color(0xFFE53935);
      case 'Medium':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(activity.emoji, style: const TextStyle(fontSize: 36)),
        title: Text(activity.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(activity.intensity,
                      style: TextStyle(
                          color: _intensityColor(activity.intensity),
                          fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.timer_outlined, size: 16),
                Text(' ${activity.durationMinutes} min'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening: ${activity.title} video...')),
          ),
        ),
      ),
    );
  }
}
