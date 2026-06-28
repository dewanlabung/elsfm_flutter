import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/sleep_timer_service.dart';

/// Sleep timer button with preset duration selection.
///
/// Shows current timer status and opens a dialog for timer duration selection.
class SleepTimerButton extends ConsumerWidget {
  final VoidCallback? onTimerStarted;

  const SleepTimerButton({
    this.onTimerStarted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(sleepTimerRunningProvider);
    final remaining = ref.watch(sleepTimerRemainingProvider);
    final service = ref.watch(sleepTimerServiceProvider);

    String? displayText;
    if (isRunning && remaining.value != null) {
      final totalSeconds = remaining.value?.inSeconds ?? 0;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      displayText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    return Column(
      children: [
        IconButton(
          icon: Icon(
            isRunning ? Icons.timer : Icons.timer_outlined,
            color: isRunning ? Colors.blue : null,
          ),
          onPressed: () => _showSleepTimerDialog(context, ref),
          tooltip: isRunning ? 'Sleep timer active' : 'Set sleep timer',
        ),
        if (displayText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              displayText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sleepTimerRunningProvider.notifier);
    final service = ref.read(sleepTimerServiceProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sleep Timer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (service.isRunning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Timer running: ${_formatDuration(service.remainingTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            const Divider(),
            _TimerOption(
              minutes: 5,
              label: '5 minutes',
              onTap: () {
                Navigator.pop(context);
                notifier.startTimer(Duration(minutes: 5), onTimerStarted ?? () {});
              },
            ),
            _TimerOption(
              minutes: 10,
              label: '10 minutes',
              onTap: () {
                Navigator.pop(context);
                notifier.startTimer(Duration(minutes: 10), onTimerStarted ?? () {});
              },
            ),
            _TimerOption(
              minutes: 15,
              label: '15 minutes',
              onTap: () {
                Navigator.pop(context);
                notifier.startTimer(Duration(minutes: 15), onTimerStarted ?? () {});
              },
            ),
            _TimerOption(
              minutes: 30,
              label: '30 minutes',
              onTap: () {
                Navigator.pop(context);
                notifier.startTimer(Duration(minutes: 30), onTimerStarted ?? () {});
              },
            ),
            _TimerOption(
              minutes: 60,
              label: '1 hour',
              onTap: () {
                Navigator.pop(context);
                notifier.startTimer(Duration(hours: 1), onTimerStarted ?? () {});
              },
            ),
            if (service.isRunning) ...[
              const Divider(),
              ListTile(
                title: const Text('Cancel Timer'),
                trailing: const Icon(Icons.close),
                onTap: () {
                  Navigator.pop(context);
                  notifier.cancelTimer();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TimerOption extends StatelessWidget {
  final int minutes;
  final String label;
  final VoidCallback onTap;

  const _TimerOption({
    required this.minutes,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
