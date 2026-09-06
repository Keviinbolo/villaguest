import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Envuelve [child] y superpone un banner fijo cuando el dispositivo
/// pierde conectividad de red (wifi/datos). No garantiza que haya
/// internet real, solo que el dispositivo está desconectado de toda red.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivity.checkConnectivity().then(_onResults);
    _subscription =
        _connectivity.onConnectivityChanged.listen(_onResults);
  }

  void _onResults(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (isOffline != _isOffline) setState(() => _isOffline = isOffline);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isOffline ? _buildBanner(context) : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.error,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off,
                  size: 18, color: Theme.of(context).colorScheme.onError),
              const SizedBox(width: 8),
              Text(
                'Sin conexión a internet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
