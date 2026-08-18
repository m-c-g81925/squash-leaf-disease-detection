import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  final bool Function(DateTime) isPastDate;
  final String Function(DateTime) createDateKey;
  final void Function(DateTime selected, DateTime focused) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.documents,
    required this.isPastDate,
    required this.createDateKey,
    required this.onDaySelected,
  });

  Color _typeColor(String type) {
    switch (type.trim().toLowerCase()) {
      case 'planting':
        return const Color(0xFF179E43);
      case 'watering':
        return Colors.blue;
      case 'fertilizing':
        return Colors.orange;
      case 'disease scan':
        return Colors.red;
      case 'pest control':
        return Colors.deepPurple;
      case 'weeding':
        return Colors.teal;
      case 'harvest':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<QueryDocumentSnapshot<Map<String, dynamic>>>(
        firstDay: today,
        lastDay: DateTime(2035, 12, 31),
        focusedDay: focusedDay.isBefore(today) ? today : focusedDay,
        rowHeight: 42,
        daysOfWeekHeight: 28,
        enabledDayPredicate: (day) => !isPastDate(day),
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: (day) {
          final dateKey = createDateKey(day);

          return documents.where((document) {
            final data = document.data();
            return data['dateKey']?.toString() == dateKey;
          }).toList();
        },
        onDaySelected: onDaySelected,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Color(0xFF179E43),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Color(0xFF179E43),
          ),
        ),
        calendarStyle: const CalendarStyle(
          disabledTextStyle: TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFFA5D6A7),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF179E43),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          markersMaxCount: 4,
          markersAlignment: Alignment.bottomCenter,
        ),
        calendarBuilders:
            CalendarBuilders<QueryDocumentSnapshot<Map<String, dynamic>>>(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) {
              return const SizedBox.shrink();
            }

            final markerCount = events.length > 4 ? 4 : events.length;

            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  markerCount,
                  (index) {
                    final data = events[index].data();
                    final type = data['type']?.toString() ?? 'Other';

                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _typeColor(type),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
