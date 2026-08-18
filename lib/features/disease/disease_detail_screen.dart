import 'package:flutter/material.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> disease;

  const DiseaseDetailScreen({
    super.key,
    required this.disease,
  });

  static const Color _backgroundColor = Color(0xFFF6F7F5);

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Medium':
        return const Color(0xFFB56A00);
      case 'High':
        return const Color(0xFFC33A32);
      case 'Critical':
        return const Color(0xFF8F211B);
      default:
        return const Color(0xFF68736B);
    }
  }

  List<String> _readItems(String key) {
    final dynamic value = disease[key];

    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        disease['name']?.toString() ?? 'Disease Details';
    final String severity =
        disease['severity']?.toString() ?? 'Unknown';
    final String image =
        disease['detailImage']?.toString() ?? '';
    final String description =
        disease['description']?.toString() ??
            'No description available.';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2923),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _SeverityBadge(
              severity: severity,
              color: _severityColor(severity),
            ),
            const SizedBox(height: 12),
            _DiseaseImage(imagePath: image),
            const SizedBox(height: 15),
            _DescriptionCard(description: description),
            const SizedBox(height: 12),
            _InformationCard(
              title: 'Symptoms',
              icon: Icons.warning_amber,
              items: _readItems('symptoms'),
            ),
            const SizedBox(height: 12),
            _InformationCard(
              title: 'Causes',
              icon: Icons.bug_report,
              items: _readItems('causes'),
            ),
            const SizedBox(height: 12),
            _InformationCard(
              title: 'Treatment',
              icon: Icons.healing,
              items: _readItems('treatment'),
            ),
            const SizedBox(height: 12),
            _InformationCard(
              title: 'Prevention Tips',
              icon: Icons.eco,
              items: _readItems('prevention'),
              highlighted: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;

  const _SeverityBadge({
    required this.severity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          'Severity: $severity',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DiseaseImage extends StatelessWidget {
  final String imagePath;

  const _DiseaseImage({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        imagePath,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            height: 190,
            width: double.infinity,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
        ),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final bool highlighted;

  const _InformationCard({
    required this.title,
    required this.icon,
    required this.items,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFDFF3E2)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlighted
            ? Border.all(color: Colors.green.shade200)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: title,
            icon: icon,
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'No information available.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: Colors.grey,
              ),
            )
          else
            ...items.map(
              (String item) => _BulletItem(text: item),
            ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CardHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
