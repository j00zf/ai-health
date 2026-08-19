import 'dart:async';
import 'package:flutter/material.dart';

class HealthSyncScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() onSync;
  final bool force;

  const HealthSyncScreen({
    super.key,
    required this.onSync,
    this.force = false,
  });

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _messageTimer;
  int _messageIndex = 0;
  bool _failed = false;
  String? _error;
  Map<String, dynamic>? _result;

  final _messages = const [
    'Connecting to Google Health…',
    'Checking your sync points…',
    'Comparing new health records…',
    'Updating Pulse AI database…',
    'Saving a local copy for faster access…',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted && !_failed && _result == null) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });
    _run();
  }

  Future<void> _run() async {
    try {
      final result = await widget.onSync();
      if (!mounted) return;
      setState(() => _result = result);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newCount = (_result?['newRecords'] ?? 0).toString();
    final updatedCount = (_result?['updatedRecords'] ?? 0).toString();

    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Transform.rotate(
                    angle: _controller.value * 6.28318,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff6c5ce7), Color(0xff12c2e9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff6c5ce7).withOpacity(.25),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  _failed
                      ? 'Health sync paused'
                      : _result != null
                          ? 'Health sync complete'
                          : 'Syncing your health',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff20243a),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (_failed)
                  Text(
                    _error ?? 'Unable to sync Google Health.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  )
                else if (_result != null)
                  Text(
                    '$newCount new records • $updatedCount updated records',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  )
                else
                  Text(
                    _messages[_messageIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  ),
                const SizedBox(height: 28),
                if (!_failed && _result == null)
                  const SizedBox(
                    width: 230,
                    child: LinearProgressIndicator(minHeight: 5),
                  ),
                if (_failed) ...[
                  const SizedBox(height: 26),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _failed = false;
                        _error = null;
                        _result = null;
                        _messageIndex = 0;
                      });
                      _run();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Use saved health data'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
