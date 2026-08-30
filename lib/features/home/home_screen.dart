import 'package:flutter/material.dart';

import 'widgets/app_header.dart';
import 'widgets/dashboard_statistics.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activity.dart';
import 'widgets/daily_tip.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onTabChange;

  const HomeScreen({
    super.key,
    required this.onTabChange,
  });

  static const Color _backgroundColor = Color(0xFFF6F7F5);
  static const Color _primaryTextColor = Color(0xFF1F2923);
  static const Color _secondaryTextColor = Color(0xFF5E6962);
  static const Color _primaryColor = Color(0xFF179E43);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 22,
            bottom: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: AppHeader(),
              ),

              const SizedBox(height: 26),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: QuickActions(
                  onTabChange: onTabChange,
                ),
              ),

              const SizedBox(height: 28),

              const DashboardStatistics(),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _ExpertReviewShortcut(
                  onTap: () => onTabChange(5),
                ),
              ),

              const SizedBox(height: 28),

              
              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: RecentActivity(),
              ),

              const SizedBox(height: 26),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: DailyTip(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: HomeScreen._primaryTextColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ExpertReviewShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _ExpertReviewShortcut({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFDDE5DF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_outlined,
                  color: HomeScreen._primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mga Request para sa Expert Review',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HomeScreen._primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tan-awa ang pending kag natapos nga mga review',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: HomeScreen._secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                size: 22,
                color: Color(0xFF768078),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
