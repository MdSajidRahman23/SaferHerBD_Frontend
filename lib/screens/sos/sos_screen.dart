import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/sos_service.dart';
import '../../utils/constants.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _sos = SosService();

  late AnimationController _pulseCtrl;
  Timer? _countdownTimer;

  int _countdown = 0;     // 0 = idle, otherwise seconds remaining
  bool _dispatching = false;
  bool _dispatched = false;
  String _statusMsg = '';
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _countdown = 3;
      _statusMsg = 'Hold on… SOS sending in $_countdown';
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
          _dispatchNow();
        } else {
          HapticFeedback.lightImpact();
          _statusMsg = 'SOS in $_countdown…';
        }
      });
    });
  }

  void _cancelCountdown() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 0;
      _statusMsg = 'Cancelled.';
    });
  }

  Future<void> _dispatchNow() async {
    setState(() {
      _dispatching = true;
      _statusMsg = 'Getting your location…';
    });

    Position? pos;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      
      // Geolocator v12.0.0+ syntax
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      try { 
        pos = await Geolocator.getLastKnownPosition(); 
      } catch (_) {}
    }

    if (pos == null) {
      setState(() {
        _dispatching = false;
        _statusMsg = 'Could not get location. Please enable GPS and retry.';
      });
      return;
    }

    setState(() => _statusMsg = 'Dispatching to your contacts…');

    // UPDATE: Fixed parameter names to match SosService definition
    final result = await _sos.trigger(
      lat: pos.latitude,        // 'latitude' changed to 'lat'
      lng: pos.longitude,       // 'longitude' changed to 'lng'
      triggerMethod: 'manual_button',
    );

    if (!mounted) return;
    setState(() {
      _dispatching = false;
      _dispatched = true;
      _lastResult = result;
      
      // 'success' logic based on your SosService return values
      if (result['success'] == true && result['offline'] != true) {
        final notified = result['notified_contacts_count'] ?? 0;
        final total    = result['total_contacts'] ?? 0;
        _statusMsg = 'Alert sent. $notified of $total contacts notified.';
        HapticFeedback.heavyImpact();
      } else if (result['offline'] == true) {
        _statusMsg = 'Saved offline. Will retry when network returns.';
      } else {
        _statusMsg = result['message']?.toString() ?? 'Could not send. Please try again.';
      }
    });
  }

  void _reset() {
    setState(() {
      _dispatched = false;
      _statusMsg = '';
      _lastResult = null;
      _countdown = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (_dispatched)
                TextButton(
                  onPressed: _reset,
                  child: Text('New', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ),
            ]),
          ),
          Expanded(
            child: Center(
              child: _dispatched ? _buildResult() : _buildButton(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _statusMsg.isEmpty
                  ? 'Tap and hold to start SOS countdown.\nRelease to cancel within 3s.'
                  : _statusMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white70, fontSize: 13, height: 1.6),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onLongPressStart: (_) {
        if (!_dispatching && _countdown == 0) _startCountdown();
      },
      onLongPressEnd: (_) {
        if (_countdown > 0) _cancelCountdown();
      },
      // Fallback for tap if needed, though long press is safer for SOS
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final scale = 1.0 + (_pulseCtrl.value * 0.08);
          final glowAmount = 30.0 + (_pulseCtrl.value * 25);
          return Stack(alignment: Alignment.center, children: [
            Container(
              width: 220 * scale, height: 220 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.red.withOpacity(0.18 * (1 - _pulseCtrl.value)),
              ),
            ),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.red, Color(0xFFC41E32)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.red.withOpacity(0.7), blurRadius: glowAmount),
                ],
              ),
              child: Center(
                child: _dispatching
                    ? const SizedBox(
                        width: 56, height: 56,
                        child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                      )
                    : _countdown > 0
                        ? Text('$_countdown',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 84))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.shield, color: Colors.white, size: 56),
                            const SizedBox(height: 6),
                            Text('SOS',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    letterSpacing: 4)),
                          ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildResult() {
    final ok = _lastResult?['success'] == true && _lastResult?['offline'] != true;
    final queued = _lastResult?['offline'] == true;
    final notified = _lastResult?['notified_contacts_count'] ?? 0;
    final total = _lastResult?['total_contacts'] ?? 0;
    final color = ok ? AppColors.green : (queued ? AppColors.amber : AppColors.red);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(
            ok ? Icons.check_circle : (queued ? Icons.cloud_off : Icons.error_outline),
            color: color, size: 40,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          ok ? 'Alert Sent' : (queued ? 'Saved Offline' : 'Failed'),
          style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 6),
        if (ok)
          Text('Notified $notified of $total contacts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13))
        else if (queued)
          Text('Will auto-retry when you reconnect.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13))
        else
          Text(_statusMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.ink2, fontSize: 13)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bg,
                foregroundColor: AppColors.ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pushNamed(context, '/sos-history'),
              icon: const Icon(Icons.history, size: 16),
              label: Text('History', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Done',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ]),
      ]),
    );
  }
}
