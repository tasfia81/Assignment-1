import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showBanner = false;
  bool _wasOffline = false;

  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    //------------------------------- Listen to network changes ----------------------------------
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool isOfflineNow = results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);

      if (isOfflineNow != _isOffline) {
        setState(() {
          _isOffline = isOfflineNow;
          _showBanner = true;
          if (_isOffline) {
            _wasOffline = true;
            _animController.forward();
          } else {
            if (_wasOffline) {
              //-------------------- Restore connection: flash green, then hide ---------------------------------
              _animController.forward();
              Timer(const Duration(seconds: 2), () {
                if (mounted && !_isOffline) {
                  _animController.reverse().then((_) {
                    setState(() {
                      _showBanner = false;
                    });
                  });
                }
              });
            } else {
              _showBanner = false;
              _animController.reverse();
            }
          }
        });
      }
    });

    //---------------------- Check initial connectivity ------------------------------------

    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    final bool isOfflineNow = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
    if (isOfflineNow) {
      setState(() {
        _isOffline = true;
        _showBanner = true;
        _wasOffline = true;
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    final Color bgColor = _isOffline ? Colors.red.shade900 : Colors.green.shade800;
    final String message = _isOffline
        ? 'No Internet Connection. Playing cached/downloaded items.'
        : 'Back Online. Syncing catalog...';
    final IconData icon = _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded;

    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        elevation: 10,
        child: Container(
          width: double.infinity,
          color: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
