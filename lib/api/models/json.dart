/// Helpers de leitura tolerante de JSON (campo ausente ou malformado não quebra
/// a tela — contexto-prime.md §7).
typedef Json = Map<String, dynamic>;

String asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  return v.toString();
}

String? asStringOrNull(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? (double.tryParse(v)?.toInt() ?? fallback);
  return fallback;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) {
    final String s = v.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  if (v is num) return v != 0;
  return fallback;
}

bool? asBoolOrNull(dynamic v) {
  if (v == null) return null;
  return asBool(v);
}

Json? asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((key, value) => MapEntry(key.toString(), value));
  return null;
}

List<Json> asMapList(dynamic v) {
  if (v is! List) return const <Json>[];
  final List<Json> out = <Json>[];
  for (final dynamic e in v) {
    final Json? m = asMap(e);
    if (m != null) out.add(m);
  }
  return out;
}

List<String> asStringList(dynamic v) {
  if (v is! List) return const <String>[];
  return v.where((e) => e != null).map((e) => e.toString()).toList();
}

/// Remove chaves com valor nulo (para não enviar `null` em campos opcionais).
Json compact(Json json) {
  json.removeWhere((key, value) => value == null);
  return json;
}
