import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final void Function(int) onTabChange;

  const QuickActions({
    super.key,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1B),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _actionButton(
          title: 'I-scan ang balatian sang kalabasa',
          subtitle: 'Magkuha ukon mag-upload sang picture sang dahon sang kalabasa.',
          icon: Icons.camera_alt,
          color: const Color(0xFF179E43),
          onTap: () => onTabChange(1),
        ),

        _actionButton(
          title: 'Kalendaryo sang pagtanom',
          subtitle: 'Dumalaa ang schedule sang imo pagtanom.',
          icon: Icons.calendar_today,
          color: const Color(0xFF1DB954),
          onTap: () => onTabChange(2),
        ),

        _actionButton(
          title: 'Librarya sang mga balatian',
          subtitle: 'Talan-awan sang mga balatian sang kalabasa.',
          icon: Icons.menu_book,
          color: const Color(0xFF4ADE80),
          onTap: () => onTabChange(3),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 9,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}