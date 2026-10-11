import 'common.dart';
import 'json.dart';

class AssistantMessage {
  const AssistantMessage({required this.id, required this.role, required this.content, required this.createdAt});

  final String id;
  final AssistantRole role;
  final String content;
  final String createdAt;

  bool get isUser => role == AssistantRole.user;

  factory AssistantMessage.fromJson(Json json) => AssistantMessage(
        id: asString(json['id']),
        role: AssistantRole.parse(json['role']),
        content: asString(json['content']),
        createdAt: asString(json['createdAt']),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'role': role.wire,
        'content': content,
        'createdAt': createdAt,
      };
}

class AssistantThread {
  const AssistantThread({
    required this.id,
    this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? title;
  final List<AssistantMessage> messages;
  final String createdAt;
  final String updatedAt;

  factory AssistantThread.fromJson(Json json) => AssistantThread(
        id: asString(json['id']),
        title: asStringOrNull(json['title']),
        messages: asMapList(json['messages']).map(AssistantMessage.fromJson).toList(),
        createdAt: asString(json['createdAt']),
        updatedAt: asString(json['updatedAt']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'title': title,
        'messages': messages.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      });
}

class AssistantSendRequest {
  const AssistantSendRequest({this.threadId, required this.message, this.screen});

  /// ausente = nova conversa
  final String? threadId;
  final String message;

  /// context.screen
  final String? screen;

  Json toJson() => compact(<String, dynamic>{
        'threadId': threadId,
        'message': message,
        'context': screen == null ? null : <String, dynamic>{'screen': screen},
      });
}

class AssistantAction {
  const AssistantAction({required this.label, required this.deepLink});

  final String label;
  final String deepLink;

  factory AssistantAction.fromJson(Json json) => AssistantAction(
        label: asString(json['label']),
        deepLink: asString(json['deepLink']),
      );

  Json toJson() => <String, dynamic>{'label': label, 'deepLink': deepLink};
}

class AssistantSendResponse {
  const AssistantSendResponse({required this.threadId, required this.reply, this.actions, this.disclaimer});

  final String threadId;
  final AssistantMessage reply;
  final List<AssistantAction>? actions;

  /// Aviso obrigatório na primeira resposta de cada conversa.
  final String? disclaimer;

  factory AssistantSendResponse.fromJson(Json json) => AssistantSendResponse(
        threadId: asString(json['threadId']),
        reply: AssistantMessage.fromJson(asMap(json['reply']) ?? const <String, dynamic>{}),
        actions: json['actions'] == null ? null : asMapList(json['actions']).map(AssistantAction.fromJson).toList(),
        disclaimer: asStringOrNull(json['disclaimer']),
      );

  Json toJson() => compact(<String, dynamic>{
        'threadId': threadId,
        'reply': reply.toJson(),
        'actions': actions?.map((e) => e.toJson()).toList(),
        'disclaimer': disclaimer,
      });
}

class AssistantConfig {
  const AssistantConfig({
    required this.enabled,
    required this.disclaimer,
    required this.suggestedPrompts,
    required this.dailyMessageLimit,
  });

  final bool enabled;
  final String disclaimer;
  final List<String> suggestedPrompts;
  final int dailyMessageLimit;

  static const AssistantConfig disabled =
      AssistantConfig(enabled: false, disclaimer: '', suggestedPrompts: <String>[], dailyMessageLimit: 0);

  factory AssistantConfig.fromJson(Json json) => AssistantConfig(
        enabled: asBool(json['enabled']),
        disclaimer: asString(json['disclaimer']),
        suggestedPrompts: asStringList(json['suggestedPrompts']),
        dailyMessageLimit: asInt(json['dailyMessageLimit']),
      );

  Json toJson() => <String, dynamic>{
        'enabled': enabled,
        'disclaimer': disclaimer,
        'suggestedPrompts': suggestedPrompts,
        'dailyMessageLimit': dailyMessageLimit,
      };
}
