import 'package:flutter/material.dart';

class CenterToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isError = true,
    bool isElderMode = false,
  }) {
    _dismiss();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        isError: isError,
        isElderMode: isElderMode,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isElderMode;
  final Duration duration;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.isElderMode,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 220), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.isElderMode;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.symmetric(
                horizontal: 28,
                vertical: isElder ? 22 : 18,
              ),
              decoration: BoxDecoration(
                color: widget.isError
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: isElder ? 28 : 24,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isElder ? 19 : 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
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
