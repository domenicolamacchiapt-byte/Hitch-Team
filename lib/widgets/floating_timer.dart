import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class FloatingTimerOverlay extends StatelessWidget {
  final Widget child;

  const FloatingTimerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<TimerProvider>(
          builder: (context, timer, _) {
            if (timer.remainingSeconds <= 0 && !timer.isRinging) return const SizedBox.shrink();

            return Positioned(
              bottom: 80, // Abbastanza in alto per non coprire FAB o navigazione
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: timer.isRinging ? Colors.redAccent.withValues(alpha: 0.9) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: timer.isRinging ? Colors.white : const Color(0xFFFF9800), width: 2),
                      boxShadow: [
                        BoxShadow(color: timer.isRinging ? Colors.redAccent.withValues(alpha: 0.5) : Colors.black54, blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: timer.isRinging 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'RECUPERO FINITO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.stop, color: Colors.redAccent, size: 24),
                                onPressed: timer.stopRinging,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: Color(0xFFFF9800), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              timer.formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                              child: IconButton(
                                icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow, color: const Color(0xFFFF9800)),
                                onPressed: () {
                                  if (timer.isRunning) timer.pauseTimer();
                                  else timer.resumeTimer();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: timer.stop,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
