import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_notifier.dart';

class IdleTimeoutWrapper extends StatefulWidget {
  final Widget child;
  const IdleTimeoutWrapper({super.key, required this.child});

  @override
  State<IdleTimeoutWrapper> createState() => _IdleTimeoutWrapperState();
}

class _IdleTimeoutWrapperState extends State<IdleTimeoutWrapper> {
  Timer? _timer;

  static const Duration _idleTimeout = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    final authNotifier = context.read<AuthNotifier>();
 
    if (authNotifier.isAuthenticated) {
      _timer = Timer(_idleTimeout, () => _onIdleTimeout(authNotifier));
    }
  }

  void _onIdleTimeout(AuthNotifier authNotifier) {
    if (!authNotifier.isAuthenticated) return;

    authNotifier.logout();
    
    if (mounted) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сеанс завершен из-за 3 минут бездействия'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}