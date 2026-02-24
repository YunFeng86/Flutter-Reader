import 'dart:async';
import 'dart:collection';

enum AiRequestPriority { foreground, background }

class AiRequestQueue {
  AiRequestQueue({this.maxConcurrent = 2});

  final int maxConcurrent;

  int _tpmLimit = 0;
  final Queue<_QueuedTask<dynamic>> _foreground = Queue<_QueuedTask<dynamic>>();
  final Queue<_QueuedTask<dynamic>> _background = Queue<_QueuedTask<dynamic>>();
  final List<_TokenUsage> _usage = <_TokenUsage>[];
  Timer? _timer;
  var _running = 0;
  var _pumping = false;

  void updateTpmLimit(int limit) {
    final next = limit < 0 ? 0 : limit;
    if (_tpmLimit == next) return;
    _tpmLimit = next;
    _pump();
  }

  Future<T> schedule<T>({
    required int estimatedTokens,
    required AiRequestPriority priority,
    required Future<T> Function() task,
    void Function()? onStart,
  }) {
    final completer = Completer<T>();
    final tokens = estimatedTokens <= 0 ? 1 : estimatedTokens;
    final item = _QueuedTask<T>(
      estimatedTokens: tokens,
      run: task,
      completer: completer,
      onStart: onStart,
    );
    switch (priority) {
      case AiRequestPriority.foreground:
        _foreground.add(item);
      case AiRequestPriority.background:
        _background.add(item);
    }
    _pump();
    return completer.future;
  }

  void _pump() {
    if (_pumping) return;
    _pumping = true;
    unawaited(Future<void>.microtask(() async {
      try {
        _timer?.cancel();
        _timer = null;
        _pruneUsage();

        while (_running < maxConcurrent) {
          final next = _nextTask();
          if (next == null) return;

          final now = DateTime.now();
          final delay = _delayFor(next.estimatedTokens, now: now);
          if (delay > Duration.zero) {
            _timer = Timer(delay, _pump);
            return;
          }

          _start(next, now: now);
        }
      } finally {
        _pumping = false;
      }
    }));
  }

  _QueuedTask<dynamic>? _nextTask() {
    if (_foreground.isNotEmpty) return _foreground.removeFirst();
    if (_background.isNotEmpty) return _background.removeFirst();
    return null;
  }

  void _start(_QueuedTask<dynamic> item, {required DateTime now}) {
    _running++;
    _usage.add(_TokenUsage(time: now, tokens: item.estimatedTokens));
    item.onStart?.call();
    unawaited(
      item
          .run()
          .then((value) => item.completer.complete(value))
          .catchError((e, s) => item.completer.completeError(e, s))
          .whenComplete(() {
            _running--;
            _pump();
          }),
    );
  }

  void _pruneUsage() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 60));
    _usage.removeWhere((e) => e.time.isBefore(cutoff));
  }

  Duration _delayFor(int tokens, {required DateTime now}) {
    final limit = _tpmLimit;
    if (limit <= 0) return Duration.zero;
    if (_usage.isEmpty) return Duration.zero;

    var used = 0;
    for (final e in _usage) {
      used += e.tokens;
    }

    // If a single request exceeds the budget, allow it once the window clears.
    if (tokens > limit) {
      if (used == 0) return Duration.zero;
      final lastExpiry = _usage.last.time.add(const Duration(seconds: 60));
      final d = lastExpiry.difference(now);
      return d.isNegative ? Duration.zero : d;
    }

    if (used + tokens <= limit) return Duration.zero;

    // Wait until enough tokens expire from the sliding window.
    final needToFree = used + tokens - limit;
    var freed = 0;
    for (final e in _usage) {
      freed += e.tokens;
      if (freed >= needToFree) {
        final expiry = e.time.add(const Duration(seconds: 60));
        final d = expiry.difference(now);
        return d.isNegative ? Duration.zero : d;
      }
    }

    final lastExpiry = _usage.last.time.add(const Duration(seconds: 60));
    final d = lastExpiry.difference(now);
    return d.isNegative ? Duration.zero : d;
  }
}

class _TokenUsage {
  const _TokenUsage({required this.time, required this.tokens});

  final DateTime time;
  final int tokens;
}

class _QueuedTask<T> {
  const _QueuedTask({
    required this.estimatedTokens,
    required this.run,
    required this.completer,
    required this.onStart,
  });

  final int estimatedTokens;
  final Future<T> Function() run;
  final Completer<T> completer;
  final void Function()? onStart;
}
