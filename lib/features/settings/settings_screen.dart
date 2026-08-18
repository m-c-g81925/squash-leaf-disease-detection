import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _primaryColor = Color(0xFF179E43);

  bool _notificationsEnabled = true;

  Color get _pageColor =>
      const Color(0xFFF6F7F5);

  Color get _cardColor => Colors.white;

  Color get _primaryTextColor =>
      const Color(0xFF1B1B1B);

  Color get _secondaryTextColor =>
      const Color(0xFF4F5A53);

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;

    if (email == null || email.trim().isEmpty) {
      _showMessage(
        'No email address is available for this account.',
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Text(
            'A password reset link will be sent to:\n\n$email',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password reset email sent. Check your inbox.',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to send reset email: '
        '${error.message ?? error.code}',
      );
    }
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.eco,
                color: _primaryColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'About the Application',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Squash Leaf Disease Detection with Planting '
                  'Calendar Application helps farmers identify '
                  'common squash leaf conditions using a CNN '
                  'model and organize planting activities using '
                  'the planting calendar.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Developed by:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text('Mary Charlyn Gonzales'),
                Text('April Joy Cerbo'),
                SizedBox(height: 18),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: _primaryColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'The application collects only information '
              'needed to provide account, disease detection, '
              'scan history, planting calendar, and expert '
              'review features.\n\n'
              'Scan records may include detected disease, '
              'confidence level, severity, description, and '
              'scan date.\n\n'
              'Profile photos are stored locally on the '
              'user\'s device and are not uploaded to Firebase '
              'Storage.\n\n'
              'User-specific Firestore records are protected '
              'by authenticated account access.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showUserGuide() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: _primaryColor,
              ),
              SizedBox(width: 10),
              Text(
                'Quick User Guide',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Use Scan for Disease to take or choose a '
              'clear squash leaf image.\n\n'
              '2. Review the CNN prediction, confidence, '
              'severity, and description.\n\n'
              '3. Save useful scan results to Scan History.\n\n'
              '4. Use Planting Calendar to create and manage '
              'farm activity schedules.\n\n'
              '5. For low-confidence results, submit an '
              'Expert Review Request for agriculturist '
              'verification.\n\n'
              '6. Use your Profile to update farmer '
              'information and choose a local profile photo.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 22),

          _buildSectionTitle('Account'),
          const SizedBox(height: 10),
          _buildSettingsContainer(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.lock_reset_outlined,
                  color: _primaryColor,
                ),
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Send a password reset link to your email',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _sendPasswordReset,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Preferences'),
          const SizedBox(height: 10),
          _buildSettingsContainer(
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                activeColor: _primaryColor,
                secondary: const Icon(
                  Icons.notifications_outlined,
                  color: _primaryColor,
                ),
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Receive planting schedule reminders',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });

                  _showMessage(
                    value
                        ? 'Notifications enabled.'
                        : 'Notifications disabled.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Help & Information'),
          const SizedBox(height: 10),
          _buildSettingsContainer(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: _primaryColor,
                ),
                title: Text(
                  'User Guide',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Learn how to use the main features',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _showUserGuide,
              ),
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: _primaryColor,
                ),
                title: Text(
                  'About the Application',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Application purpose and developers',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _showAboutDialog,
              ),
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: _primaryColor,
                ),
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'View how your information is handled',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: _showPrivacyPolicy,
              ),
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: const Icon(
                  Icons.phone_android,
                  color: _primaryColor,
                ),
                title: Text(
                  'App Version',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Center(
            child: Text(
              'Squash Leaf Disease Detection • Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.settings,
              color: _primaryColor,
              size: 32,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your account and preferences',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
