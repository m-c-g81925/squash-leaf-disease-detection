import 'package:flutter/material.dart';

import '../../core/services/scan_history_service.dart';
import '../../models/scan_history_model.dart';
import 'scan_history_detail_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'High',
    'Medium',
    'Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} '
        'at $hour:$minute $period';
  }

  List<ScanHistory> _filterScans(List<ScanHistory> scans) {
    final query = _searchQuery.trim().toLowerCase();

    return scans.where((scan) {
      final matchesSearch =
          query.isEmpty || scan.disease.toLowerCase().contains(query);

      bool matchesSeverity;

      switch (_selectedFilter) {
        case 'High':
          final severity = scan.severity.toLowerCase();
          matchesSeverity = severity == 'high' || severity == 'critical';
          break;
        case 'Medium':
          matchesSeverity = scan.severity.toLowerCase() == 'medium';
          break;
        case 'Low':
          matchesSeverity = scan.severity.toLowerCase() == 'low';
          break;
        default:
          matchesSeverity = true;
      }

      return matchesSearch && matchesSeverity;
    }).toList();
  }

  void _openScanDetails(BuildContext context, ScanHistory scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanHistoryDetailScreen(scan: scan),
      ),
    );
  }

  Future<void> _deleteScan(BuildContext context, ScanHistory scan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Scan'),
          content: Text(
            'Are you sure you want to delete the scan result for '
            '${scan.disease}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await ScanHistoryService.deleteScan(scan.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan history deleted.'),
          backgroundColor: Color(0xFF179E43),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete scan: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllScans(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete All History',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to delete all scan history?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await ScanHistoryService.deleteAllScans();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All scan history has been deleted.'),
          backgroundColor: Color(0xFF179E43),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete all history: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Delete All History',
            onPressed: () => _deleteAllScans(context),
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ScanHistory>>(
        stream: ScanHistoryService.getScanHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final scans = snapshot.data ?? [];

          if (scans.isEmpty) {
            return _buildEmptyState();
          }

          final filteredScans = _filterScans(scans);

          return Column(
            children: [
              _buildSearchAndFilters(totalResults: filteredScans.length),
              Expanded(
                child: filteredScans.isEmpty
                    ? _buildNoResultsState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: filteredScans.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(
                            context,
                            filteredScans[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters({required int totalResults}) {
    return Container(
      color: const Color(0xFFF6F7F5),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search disease...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF179E43),
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF179E43),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: const Color(0xFF179E43),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF179E43)
                        : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4F5A53),
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedFilter = filter);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$totalResults result${totalResults == 1 ? '' : 's'} found',
            style: TextStyle(
              color: const Color(0xFF5E6962),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ScanHistory scan) {
    final severityColor = _severityColor(scan.severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openScanDetails(context, scan),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF179E43).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF179E43),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.disease,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Confidence: ${scan.confidence.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4F5A53),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Text(
                          'Severity: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scan.severity,
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: const Color(0xFF68736B),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatDate(scan.scannedAt.toDate()),
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF5E6962),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: const Color(0xFF68736B),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _deleteScan(context, scan),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF179E43).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Color(0xFF179E43),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Matching Scans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Try a different disease name or severity filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5E6962),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
              icon: const Icon(
                Icons.refresh,
                color: Color(0xFF179E43),
              ),
              label: const Text(
                'Reset Search',
                style: TextStyle(
                  color: Color(0xFF179E43),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF179E43).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 55,
                color: Color(0xFF179E43),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Scan History Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Saved disease scan results will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF5E6962),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 65,
              color: Colors.red,
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to Load Scan History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF5E6962)),
            ),
          ],
        ),
      ),
    );
  }
}
