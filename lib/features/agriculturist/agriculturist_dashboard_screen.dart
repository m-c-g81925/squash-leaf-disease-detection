import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../expert_review/review_history_screen.dart';
import '../role_selection/role_selection_screen.dart';
import 'agriculturist_review_list_screen.dart';

class AgriculturistDashboardScreen extends StatelessWidget {
  const AgriculturistDashboardScreen({super.key});

  static const Color _primary = Color(0xFF179E43);
  static const Color _background = Color(0xFFF5F7FB);

  Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream() {
    return FirebaseFirestore.instance
        .collection('expert_reviews')
        .snapshots();
  }

  bool _isReviewed(String status) {
    final value = status.trim().toLowerCase();
    return value == 'reviewed' ||
        value == 'verified' ||
        value == 'completed' ||
        value == 'rejected';
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Agriculturist Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reviewsStream(),
        builder: (context, snapshot) {
          int total = 0;
          int pending = 0;
          int reviewed = 0;

          if (snapshot.hasData) {
            total = snapshot.data!.docs.length;

            for (final document in snapshot.data!.docs) {
              final status =
                  document.data()['status']?.toString() ?? 'pending';

              if (_isReviewed(status)) {
                reviewed++;
              } else {
                pending++;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Agriculturist!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review submitted squash disease cases and provide expert feedback.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: _primary,
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  _errorCard(snapshot.error.toString())
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _dashboardCard(
                          title: 'Pending',
                          value: pending.toString(),
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dashboardCard(
                          title: 'Reviewed',
                          value: reviewed.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dashboardCard(
                    title: 'Total Consultations',
                    value: total.toString(),
                    icon: Icons.analytics,
                    color: _primary,
                  ),
                ],
                const SizedBox(height: 30),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  context: context,
                  icon: Icons.assignment,
                  title: 'Review Requests',
                  subtitle:
                      'Open farmer cases and provide expert feedback',
                  color: Colors.orange,
                  screen: const AgriculturistReviewListScreen(),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  context: context,
                  icon: Icons.history,
                  title: 'Review History',
                  subtitle:
                      'View previous and completed consultations',
                  color: _primary,
                  screen: const ReviewHistoryScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load review statistics.\n$message',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget screen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
