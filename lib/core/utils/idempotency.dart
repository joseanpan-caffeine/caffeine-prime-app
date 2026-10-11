import 'dart:math';

/// Gera UUID v4 sem dependência externa, para o header `Idempotency-Key`
/// das mutações (contexto-prime.md §8 item 3: toque duplo/retry não pode gerar
/// ação dupla).
String uuidV4() {
  final Random rnd = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // versão 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variante RFC 4122
  final String hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
