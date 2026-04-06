import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smartmeal/core/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  
  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<_NavItem> _navItems = [
    _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_15, label: 'Home', path: '/'),
    _NavItem(icon: Iconsax.scan, activeIcon: Iconsax.scan, label: 'Kühlschrank', path: '/fridge'),
    _NavItem(icon: Iconsax.discount_shape, activeIcon: Iconsax.discount_shape5, label: 'Angebote', path: '/deal-recipes'),
    _NavItem(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_25, label: 'Einstellungen', path: '/settings'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/cart'),
            customBorder: const CircleBorder(),
            child: const Center(
              child: Icon(
                Iconsax.shopping_cart,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left items (Home, Fridge)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavBarItem(
                          icon: _currentIndex == 0 ? _navItems[0].activeIcon : _navItems[0].icon,
                          label: '',
                          isSelected: _currentIndex == 0,
                          onTap: () {
                            setState(() => _currentIndex = 0);
                            context.go(_navItems[0].path);
                          },
                        ),
                        _NavBarItem(
                          icon: _currentIndex == 1 ? _navItems[1].activeIcon : _navItems[1].icon,
                          label: '',
                          isSelected: _currentIndex == 1,
                          onTap: () {
                            setState(() => _currentIndex = 1);
                            context.go(_navItems[1].path);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Spacer for FAB
                  const SizedBox(width: 64),
                  // Right items (Deals, Settings)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavBarItem(
                          icon: _currentIndex == 2 ? _navItems[2].activeIcon : _navItems[2].icon,
                          label: '',
                          isSelected: _currentIndex == 2,
                          onTap: () {
                            setState(() => _currentIndex = 2);
                            context.go(_navItems[2].path);
                          },
                        ),
                        _NavBarItem(
                          icon: _currentIndex == 3 ? _navItems[3].activeIcon : _navItems[3].icon,
                          label: '',
                          isSelected: _currentIndex == 3,
                          onTap: () {
                            setState(() => _currentIndex = 3);
                            context.go(_navItems[3].path);
                          },
                        ),
                      ],
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  
  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
