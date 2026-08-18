import 'package:flutter/material.dart';

class GrowthProgressTracker extends StatelessWidget {
  final String currentStage;

  const GrowthProgressTracker({
    super.key,
    required this.currentStage,
  });

  static const List<String> _stages = [
    'Seedling',
    'Transplant',
    'Vegetative',
    'Flowering',
    'Fruiting',
    'Harvest',
  ];

  int _currentStageIndex() {
    final int index = _stages.indexWhere(
      (String stage) =>
          stage.toLowerCase() ==
          currentStage.trim().toLowerCase(),
    );

    return index < 0 ? 0 : index;
  }

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'Seedling':
        return Icons.spa;
      case 'Transplant':
        return Icons.transcribe;
      case 'Vegetative':
        return Icons.grass;
      case 'Flowering':
        return Icons.local_florist;
      case 'Fruiting':
        return Icons.eco;
      case 'Harvest':
        return Icons.agriculture;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeIndex = _currentStageIndex();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Color(0xFF179E43),
              ),
              SizedBox(width: 8),
              Text(
                'Growth Progress',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(
            _stages.length,
            (int index) {
              final String stage = _stages[index];

              final bool isCompleted = index < activeIndex;
              final bool isCurrent = index == activeIndex;
              final bool isLast = index == _stages.length - 1;

              final Color stageColor = isCompleted || isCurrent
                  ? const Color(0xFF179E43)
                  : Colors.grey.shade400;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF179E43)
                              : isCompleted
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: stageColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : _stageIcon(stage),
                          size: 20,
                          color: isCurrent
                              ? Colors.white
                              : stageColor,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 38,
                          color: isCompleted
                              ? const Color(0xFF179E43)
                              : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? const Color(0xFF179E43)
                                  : isCompleted
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isCompleted
                                ? 'Completed stage'
                                : isCurrent
                                    ? 'Current growth stage'
                                    : 'Upcoming stage',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent
                                  ? const Color(0xFF179E43)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}