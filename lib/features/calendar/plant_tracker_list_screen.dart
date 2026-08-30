import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'plant_tracker_detail_screen.dart';

class PlantTrackerListScreen extends StatelessWidget {
  const PlantTrackerListScreen({super.key});

  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF5F7FB);

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _daysAfterPlanting(DateTime plantingDate) {
    final int days = _normalize(DateTime.now())
        .difference(_normalize(plantingDate))
        .inDays;
    return days < 0 ? 0 : days;
  }

  String _growthStage(int days) {
    if (days <= 0) return 'Planted';
    if (days <= 10) return 'Germination / Sprouting';
    if (days <= 20) return 'Seedling Growth';
    if (days <= 30) return 'Vine Development';
    if (days <= 45) return 'Flowering';
    if (days <= 70) return 'Fruit Development';
    return 'Possible Harvest Stage';
  }

  IconData _growthIcon(int days) {
    if (days <= 0) return Icons.grass;
    if (days <= 10) return Icons.spa;
    if (days <= 20) return Icons.eco;
    if (days <= 30) return Icons.nature;
    if (days <= 45) return Icons.local_florist;
    if (days <= 70) return Icons.agriculture;
    return Icons.shopping_basket;
  }

  String _nextStage(int days) {
    if (days <= 0) return 'Germination / Sprouting';
    if (days <= 10) return 'Seedling Growth';
    if (days <= 20) return 'Vine Development';
    if (days <= 30) return 'Flowering';
    if (days <= 45) return 'Fruit Development';
    if (days <= 70) return 'Possible Harvest Stage';
    return 'Harvest monitoring';
  }

  int _daysUntilNextStage(int days) {
    if (days <= 0) return 1;
    if (days <= 10) return 11 - days;
    if (days <= 20) return 21 - days;
    if (days <= 30) return 31 - days;
    if (days <= 45) return 46 - days;
    if (days <= 70) return 71 - days;
    return 0;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  DateTime _estimatedHarvestDate(DateTime plantingDate) {
    return _normalize(
      plantingDate.add(const Duration(days: 71)),
    );
  }

  double _progressValue(int days) {
    if (days <= 0) return 0.02;
    if (days >= 71) return 1.0;
    return days / 71;
  }

  Widget _sectionHeader({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 21),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E7E2),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPlantCard({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    final Map<String, dynamic> data = document.data();

    final String plantName =
        data['plantName']?.toString().trim() ?? 'Squash Plant';

    final dynamic rawDate = data['plantingDate'];

    if (rawDate is! Timestamp) {
      return const SizedBox.shrink();
    }

    final DateTime plantingDate = rawDate.toDate();
    final int days = _daysAfterPlanting(plantingDate);
    final String stage = _growthStage(days);
    final String nextStage = _nextStage(days);
    final int daysUntilNext = _daysUntilNextStage(days);
    final DateTime harvestDate =
        _estimatedHarvestDate(plantingDate);

    final bool isHarvested =
        data['status']?.toString() == 'harvested';

    final dynamic rawActualHarvestDate =
        data['actualHarvestDate'];

    final DateTime? actualHarvestDate =
        rawActualHarvestDate is Timestamp
            ? rawActualHarvestDate.toDate()
            : null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlantTrackerDetailScreen(
              documentId: document.id,
              data: data,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE1E7E2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isHarvested
                        ? Icons.check_circle
                        : _growthIcon(days),
                    color: _primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isHarvested
                            ? 'Completed growth cycle'
                            : 'Day $days after planting',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isHarvested ? '✓ Harvested' : stage,
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: isHarvested
                  ? 1.0
                  : _progressValue(days),
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: const Color(0xFFE5E9E6),
              color: _primaryColor,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Planted: ${_formatDate(plantingDate)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isHarvested
                      ? Icons.check_circle_outline
                      : Icons.trending_up,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHarvested
                        ? 'Growth cycle completed.'
                        : days >= 71
                            ? 'Next: Monitor fruit maturity for harvesting.'
                            : 'Next: $nextStage in about '
                                '$daysUntilNext day${daysUntilNext == 1 ? '' : 's'}.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.agriculture_outlined,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHarvested && actualHarvestDate != null
                        ? 'Actual harvest: ${_formatDate(actualHarvestDate)}'
                        : 'Estimated harvest: ${_formatDate(harvestDate)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Squash Plants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userId == null
          ? const Center(
              child: Text(
                'Please log in to view your tracked plants.',
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('plant_trackers')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load tracked plants.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 70,
                            color: _primaryColor,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'No tracked squash plants yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Use Track New Squash Plant to start monitoring plant growth.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final activePlants = documents.where(
                  (document) =>
                      document.data()['status']?.toString() !=
                      'harvested',
                ).toList();

                final harvestedPlants = documents.where(
                  (document) =>
                      document.data()['status']?.toString() ==
                      'harvested',
                ).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader(
                      title: 'Active Plants',
                      count: activePlants.length,
                      icon: Icons.eco,
                    ),
                    if (activePlants.isEmpty)
                      _emptySection(
                        'No active squash plants right now.',
                      )
                    else
                      ...activePlants.map(
                        (document) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 14),
                          child: _buildPlantCard(
                            context: context,
                            document: document,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _sectionHeader(
                      title: 'Harvested Plants',
                      count: harvestedPlants.length,
                      icon: Icons.inventory_2_outlined,
                    ),
                    if (harvestedPlants.isEmpty)
                      _emptySection(
                        'No harvested squash plants yet.',
                      )
                    else
                      ...harvestedPlants.map(
                        (document) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 14),
                          child: _buildPlantCard(
                            context: context,
                            document: document,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
