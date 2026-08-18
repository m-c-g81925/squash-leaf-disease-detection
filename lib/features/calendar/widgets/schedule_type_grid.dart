import 'package:flutter/material.dart';

class ScheduleTypeGrid extends StatelessWidget {
  final List<String> scheduleTypes;
  final String selectedType;
  final ValueChanged<String> onChanged;

  const ScheduleTypeGrid({
    super.key,
    required this.scheduleTypes,
    required this.selectedType,
    required this.onChanged,
  });

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
  Widget build(BuildContext context) {
    return GridView.builder(
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
        final selected = selectedType == type;

        return InkWell(
          onTap: () => onChanged(type),
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
                      : Colors.grey.shade700,
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
    );
  }
}