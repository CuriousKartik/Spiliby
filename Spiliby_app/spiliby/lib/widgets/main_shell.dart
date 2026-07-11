import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../pages/home_page.dart';
import '../pages/groups_page.dart';
import '../pages/friends_page.dart';
import '../pages/settings_page.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget page;
  const _Tab(this.label, this.icon, this.page);
}

final _tabs = [
  _Tab('Home', Icons.home_rounded, const HomePage()),
  _Tab('Groups', Icons.groups_rounded, const GroupsPage()),
  _Tab('Friends', Icons.people_alt_rounded, const FriendsPage()),
  _Tab('Settings', Icons.settings_rounded, const SettingsPage()),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tabs[index].page,
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      style: AppFonts.body(size: 11, color: c.inactiveNav),
                      children: [
                        const TextSpan(text: 'Made with '),
                        TextSpan(text: '♥', style: TextStyle(color: c.danger)),
                        const TextSpan(text: ' by Kartikey & Junaid'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Free to use · no passwords · no copying as your own',
                    textAlign: TextAlign.center,
                    style: AppFonts.body(size: 10, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: c.navBg,
            border: Border(top: BorderSide(color: c.navBorder)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _tabs.length; i++)
                _NavItem(
                  tab: _tabs[i],
                  active: i == index,
                  onTap: () => setState(() => index = i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final color = active ? c.accentHover : c.inactiveNav;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(tab.label, style: AppFonts.body(size: 11, weight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}