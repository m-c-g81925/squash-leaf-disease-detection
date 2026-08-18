import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'features/agriculturist/agriculturist_dashboard_screen.dart';
import 'features/main/main_screen.dart';
import 'features/role_selection/role_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static const Color _primaryColor = Color(0xFF179E43);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (
        BuildContext context,
        AsyncSnapshot<User?> authSnapshot,
      ) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'Checking your account...',
          );
        }

        if (authSnapshot.hasError) {
          return _ErrorScreen(
            message:
                'Unable to check authentication: ${authSnapshot.error}',
          );
        }

        final User? user = authSnapshot.data;

        if (user == null) {
          return const RoleSelectionScreen();
        }

        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (
            BuildContext context,
            AsyncSnapshot<
                    DocumentSnapshot<Map<String, dynamic>>>
                userSnapshot,
          ) {
            if (userSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen(
                message: 'Loading your account...',
              );
            }

            if (userSnapshot.hasError) {
              return _ErrorScreen(
                message:
                    'Unable to load user information: ${userSnapshot.error}',
              );
            }

            if (!userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              return _MissingUserRecordScreen(
                userId: user.uid,
              );
            }

            final Map<String, dynamic> data =
                userSnapshot.data!.data() ??
                    <String, dynamic>{};

            final String role =
                data['role']?.toString().trim().toLowerCase() ??
                    '';

            final bool isActive =
                data['isActive'] as bool? ?? true;

            if (!isActive) {
              return const _InactiveAccountScreen();
            }

            switch (role) {
              case 'farmer':
                return const MainScreen();

              case 'agriculturist':
                return const AgriculturistDashboardScreen();

              default:
                return _InvalidRoleScreen(
                  role: role,
                );
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AuthWrapper._primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageScreen(
      icon: Icons.error_outline,
      iconColor: Colors.red,
      title: 'Something Went Wrong',
      message: message,
      actionLabel: 'Sign Out',
      onAction: () => FirebaseAuth.instance.signOut(),
    );
  }
}

class _MissingUserRecordScreen extends StatelessWidget {
  final String userId;

  const _MissingUserRecordScreen({
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageScreen(
      icon: Icons.person_off_outlined,
      iconColor: Colors.orange,
      title: 'User Profile Missing',
      message:
          'Your authentication account exists, but its Firestore user record was not found.\n\nUser ID: $userId',
      actionLabel: 'Sign Out',
      onAction: () => FirebaseAuth.instance.signOut(),
    );
  }
}

class _InactiveAccountScreen extends StatelessWidget {
  const _InactiveAccountScreen();

  @override
  Widget build(BuildContext context) {
    return _MessageScreen(
      icon: Icons.block,
      iconColor: Colors.red,
      title: 'Account Disabled',
      message:
          'This account is currently inactive. Please contact the system administrator.',
      actionLabel: 'Sign Out',
      onAction: () => FirebaseAuth.instance.signOut(),
    );
  }
}

class _InvalidRoleScreen extends StatelessWidget {
  final String role;

  const _InvalidRoleScreen({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageScreen(
      icon: Icons.manage_accounts_outlined,
      iconColor: Colors.orange,
      title: 'Invalid Account Role',
      message: role.isEmpty
          ? 'No role is assigned to this account.'
          : 'The role "$role" is not supported by this application.',
      actionLabel: 'Sign Out',
      onAction: () => FirebaseAuth.instance.signOut(),
    );
  }
}

class _MessageScreen extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 68,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AuthWrapper._primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
