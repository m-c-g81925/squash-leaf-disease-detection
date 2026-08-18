import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../calendar/calendar_screen.dart';
import '../disease/disease_library_screen.dart';
import '../expert_review/expert_review_requests_screen.dart';
import '../home/home_screen.dart';
import '../profile/farmer_profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../../auth_wrapper.dart';
import '../scan/scan_history_screen.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onTabChange: _switchTab),
    const ScanScreen(),
    const CalendarScreen(),
    const DiseaseLibraryScreen(),
    const ScanHistoryScreen(),
    const ExpertReviewRequestsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _screenTitles = [
    'Home',
    'Scan for Disease',
    'Planting Calendar',
    'Disease Library',
    'Scan History',
    'Expert Review Requests',
    'Settings',
  ];

  void _switchTab(int index) {
    if (index < 0 || index >= _screens.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _selectDrawerPage(
    BuildContext context,
    int index,
  ) {
    Navigator.pop(context);

    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openFarmerProfile(
    BuildContext context,
  ) async {
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FarmerProfileScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF179E43),
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthWrapper(),
      ),
      (route) => false,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: Text(
          _screenTitles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE2E7E3),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFAFBF9),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  children: [
                    _drawerItem(
                      context: context,
                      index: 0,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      title: 'Home',
                    ),
                    _drawerItem(
                      context: context,
                      index: 1,
                      icon: Icons.camera_alt_outlined,
                      selectedIcon: Icons.camera_alt,
                      title: 'Scan for Disease',
                    ),
                    _drawerItem(
                      context: context,
                      index: 2,
                      icon: Icons.calendar_today_outlined,
                      selectedIcon: Icons.calendar_today,
                      title: 'Planting Calendar',
                    ),
                    _drawerItem(
                      context: context,
                      index: 3,
                      icon: Icons.menu_book_outlined,
                      selectedIcon: Icons.menu_book,
                      title: 'Disease Library',
                    ),
                    _drawerItem(
                      context: context,
                      index: 4,
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      title: 'Scan History',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Divider(),
                    ),
                    _drawerItem(
                      context: context,
                      index: 5,
                      icon: Icons.support_agent_outlined,
                      selectedIcon: Icons.support_agent,
                      title: 'Expert Review Requests',
                    ),
                    _drawerItem(
                      context: context,
                      index: 6,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      title: 'Settings',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                leading: const Icon(
                  Icons.logout,
                  color: Color(0xFFB3261E),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('farmer_profiles')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> profile =
            snapshot.data?.data() ?? <String, dynamic>{};

        final String farmerName =
            profile['farmerName']?.toString().trim() ?? '';

        final String municipality =
            profile['municipality']?.toString().trim() ?? '';

        final bool hasProfile = farmerName.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openFarmerProfile(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                16,
                24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF179E43),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: hasProfile
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF179E43),
                            size: 36,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.eco,
                                  color: Color(0xFF179E43),
                                  size: 34,
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasProfile
                              ? farmerName
                              : 'Squash Leaf Disease Detection',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          municipality.isNotEmpty
                              ? municipality
                              : hasProfile
                                  ? 'Tap to view farmer profile'
                                  : 'Disease Detection and Planting Calendar',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE7F4EA),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFE7F4EA),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final bool isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: ListTile(
        minTileHeight: 48,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected
              ? const Color(0xFF179E43)
              : const Color(0xFF5D675F),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF179E43)
                : const Color(0xFF253029),
            fontWeight: isSelected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF179E43),
              )
            : null,
        selected: isSelected,
        selectedTileColor: const Color(0xFFEAF5ED),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          _selectDrawerPage(context, index);
        },
      ),
    );
  }
}
