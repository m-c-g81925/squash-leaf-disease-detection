import 'package:flutter/material.dart';
import '../role_selection/role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // TITLE
              const SizedBox(height: 10),

              const Text(
                "Squash Disease Detection",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // CIRCLE LOGO
              Center(
                child: Container(
                  width: 210,
                  height: 210,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,

                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 3,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // FEATURE CARD
              _featureCard(
                icon: Icons.camera_alt,
                title: "Disease Scanning",
                subtitle: "Take or upload squash leaf images",
              ),

              const SizedBox(height: 12),

              // FEATURE CARD
              _featureCard(
                icon: Icons.menu_book,
                title: "Disease Library",
                subtitle: "Learn symptoms and prevention tips",
              ),

              const SizedBox(height: 12),

              // FEATURE CARD
              _featureCard(
                icon: Icons.calendar_today,
                title: "Planting Calendar",
                subtitle: "Manage schedules and farming tasks",
              ),

              const Spacer(),

              // BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RoleSelectionScreen(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Get Started  →",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: Colors.green.shade800,
              size: 24,
            ),
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}