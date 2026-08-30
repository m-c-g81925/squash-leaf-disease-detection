import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'edit_plant_tracker_screen.dart';

class PlantTrackerDetailScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const PlantTrackerDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<PlantTrackerDetailScreen> createState() =>
      _PlantTrackerDetailScreenState();
}

class _PlantTrackerDetailScreenState
    extends State<PlantTrackerDetailScreen> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF5F7FB);

  bool _isDeleting = false;
  bool _isHarvesting = false;
  late Map<String, dynamic> _plantData;

  @override
  void initState() {
    super.initState();
    _plantData = Map<String, dynamic>.from(widget.data);
  }

  DateTime _normalize(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  int _daysAfterPlanting(DateTime plantingDate) {
    final DateTime today =
        _normalize(DateTime.now());

    final DateTime planted =
        _normalize(plantingDate);

    final int days =
        today.difference(planted).inDays;

    return days < 0 ? 0 : days;
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

  String _nextStage(int days) {
    if (days <= 0) {
      return 'Germination / Sprouting';
    }

    if (days <= 10) {
      return 'Seedling Growth';
    }

    if (days <= 20) {
      return 'Vine Development';
    }

    if (days <= 30) {
      return 'Flowering';
    }

    if (days <= 45) {
      return 'Fruit Development';
    }

    if (days <= 70) {
      return 'Possible Harvest Stage';
    }

    return 'Harvest monitoring';
  }

  int _daysUntilNextStage(int days) {
    if (days <= 0) {
      return 1;
    }

    if (days <= 10) {
      return 11 - days;
    }

    if (days <= 20) {
      return 21 - days;
    }

    if (days <= 30) {
      return 31 - days;
    }

    if (days <= 45) {
      return 46 - days;
    }

    if (days <= 70) {
      return 71 - days;
    }

    return 0;
  }

  DateTime _estimatedHarvestDate(
    DateTime plantingDate,
  ) {
    return _normalize(
      plantingDate.add(
        const Duration(days: 71),
      ),
    );
  }

  double _progressValue(int days) {
    if (days <= 0) {
      return 0.02;
    }

    if (days >= 71) {
      return 1.0;
    }

    return days / 71;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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

  Future<void> _editPlant() async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlantTrackerScreen(
          documentId: widget.documentId,
          data: _plantData,
        ),
      ),
    );

    if (result is Map<String, dynamic> && mounted) {
      setState(() {
        _plantData = {
          ..._plantData,
          ...result,
        };
      });
    }
  }

  Future<void> _markAsHarvested() async {
    if (_isHarvesting) return;

    final bool alreadyHarvested =
        _plantData['status']?.toString() == 'harvested';

    if (alreadyHarvested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This squash plant is already marked as harvested.'),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark as harvested?'),
          content: const Text(
            'This will record today as the actual harvest date. '
            'The plant will remain in My Squash Plants as a completed record.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark Harvested'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isHarvesting = true;
    });

    try {
      final DateTime actualHarvestDate = _normalize(DateTime.now());

      await FirebaseFirestore.instance
          .collection('plant_trackers')
          .doc(widget.documentId)
          .update({
        'status': 'harvested',
        'actualHarvestDate': Timestamp.fromDate(actualHarvestDate),
        'harvestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _plantData = {
          ..._plantData,
          'status': 'harvested',
          'actualHarvestDate': Timestamp.fromDate(actualHarvestDate),
        };
        _isHarvesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Squash plant marked as harvested.'),
          backgroundColor: _primaryColor,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _isHarvesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark plant as harvested: '
            '${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlant() async {
    if (_isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete tracked plant?'),
          content: const Text(
            'This will permanently remove this squash plant from My Squash Plants. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('plant_trackers')
          .doc(widget.documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracked squash plant deleted.'),
          backgroundColor: Color(0xFF179E43),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete plant: ${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete plant: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String plantName =
        _plantData['plantName']?.toString().trim() ??
            'Squash Plant';

    final dynamic rawDate =
        _plantData['plantingDate'];

    if (rawDate is! Timestamp) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Plant Progress'),
        ),
        body: const Center(
          child: Text(
            'This plant does not have a valid planting date.',
          ),
        ),
      );
    }

    final DateTime plantingDate =
        rawDate.toDate();

    final int days =
        _daysAfterPlanting(
      plantingDate,
    );

    final String stage =
        _growthStage(days);

    final String nextStage =
        _nextStage(days);

    final int daysUntilNext =
        _daysUntilNextStage(days);

    final DateTime harvestDate =
        _estimatedHarvestDate(
      plantingDate,
    );

    final bool isHarvested =
        _plantData['status']?.toString() == 'harvested';

    final dynamic rawActualHarvestDate =
        _plantData['actualHarvestDate'];

    final DateTime? actualHarvestDate =
        rawActualHarvestDate is Timestamp
            ? rawActualHarvestDate.toDate()
            : null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Plant Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Edit Plant',
            onPressed: (_isDeleting || _isHarvesting) ? null : _editPlant,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete Plant',
            onPressed: (_isDeleting || _isHarvesting) ? null : _deletePlant,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFE1E7E2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    plantName,
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Day $days after planting',
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF5E6962,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  LinearProgressIndicator(
                    value:
                        _progressValue(
                      days,
                    ),
                    minHeight: 10,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                    backgroundColor:
                        const Color(
                      0xFFE5E9E6,
                    ),
                    color:
                        _primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Estimated Stage',
                    style:
                        TextStyle(
                      fontSize: 14,
                      color:
                          Color(
                        0xFF5E6962,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Text(
                    stage,
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          _primaryColor,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    _stageDescription(
                      days,
                    ),
                    style:
                        const TextStyle(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Growth Timeline',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  _timelineItem(
                    label: 'Planted',
                    range: 'Day 0',
                    active:
                        days >= 0,
                  ),
                  _timelineItem(
                    label:
                        'Germination / Sprouting',
                    range:
                        'Day 1–10',
                    active:
                        days >= 1,
                  ),
                  _timelineItem(
                    label:
                        'Seedling Growth',
                    range:
                        'Day 11–20',
                    active:
                        days >= 11,
                  ),
                  _timelineItem(
                    label:
                        'Vine Development',
                    range:
                        'Day 21–30',
                    active:
                        days >= 21,
                  ),
                  _timelineItem(
                    label:
                        'Flowering',
                    range:
                        'Day 31–45',
                    active:
                        days >= 31,
                  ),
                  _timelineItem(
                    label:
                        'Fruit Development',
                    range:
                        'Day 46–70',
                    active:
                        days >= 46,
                  ),
                  _timelineItem(
                    label:
                        'Possible Harvest',
                    range:
                        'Day 71+',
                    active:
                        days >= 71,
                    last:
                        true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon:
                  Icons.trending_up,
              title:
                  'Next Expected Stage',
              value:
                  days >= 71
                      ? 'Monitor fruit maturity for harvesting.'
                      : '$nextStage in about '
                          '$daysUntilNext day${daysUntilNext == 1 ? '' : 's'}.',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon:
                  Icons.calendar_today,
              title:
                  'Planting Date',
              value:
                  _formatDate(
                plantingDate,
              ),
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon:
                  Icons.agriculture,
              title:
                  'Estimated Harvest',
              value:
                  _formatDate(
                harvestDate,
              ),
            ),
            const SizedBox(height: 16),
            if (isHarvested)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB7DFBE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: _primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Harvested',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (actualHarvestDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Actual harvest date: '
                              '${_formatDate(actualHarvestDate)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _isHarvesting ? null : _markAsHarvested,
                  icon: _isHarvesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.agriculture),
                  label: Text(
                    _isHarvesting
                        ? 'Saving...'
                        : 'Mark as Harvested',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFF8E7,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Text(
                'Growth stages are estimates only. Actual squash development can vary depending on weather, soil, variety, irrigation, pests, disease, and overall plant health.',
                style:
                    TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color:
                      Color(
                    0xFF745E2D,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem({
    required String label,
    required String range,
    required bool active,
    bool last = false,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: active
                    ? _primaryColor
                    : const Color(
                        0xFFD8DEDA,
                      ),
              ),
              child: active
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color:
                          Colors.white,
                    )
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 38,
                color: active
                    ? _primaryColor
                    : const Color(
                        0xFFD8DEDA,
                      ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 18,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color: active
                        ? const Color(
                            0xFF1F2923,
                          )
                        : Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  range,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFE8F5E9,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
                  _primaryColor,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}