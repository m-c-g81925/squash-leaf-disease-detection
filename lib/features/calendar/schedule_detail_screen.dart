import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_schedule_screen.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const ScheduleDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Planting':
        return Icons.eco;
      case 'Watering':
        return Icons.water_drop;
      case 'Fertilizing':
        return Icons.grass;
      case 'Disease Scan':
        return Icons.camera_alt;
      case 'Pest Control':
        return Icons.shield;
      case 'Weeding':
        return Icons.yard;
      case 'Harvest':
        return Icons.agriculture;
      default:
        return Icons.push_pin;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Future<void> _deleteSchedule(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(documentId)
          .delete();
      if (context.mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete: ${error.message ?? error.code}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editSchedule(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(existingData: data),
      ),
    );

    if (result == null) return;
    final date = result['date'] as DateTime;

    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(documentId)
          .update({
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'dateKey': _dateKey(date),
        'task': result['task'],
        'type': result['type'] ?? 'Other',
        'time': result['time'],
        'growthStage': result['growthStage'],
        'priority': result['priority'],
        'notes': result['notes'],
        'event': result['event'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update: ${error.message ?? error.code}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = data['task']?.toString() ?? 'Schedule';
    final type = data['type']?.toString() ?? 'Other';
    final time = data['time']?.toString() ?? 'No time';
    final growthStage = data['growthStage']?.toString() ?? 'Not set';
    final priority = data['priority']?.toString() ?? 'Medium';
    final notes = data['notes']?.toString() ?? 'No notes';
    final timestamp = data['date'] as Timestamp?;
    final date = timestamp?.toDate();
    final priorityColor = _priorityColor(priority);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text('Schedule Details'),
        foregroundColor: const Color(0xFF1F2923),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _editSchedule(context),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () => _deleteSchedule(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _typeIcon(type),
                    color: const Color(0xFF179E43),
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF179E43),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _detailItem('Task', task),
              _detailItem('Date', _formatDate(date)),
              _detailItem('Time', time),
              _detailItem('Growth Stage', growthStage),
              const Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _detailItem('Notes', notes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? 'None' : value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
