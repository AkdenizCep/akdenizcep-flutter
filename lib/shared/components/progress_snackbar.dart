import 'package:flutter/material.dart';

/// Alt kısmında, gösterim süresi boyunca dolu başlayıp boşalan ince bir
/// ilerleme çizgisi olan, süresi bitince otomatik kapanan bildirim.
///
/// [messenger] verilirse `context`'ten türetilen yerine o kullanılır — bir
/// `await` sırasında context'in ağaçtan kaldırılma ihtimali olan akışlarda
/// (`await`'ten önce yakalanmış bir messenger ile) güvenli kullanım sağlar.
void showProgressSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  IconData icon = Icons.check_circle_rounded,
  Color? accentColor,
  ScaffoldMessengerState? messenger,
  EdgeInsets? margin,
}) {
  final resolvedMessenger = messenger ?? ScaffoldMessenger.of(context);
  resolvedMessenger.clearSnackBars();
  resolvedMessenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: margin,
      content: _ProgressSnackBarContent(
        message: message,
        duration: duration,
        icon: icon,
        accentColor: accentColor,
      ),
    ),
  );
}

class _ProgressSnackBarContent extends StatefulWidget {
  final String message;
  final Duration duration;
  final IconData icon;
  final Color? accentColor;

  const _ProgressSnackBarContent({
    required this.message,
    required this.duration,
    required this.icon,
    required this.accentColor,
  });

  @override
  State<_ProgressSnackBarContent> createState() =>
      _ProgressSnackBarContentState();
}

class _ProgressSnackBarContentState extends State<_ProgressSnackBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = widget.accentColor ?? colorScheme.primary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(widget.icon, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: 1 - _controller.value,
                minHeight: 3,
                backgroundColor: colorScheme.onInverseSurface.withValues(
                  alpha: 0.16,
                ),
                valueColor: AlwaysStoppedAnimation(accentColor),
              );
            },
          ),
        ],
      ),
    );
  }
}
