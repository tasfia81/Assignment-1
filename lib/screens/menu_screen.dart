import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/db_service.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _downloadCount = 0;
  String _networkStatus = 'Checking...';
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionText(results);
    });
  }

  Future<void> _loadStats() async {
    final downloads = await DbService.getDownloadedMovies();
    if (mounted) {
      setState(() {
        _downloadCount = downloads.length;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionText(results);
  }

  void _updateConnectionText(List<ConnectivityResult> results) {
    String status = 'Offline';
    if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
      if (results.contains(ConnectivityResult.wifi)) {
        status = 'Wi-Fi Connected';
      } else if (results.contains(ConnectivityResult.mobile)) {
        status = 'Cellular Connected';
      } else {
        status = 'Online';
      }
    }
    if (mounted) {
      setState(() {
        _networkStatus = status;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 100.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //============================ Custom Profile Card Widget ====================================
            const ProfileCard(
              name: 'Tasfia Sumiya',
              role: 'Flutter Developer',
            ),
            SizedBox(height: 24.h),

            //=========================== Diagnostic Section ============================================
            _buildSectionHeader('Diagnostics'),
            SizedBox(height: 8.h),
            SettingsTile(
              icon: Icons.network_check_rounded,
              title: 'Connection Status',
              subtitle: _networkStatus,
              iconColor: Colors.blueAccent,
            ),
            SizedBox(height: 24.h),

            //=========================== Storage Section ===============================================
            _buildSectionHeader('Storage & Cache'),
            SizedBox(height: 8.h),
            SettingsTile(
              icon: Icons.download_done_rounded,
              title: 'Offline Video Files',
              subtitle: '$_downloadCount movie(s) saved',
              iconColor: Colors.green,
            ),
            SizedBox(height: 8.h),
            SettingsTile(
              icon: Icons.cleaning_services_rounded,
              title: 'Clear Catalog Cache',
              subtitle: 'Free up local search index cache',
              iconColor: Colors.amber,
              onTap: () async {
                await DbService.clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catalog cache cleared successfully.'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 24.h),

            //================================ Info Section ==============================================
            _buildSectionHeader('Application Info'),
            SizedBox(height: 8.h),
            const SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: '1.0.0 (Release Build)',
              iconColor: Colors.purpleAccent,
            ),
            SizedBox(height: 8.h),
            const SettingsTile(
              icon: Icons.assignment_ind_outlined,
              title: 'Developer Role',
              subtitle: 'Mobile Engineering Intern Challenge',
              iconColor: Colors.pinkAccent,
            ),
            SizedBox(height: 8.h),
            SettingsTile(
              icon: Icons.link_rounded,
              title: 'GitHub Profile',
              subtitle: 'github.com/tasfia81',
              iconColor: Colors.tealAccent,
              onTap: () async {
                final Uri url = Uri.parse('https://github.com/tasfia81');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
