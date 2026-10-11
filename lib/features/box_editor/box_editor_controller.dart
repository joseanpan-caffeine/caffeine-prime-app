import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../core/analytics.dart';
import '../../data/providers.dart';
import '../../data/subscription_actions.dart';

/// Estado do editor de caixa. Preços só do `preview` (API); o app nunca soma.
class BoxEditorState {
  const BoxEditorState({
    required this.original,
    required this.items,
    required this.frequency,
    required this.originalFrequency,
    this.couponCode,
    this.giftHandles = const <String>[],
    this.nextCycleOnly = false,
    this.preview = const AsyncValue<PricePreview?>.data(null),
    this.submitting = false,
    this.initialized = false,
  });

  /// Itens atuais da assinatura (sem brindes), para calcular "alterações".
  final List<BoxItemInput> original;
  final List<BoxItemInput> items;
  final Frequency frequency;
  final Frequency originalFrequency;
  final String? couponCode;
  final List<String> giftHandles;
  final bool nextCycleOnly;
  final AsyncValue<PricePreview?> preview;
  final bool submitting;
  final bool initialized;

  int quantityOf(String handle) {
    for (final BoxItemInput i in items) {
      if (i.handle == handle) return i.quantity;
    }
    return 0;
  }

  BoxItemInput? itemOf(String handle) {
    for (final BoxItemInput i in items) {
      if (i.handle == handle) return i;
    }
    return null;
  }

  int get totalUnits => items.fold<int>(0, (int a, BoxItemInput b) => a + b.quantity);

  /// Número de itens adicionados/removidos/alterados em relação à caixa atual.
  int get changesCount {
    int n = 0;
    final Map<String, BoxItemInput> orig = <String, BoxItemInput>{for (final BoxItemInput i in original) i.handle: i};
    final Map<String, BoxItemInput> now = <String, BoxItemInput>{for (final BoxItemInput i in items) i.handle: i};
    for (final String h in <String>{...orig.keys, ...now.keys}) {
      final BoxItemInput? a = orig[h];
      final BoxItemInput? b = now[h];
      if (a == null || b == null) {
        n++;
      } else if (a.quantity != b.quantity || a.recurrence != b.recurrence) {
        n++;
      }
    }
    return n;
  }

  bool get hasChanges => changesCount > 0 || frequency != originalFrequency || giftHandles.isNotEmpty || (couponCode ?? '').isNotEmpty;

  /// Regra 60 dias: pelo menos um item com recorrência normal.
  bool get allSixtyDays => items.isNotEmpty && items.every((i) => i.recurrence != null && i.recurrence!.isSixtyDays);

  BoxEditorState copyWith({
    List<BoxItemInput>? items,
    Frequency? frequency,
    String? couponCode,
    bool clearCoupon = false,
    List<String>? giftHandles,
    bool? nextCycleOnly,
    AsyncValue<PricePreview?>? preview,
    bool? submitting,
  }) {
    return BoxEditorState(
      original: original,
      items: items ?? this.items,
      frequency: frequency ?? this.frequency,
      originalFrequency: originalFrequency,
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      giftHandles: giftHandles ?? this.giftHandles,
      nextCycleOnly: nextCycleOnly ?? this.nextCycleOnly,
      preview: preview ?? this.preview,
      submitting: submitting ?? this.submitting,
      initialized: initialized,
    );
  }
}

class BoxEditorController extends AutoDisposeNotifier<BoxEditorState> {
  Timer? _debounce;
  int _previewSeq = 0;
  bool _disposed = false;

  @override
  BoxEditorState build() {
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
    });
    return const BoxEditorState(
      original: <BoxItemInput>[],
      items: <BoxItemInput>[],
      frequency: Frequency.unknown,
      originalFrequency: Frequency.unknown,
    );
  }

  /// Inicializa a partir da assinatura corrente (idempotente).
  void initFrom(Subscription subscription, {String? addHandle}) {
    if (state.initialized) return;
    final List<BoxItemInput> items = subscription.items
        .where((i) => !i.gift)
        .map((i) => BoxItemInput(handle: i.handle, quantity: i.quantity, recurrence: i.recurrence))
        .toList();
    final List<BoxItemInput> original = List<BoxItemInput>.unmodifiable(items);
    List<BoxItemInput> current = List<BoxItemInput>.from(items);
    if (addHandle != null && addHandle.isNotEmpty && current.every((i) => i.handle != addHandle)) {
      current = <BoxItemInput>[...current, BoxItemInput(handle: addHandle, quantity: 1)];
    }
    state = BoxEditorState(
      original: original,
      items: current,
      frequency: subscription.frequency,
      originalFrequency: subscription.frequency,
      initialized: true,
    );
    if (addHandle != null) _schedulePreview();
  }

  void setQuantity(String handle, int quantity) {
    final List<BoxItemInput> items = List<BoxItemInput>.from(state.items);
    final int idx = items.indexWhere((i) => i.handle == handle);
    if (quantity <= 0) {
      if (idx >= 0) items.removeAt(idx);
    } else if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: quantity);
    } else {
      items.add(BoxItemInput(handle: handle, quantity: quantity));
    }
    state = state.copyWith(items: items);
    _schedulePreview();
  }

  void remove(String handle) => setQuantity(handle, 0);

  /// Troca o produto de um item (ex.: outro sabor), mantendo quantidade/recorrência.
  void replaceHandle(String oldHandle, String newHandle) {
    if (oldHandle == newHandle) return;
    final List<BoxItemInput> items = List<BoxItemInput>.from(state.items);
    final int idx = items.indexWhere((i) => i.handle == oldHandle);
    if (idx < 0) return;
    final int existing = items.indexWhere((i) => i.handle == newHandle);
    if (existing >= 0) {
      items[existing] = items[existing].copyWith(quantity: items[existing].quantity + items[idx].quantity);
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(handle: newHandle);
    }
    state = state.copyWith(items: items);
    _schedulePreview();
  }

  /// Alterna entre todo ciclo e 60 dias ('on' = entra no próximo ciclo).
  void toggleSixtyDays(String handle) {
    final List<BoxItemInput> items = List<BoxItemInput>.from(state.items);
    final int idx = items.indexWhere((i) => i.handle == handle);
    if (idx < 0) return;
    final BoxItemInput it = items[idx];
    final bool isSixty = it.recurrence != null && it.recurrence!.isSixtyDays;
    items[idx] = isSixty
        ? it.copyWith(recurrence: ItemRecurrence.everyCycle)
        : it.copyWith(recurrence: ItemRecurrence.on);
    state = state.copyWith(items: items);
    _schedulePreview();
  }

  void setFrequency(Frequency f) {
    state = state.copyWith(frequency: f);
    _schedulePreview();
  }

  void setCoupon(String? code) {
    final String? c = (code ?? '').trim().isEmpty ? null : code!.trim();
    state = c == null ? state.copyWith(clearCoupon: true) : state.copyWith(couponCode: c);
    _schedulePreview(immediate: true);
  }

  void toggleGift(String handle) {
    final List<String> gifts = List<String>.from(state.giftHandles);
    if (gifts.contains(handle)) {
      gifts.remove(handle);
    } else {
      gifts.add(handle);
    }
    state = state.copyWith(giftHandles: gifts);
  }

  void setNextCycleOnly(bool v) => state = state.copyWith(nextCycleOnly: v);

  void _schedulePreview({bool immediate = false}) {
    _debounce?.cancel();
    if (state.items.isEmpty) {
      state = state.copyWith(preview: const AsyncValue<PricePreview?>.data(null));
      return;
    }
    state = state.copyWith(preview: const AsyncValue<PricePreview?>.loading());
    _debounce = Timer(Duration(milliseconds: immediate ? 0 : 500), refreshPreview);
  }

  Future<void> refreshPreview() async {
    if (state.items.isEmpty) return;
    final int seq = ++_previewSeq;
    final PreviewRequest req = PreviewRequest(
      frequency: state.frequency,
      items: state.items,
      couponCode: state.couponCode,
    );
    try {
      final PricePreview p = await ref.read(subscriptionApiProvider).preview(req);
      if (_disposed || seq != _previewSeq) return; // resposta antiga
      state = state.copyWith(preview: AsyncValue<PricePreview?>.data(p));
      ref.read(analyticsProvider).track(AnalyticsEvents.boxEditPreview, params: <String, Object?>{'items': req.items.length});
    } catch (e, st) {
      if (_disposed || seq != _previewSeq) return;
      state = state.copyWith(preview: AsyncValue<PricePreview?>.error(e, st));
    }
  }

  /// Confirma a edição (POST /me/subscription/scheduling). Protegido contra
  /// toque duplo por `submitting` + Idempotency-Key.
  Future<ScheduledChange> confirm({String? reason}) async {
    if (state.submitting) {
      throw const ApiError(code: 'BUSY', message: 'Aguarde, já estamos salvando sua caixa.');
    }
    if (state.items.isEmpty) {
      throw const ApiError(code: 'EMPTY_BOX', message: 'Sua caixa precisa ter pelo menos um item.');
    }
    if (state.allSixtyDays) {
      throw const ApiError(
        code: 'ALL_SIXTY_DAYS',
        message: 'Pelo menos um item precisa ter recorrência normal (todo ciclo).',
      );
    }
    state = state.copyWith(submitting: true);
    try {
      final ScheduledChange result = await ref.read(subscriptionActionsProvider).schedule(
            SchedulingRequest(
              frequency: state.frequency,
              items: state.items,
              couponCode: state.couponCode,
              giftHandles: state.giftHandles.isEmpty ? null : state.giftHandles,
              nextCycleOnly: state.nextCycleOnly ? true : null,
              reason: reason,
            ),
          );
      return result;
    } finally {
      if (!_disposed) state = state.copyWith(submitting: false);
    }
  }
}

final AutoDisposeNotifierProvider<BoxEditorController, BoxEditorState> boxEditorProvider =
    NotifierProvider.autoDispose<BoxEditorController, BoxEditorState>(BoxEditorController.new);
