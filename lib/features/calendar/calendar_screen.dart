import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_colors.dart';
import 'add_schedule_screen.dart';
import 'schedule_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isPastDate(DateTime day) {
    final DateTime today = _normalize(DateTime.now());
    final DateTime selectedDate = _normalize(day);
    return selectedDate.isBefore(today);
  }

  String _createDateKey(DateTime date) {
    final String year = date.year.toString();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _calendarStream() {
    final String? userId = _currentUserId;

    if (userId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> _openAddScheduleScreen() async {
    final String? userId = _currentUserId;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before adding a schedule.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(initialDate: _selectedDay),
      ),
    );

    if (result == null || !mounted) return;

    final dynamic returnedDate = result['date'];

    if (returnedDate is! DateTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected date is invalid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime normalizedDate = _normalize(returnedDate);

    if (_isPastDate(normalizedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot add a schedule to a past date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('schedules').add({
        'userId': userId,
        'date': Timestamp.fromDate(normalizedDate),
        'dateKey': _createDateKey(normalizedDate),
        'task': result['task'] ?? '',
        'time': result['time'] ?? 'No time',
        'growthStage': result['growthStage'] ?? 'Seedling',
        'priority': result['priority'] ?? 'Medium',
        'notes': result['notes'] ?? '',
        'event': result['event'] ?? result['task'] ?? 'Schedule',
        'type': result['type'] ?? 'Other',
        'status': result['status'] ?? 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _selectedDay = normalizedDate;
        _focusedDay = normalizedDate;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved successfully.'),
          backgroundColor: Color(0xFF179E43),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save schedule: ${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save schedule: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getSchedulesForSelectedDay() {
    final String dateKey = _createDateKey(_selectedDay);

    final String? userId = _currentUserId;

    if (userId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots();
  }

  String _formatSelectedDate() {
    return '${_selectedDay.month}/${_selectedDay.day}/${_selectedDay.year}';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = _normalize(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF179E43),
        onPressed: _openAddScheduleScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: const BoxDecoration(
                
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planting Calendar',
                    style: TextStyle(
                      color:Color(0xFF1B1B1B),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Manage your squash planting schedules.',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
                child: Column(
                  children: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _calendarStream(),
                      builder: (context, snapshot) {
                        final documents = snapshot.data?.docs ?? [];

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
                          child: TableCalendar<
                              QueryDocumentSnapshot<Map<String, dynamic>>>(
                            firstDay: today,
                            lastDay: DateTime(2035, 12, 31),
                            focusedDay:
                                _focusedDay.isBefore(today) ? today : _focusedDay,
                            rowHeight: 40,
                            daysOfWeekHeight: 28,
                            enabledDayPredicate: (day) => !_isPastDate(day),
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            eventLoader: (day) {
                              final String dateKey = _createDateKey(day);

                              return documents.where((document) {
                                final data = document.data();
                                return data['dateKey'] == dateKey;
                              }).toList();
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              if (_isPastDate(selectedDay)) return;

                              setState(() {
                                _selectedDay = _normalize(selectedDay);
                                _focusedDay = _normalize(focusedDay);
                              });
                            },
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
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
                              markerDecoration: BoxDecoration(
                                color: Color(0xFF179E43),
                                shape: BoxShape.circle,
                              ),
                              markersMaxCount: 3,
                            ),
                            calendarBuilders: CalendarBuilders<
                                QueryDocumentSnapshot<Map<String, dynamic>>>(
                              markerBuilder: (context, day, events) {
                                if (events.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final int markerCount =
                                    events.length > 3 ? 3 : events.length;

                                return Positioned(
                                  bottom: 2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      markerCount,
                                      (index) => Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF179E43),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved Schedules',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatSelectedDate(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _getSchedulesForSelectedDay(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Unable to load schedules',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  snapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF179E43),
                              ),
                            ),
                          );
                        }

                        final schedules = snapshot.data?.docs ?? [];

                        if (schedules.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  color: Colors.grey,
                                  size: 42,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No schedules for this date',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            final document = schedules[index];
                            final Map<String, dynamic> data = document.data();

                            final String event =
                                data['event']?.toString() ?? 'Schedule';
                            final String priority =
                                data['priority']?.toString() ?? 'Medium';
                            final String time =
                                data['time']?.toString() ?? 'No time';

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleDetailScreen(
                                      documentId: document.id,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
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
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.event_note,
                                        color: Color(0xFF179E43),
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
                                              fontWeight: FontWeight.w700,
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
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
