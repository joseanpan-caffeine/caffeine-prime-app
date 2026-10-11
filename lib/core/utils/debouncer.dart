import 'dart:async';

/// Debounce simples para a prévia de preço do editor de caixa.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
