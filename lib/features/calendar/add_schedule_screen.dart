import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final DateTime? initialDate;

  const AddScheduleScreen({
    super.key,
    this.existingData,
    this.initialDate,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final taskController = TextEditingController();
  final notesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String scheduleType = 'Planting';
  String growthStage = 'Seedling';
  String priority = 'Medium';
  bool _isSaving = false;

  static const scheduleTypes = [
    'Planting',
    'Watering',
    'Fertilizing',
    'Disease Scan',
    'Pest Control',
    'Weeding',
    'Harvest',
    'Other',
  ];

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isPastDate(DateTime date) =>
      _normalizeDate(date).isBefore(_today());

  bool _isToday(DateTime date) =>
      DateUtils.isSameDay(_normalizeDate(date), _today());

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

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? _today();

    final data = widget.existingData;
    if (data != null) {
      taskController.text = data['task']?.toString() ?? '';
      notesController.text = data['notes']?.toString() ?? '';

      final savedType = data['type']?.toString() ?? 'Planting';
      scheduleType = scheduleTypes.contains(savedType) ? savedType : 'Other';
      growthStage = data['growthStage']?.toString() ?? 'Seedling';
      priority = data['priority']?.toString() ?? 'Medium';

      final savedDate = data['date'];
      if (savedDate is Timestamp) {
        selectedDate = savedDate.toDate();
      } else if (savedDate is DateTime) {
        selectedDate = savedDate;
      }

      final savedTime = data['time'];
      if (savedTime != null && savedTime.toString() != 'No time') {
        selectedTime = _parseTime(savedTime.toString());
      }
    }

    if (selectedDate != null && _isPastDate(selectedDate!)) {
      selectedDate = _today();
      selectedTime = null;
    }

    if (selectedDate != null &&
        selectedTime != null &&
        !_isTimeAvailable(selectedDate!, selectedTime!)) {
      selectedTime = null;
    }
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');
      final timeParts = parts.first.split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  bool _isTimeAvailable(DateTime date, TimeOfDay time) {
    if (!_isToday(date)) return true;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    return selected.isAfter(DateTime.now());
  }

  List<TimeOfDay> _getAvailableTimes() {
    if (selectedDate == null) return [];

    final times = <TimeOfDay>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final time = TimeOfDay(hour: hour, minute: minute);
        if (_isTimeAvailable(selectedDate!, time)) times.add(time);
      }
    }
    return times;
  }

  String _timeKey(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        time,
        alwaysUse24HourFormat: false,
      );

  Future<void> _pickDate() async {
    final today = _today();
    var initial = selectedDate ?? today;
    if (initial.isBefore(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2035, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF179E43),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1F2923),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final normalized = _normalizeDate(picked);
    setState(() {
      selectedDate = normalized;
      if (selectedTime != null &&
          !_isTimeAvailable(normalized, selectedTime!)) {
        selectedTime = null;
      }
    });
  }

  Future<void> _showCustomTimePicker() async {
    if (selectedDate == null) return;

    final availableTimes = _getAvailableTimes();
    if (availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available times remain today.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    TimeOfDay temporaryTime = selectedTime != null &&
            availableTimes.any((t) => _timeKey(t) == _timeKey(selectedTime!))
        ? selectedTime!
        : availableTimes.first;

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Color(0xFF179E43)),
                        SizedBox(width: 10),
                        Text(
                          'Select Schedule Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _timeKey(temporaryTime),
                      isExpanded: true,
                      menuMaxHeight: 350,
                      decoration: InputDecoration(
                        labelText: 'Available Time',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.schedule,
                          color: Color(0xFF179E43),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: availableTimes
                          .map(
                            (time) => DropdownMenuItem(
                              value: _timeKey(time),
                              child: Text(_formatTime(time)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          temporaryTime = availableTimes.firstWhere(
                            (time) => _timeKey(time) == value,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext, temporaryTime),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF179E43),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Select Time'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() => selectedTime = result);
    }
  }

  String _formatDate() {
    if (selectedDate == null) return 'Select date';
    return '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}';
  }

  Future<void> _saveSchedule() async {
    if (_isSaving) return;

    final task = taskController.text.trim();
    if (task.isEmpty || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the task, date, and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final date = _normalizeDate(selectedDate!);
    final scheduleDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (!scheduleDateTime.isAfter(DateTime.now())) {
      setState(() => selectedTime = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final formattedTime = _formatTime(selectedTime!);
    final event = '$task • $formattedTime • $growthStage • $priority';

    try {
      try {
        await NotificationService.scheduleNotification(
          id: scheduleDateTime.millisecondsSinceEpoch ~/ 1000,
          title: '$scheduleType Reminder',
          body: '$task at $formattedTime',
          scheduledDate: scheduleDateTime,
        );
      } catch (error) {
        debugPrint('Notification error: $error');
      }

      if (!mounted) return;
      Navigator.pop<Map<String, dynamic>>(
        context,
        {
          'date': date,
          'task': task,
          'type': scheduleType,
          'time': formattedTime,
          'growthStage': growthStage,
          'priority': priority,
          'notes': notesController.text.trim(),
          'event': event,
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to prepare schedule: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    taskController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Schedule' : 'Add Schedule'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF179E43),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _inputField(
              controller: taskController,
              label: 'Task Name',
              icon: Icons.task_alt,
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Schedule Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scheduleTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final type = scheduleTypes[index];
                final selected = scheduleType == type;

                return InkWell(
                  onTap: () => setState(() => scheduleType = type),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF179E43)
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _typeIcon(type),
                          color: selected
                              ? const Color(0xFF179E43)
                              : const Color(0xFF4F5A53),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            _selectBox(
              label: _formatDate(),
              icon: Icons.calendar_today,
              onTap: _pickDate,
            ),
            const SizedBox(height: 15),
            _selectBox(
              label: selectedTime == null
                  ? 'Select time'
                  : _formatTime(selectedTime!),
              icon: Icons.access_time,
              onTap: _showCustomTimePicker,
            ),
            const SizedBox(height: 15),
            _dropdownBox(
              label: 'Growth Stage',
              value: growthStage,
              items: const [
                'Seedling',
                'Transplant',
                'Vegetative',
                'Flowering',
                'Fruiting',
              ],
              onChanged: (value) {
                if (value != null) setState(() => growthStage = value);
              },
            ),
            const SizedBox(height: 15),
            _dropdownBox(
              label: 'Priority',
              value: priority,
              items: const ['Low', 'Medium', 'High'],
              onChanged: (value) {
                if (value != null) setState(() => priority = value);
              },
            ),
            const SizedBox(height: 15),
            _inputField(
              controller: notesController,
              label: 'Notes',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF179E43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Update Schedule' : 'Save Schedule',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF179E43)),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _selectBox({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5E6962)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF179E43)),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _dropdownBox({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
