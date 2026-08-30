import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPlantTrackerScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const EditPlantTrackerScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<EditPlantTrackerScreen> createState() =>
      _EditPlantTrackerScreenState();
}

class _EditPlantTrackerScreenState
    extends State<EditPlantTrackerScreen> {
  static const Color _primaryColor = Color(0xFF179E43);

  late final TextEditingController _plantNameController;
  late DateTime _plantingDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _plantNameController = TextEditingController(
      text: widget.data['plantName']?.toString() ?? '',
    );

    final dynamic rawDate = widget.data['plantingDate'];
    _plantingDate = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.now();
  }

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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final String plantName =
        _plantNameController.text.trim();

    if (plantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a plant name.'),
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

      final Map<String, dynamic> updatedData = {
        'plantName': plantName,
        'plantingDate': Timestamp.fromDate(
          _normalize(_plantingDate),
        ),
        'daysAfterPlanting': days,
        'estimatedGrowthStage': _growthStage(days),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('plant_trackers')
          .doc(widget.documentId)
          .update(updatedData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracked squash plant updated.'),
          backgroundColor: _primaryColor,
        ),
      );

      Navigator.pop(context, updatedData);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update plant: '
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Edit Tracked Plant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _plantNameController,
              decoration: InputDecoration(
                labelText: 'Plant name or label',
                prefixIcon: const Icon(
                  Icons.eco,
                  color: _primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Planting Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPlantingDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(_formatDate(_plantingDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Updated Growth Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Day $days'),
                  const SizedBox(height: 5),
                  Text(
                    _growthStage(days),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
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
                    _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
