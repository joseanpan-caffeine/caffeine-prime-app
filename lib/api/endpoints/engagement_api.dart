import '../api_client.dart';
import '../api_error.dart';
import '../models/assistant.dart';
import '../models/health.dart';
import '../models/json.dart';
import '../models/routine.dart';

/// Rotina (frente 2): GET/PUT /me/routine, check-ins e resumo.
class RoutineApi {
  RoutineApi(this._client);

  final ApiClient _client;

  /// 404 = ainda sem plano → plano vazio.
  Future<RoutinePlan> plan() async {
    try {
      return RoutinePlan.fromJson(await _client.getJson('/me/routine'));
    } on ApiError catch (e) {
      if (e.isNotFound) return RoutinePlan.empty;
      rethrow;
    }
  }

  Future<RoutinePlan> updatePlan(UpdateRoutinePlanRequest req) async {
    return RoutinePlan.fromJson(await _client.putJson('/me/routine', body: req.toJson()));
  }

  Future<CheckIn> checkIn(CheckInRequest req) async {
    return CheckIn.fromJson(await _client.postJson('/me/routine/check-ins', body: req.toJson()));
  }

  /// Desfaz o check-in do item na data (DELETE com corpo; o BFF também aceita
  /// query string — enviamos os dois para compatibilidade).
  Future<void> undoCheckIn(CheckInRequest req) async {
    final Json body = req.toJson();
    await _client.delete(
      '/me/routine/check-ins?routineItemId=${Uri.encodeQueryComponent(req.routineItemId)}&date=${Uri.encodeQueryComponent(req.date)}',
      body: body,
    );
  }

  Future<RoutineSummary> summary() async {
    return RoutineSummary.fromJson(await _client.getJson('/me/routine/summary'));
  }
}

/// Saúde / wearables (frente 2).
class HealthApi {
  HealthApi(this._client);

  final ApiClient _client;

  Future<HealthSummary> sync(HealthSyncRequest req) async {
    final Json json = await _client.postJson('/me/health/sync', body: req.toJson());
    // O BFF pode responder 202 sem corpo; nesse caso buscamos o resumo.
    if (json.isEmpty) return summary();
    return HealthSummary.fromJson(json);
  }

  Future<HealthSummary> summary() async {
    try {
      return HealthSummary.fromJson(await _client.getJson('/me/health/summary'));
    } on ApiError catch (e) {
      if (e.isNotFound) return HealthSummary.disconnected;
      rethrow;
    }
  }
}

/// Assistente (frente 5: Prime IA).
class AssistantApi {
  AssistantApi(this._client);

  final ApiClient _client;

  Future<AssistantConfig> config() async {
    return AssistantConfig.fromJson(await _client.getJson('/assistant/config'));
  }

  Future<List<AssistantThread>> threads() async {
    final dynamic data = await _client.getRaw('/me/assistant/threads');
    if (data is List) return asMapList(data).map(AssistantThread.fromJson).toList();
    final Json? json = asMap(data);
    if (json != null && json['threads'] is List) {
      return asMapList(json['threads']).map(AssistantThread.fromJson).toList();
    }
    if (json != null && json['items'] is List) {
      return asMapList(json['items']).map(AssistantThread.fromJson).toList();
    }
    return <AssistantThread>[];
  }

  Future<AssistantThread> thread(String id) async {
    return AssistantThread.fromJson(await _client.getJson('/me/assistant/threads/$id'));
  }

  Future<void> deleteThread(String id) async => _client.delete('/me/assistant/threads/$id');

  /// POST /me/assistant/messages. 429 = limite diário.
  Future<AssistantSendResponse> send(AssistantSendRequest req) async {
    return AssistantSendResponse.fromJson(await _client.postJson('/me/assistant/messages', body: req.toJson()));
  }
}
