import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onTap,
  });

  Color _iconBackground(String event) {
    switch (event.toLowerCase()) {
      case 'watering':
        return Colors.blue.shade50;
      case 'fertilizing':
        return Colors.orange.shade50;
      case 'disease scan':
        return Colors.red.shade50;
      case 'pest control':
        return Colors.deepOrange.shade50;
      case 'harvest':
        return Colors.amber.shade50;
      case 'weeding':
        return Colors.brown.shade50;
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  IconData _icon(String event) {
    switch (event.toLowerCase()) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizing':
        return Icons.eco;
      case 'disease scan':
        return Icons.health_and_safety;
      case 'pest control':
        return Icons.bug_report;
      case 'harvest':
        return Icons.agriculture;
      case 'weeding':
        return Icons.grass;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String event =
        schedule['event']?.toString() ??
        schedule['task']?.toString() ??
        'Schedule';

    final String time =
        schedule['time']?.toString() ?? 'No time';

    final String priority =
        schedule['priority']?.toString() ?? 'Medium';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconBackground(event),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _icon(event),
                color: const Color(0xFF179E43),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    event,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$time • Priority: $priority',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}