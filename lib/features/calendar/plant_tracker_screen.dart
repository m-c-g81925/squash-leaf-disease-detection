import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';

class PlantTrackerScreen extends StatefulWidget {
  const PlantTrackerScreen({super.key});

  @override
  State<PlantTrackerScreen> createState() =>
      _PlantTrackerScreenState();
}

class _PlantTrackerScreenState
    extends State<PlantTrackerScreen> {
  final TextEditingController _plantNameController =
      TextEditingController();

  DateTime _plantingDate = DateTime.now();
  bool _isSaving = false;

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _daysAfterPlanting(DateTime plantingDate) {
    final DateTime today = _normalize(DateTime.now());
    final DateTime planted = _normalize(plantingDate);

    return today.difference(planted).inDays;
  }

  String _growthStage(int days) {
    if (days <= 0) {
      return 'Planted';
    }

    if (days <= 10) {
      return 'Germination / Sprouting';
    }

    if (days <= 20) {
      return 'Seedling Growth';
    }

    if (days <= 30) {
      return 'Vine Development';
    }

    if (days <= 45) {
      return 'Flowering';
    }

    if (days <= 70) {
      return 'Fruit Development';
    }

    return 'Possible Harvest Stage';
  }

  String _stageDescription(int days) {
    if (days <= 0) {
      return 'The squash has just been planted.';
    }

    if (days <= 10) {
      return 'The squash is expected to begin germinating and sprouting.';
    }

    if (days <= 20) {
      return 'The young squash plant is developing leaves and roots.';
    }

    if (days <= 30) {
      return 'The squash vines are expected to grow and spread.';
    }

    if (days <= 45) {
      return 'The squash may begin producing flowers during this period.';
    }

    if (days <= 70) {
      return 'Squash fruits may begin forming and developing.';
    }

    return 'The squash may be approaching harvest maturity. Check the actual fruit before harvesting.';
  }

  Future<void> _pickPlantingDate() async {
    final DateTime today = _normalize(DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate.isAfter(today)
          ? today
          : _plantingDate,
      firstDate: DateTime(2020),
      lastDate: today,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _plantingDate = picked;
    });
  }

  Future<void> _scheduleGrowthNotifications({
    required String plantName,
    required DateTime plantingDate,
  }) async {
    final DateTime now = DateTime.now();

    final List<Map<String, dynamic>> stages = [
      {
        'day': 1,
        'title': 'Squash Sprouting Stage',
        'body':
            '$plantName is expected to begin germinating and sprouting.',
      },
      {
        'day': 11,
        'title': 'Squash Seedling Stage',
        'body':
            '$plantName is expected to enter the seedling growth stage.',
      },
      {
        'day': 21,
        'title': 'Squash Vine Development',
        'body':
            '$plantName is expected to begin vine development.',
      },
      {
        'day': 31,
        'title': 'Squash Flowering Stage',
        'body':
            '$plantName may begin producing flowers around this time.',
      },
      {
        'day': 46,
        'title': 'Squash Fruit Development',
        'body':
            '$plantName may begin developing squash fruits around this time.',
      },
      {
        'day': 71,
        'title': 'Squash Harvest Check',
        'body':
            '$plantName may be approaching harvest. Check the fruit for actual maturity.',
      },
    ];

    final int baseId =
        DateTime.now().millisecondsSinceEpoch.remainder(1000000);

    for (int index = 0; index < stages.length; index++) {
      final Map<String, dynamic> stage = stages[index];

      final DateTime stageDate = plantingDate.add(
        Duration(days: stage['day'] as int),
      );

      // Notify at 7:00 AM on the estimated stage date.
      final DateTime notificationDate = DateTime(
        stageDate.year,
        stageDate.month,
        stageDate.day,
        7,
      );

      // Do not schedule stages that have already passed.
      if (!notificationDate.isAfter(now)) {
        continue;
      }

      await NotificationService.scheduleNotification(
        id: baseId + index,
        title: stage['title'] as String,
        body: stage['body'] as String,
        scheduledDate: notificationDate,
      );
    }
  }

  Future<void> _savePlant() async {
    if (_isSaving) return;

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in before tracking a squash plant.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String plantName =
        _plantNameController.text.trim();

    if (plantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a name for this squash plant.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final int days =
          _daysAfterPlanting(_plantingDate);

      await FirebaseFirestore.instance
          .collection('plant_trackers')
          .add({
        'userId': user.uid,
        'plantName': plantName,
        'plantingDate':
            Timestamp.fromDate(
          _normalize(_plantingDate),
        ),
        'daysAfterPlanting': days,
        'estimatedGrowthStage':
            _growthStage(days),
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      await _scheduleGrowthNotifications(
        plantName: plantName,
        plantingDate: _normalize(_plantingDate),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Squash plant added. Growth-stage notifications were scheduled.',
          ),
          backgroundColor:
              Color(0xFF179E43),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save plant: '
            '${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int days =
        _daysAfterPlanting(_plantingDate);

    final String stage =
        _growthStage(days);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Track New Squash Plant',
        ),
        backgroundColor:
            const Color(0xFF179E43),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            TextField(
              controller:
                  _plantNameController,
              decoration: InputDecoration(
                labelText:
                    'Plant name or label',
                hintText:
                    'Example: Squash Plot 1',
                prefixIcon: const Icon(
                  Icons.eco,
                  color:
                      Color(0xFF179E43),
                ),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Planting Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPlantingDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color:
                          Color(0xFF179E43),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      '${_plantingDate.month}/'
                      '${_plantingDate.day}/'
                      '${_plantingDate.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFDDE5DF,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Growth Preview',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Day $days',
                    style: const TextStyle(
                      color:
                          Color(0xFF5E6962),
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    stage,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF179E43),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    _stageDescription(
                      days,
                    ),
                    style: const TextStyle(
                      height: 1.4,
                      color:
                          Color(0xFF4F5A53),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    'Note: Growth stages are estimates and may vary depending on weather, soil, variety, irrigation, and plant health.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isSaving
                        ? null
                        : _savePlant,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Start Tracking Plant',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF179E43,
                  ),
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}