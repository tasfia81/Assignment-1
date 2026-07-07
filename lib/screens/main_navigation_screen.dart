import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'catalog_screen.dart';
import 'favorites_screen.dart';
import 'downloads_screen.dart';
import 'menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CatalogScreen(),
    FavoritesScreen(),
    DownloadsScreen(),
    MenuScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body content to scroll behind the floating bar
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h, left: 20.w, right: 20.w),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xEE161622), // Highly premium translucent dark tone
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withAlpha(20),
              width: 1.h,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(102),
                blurRadius: 16.r,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.purpleAccent,
              unselectedItemColor: Colors.white38,
              selectedFontSize: 11.sp,
              unselectedFontSize: 10.sp,
              iconSize: 22.r,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded, color: Colors.purpleAccent),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_rounded),
                  activeIcon: Icon(Icons.favorite_rounded, color: Colors.purpleAccent),
                  label: 'Favorites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.download_for_offline_rounded),
                  activeIcon: Icon(Icons.download_for_offline_rounded, color: Colors.purpleAccent),
                  label: 'Downloads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_rounded),
                  activeIcon: Icon(Icons.menu_rounded, color: Colors.purpleAccent),
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
