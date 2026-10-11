import 'common.dart';
import 'json.dart';

class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.productHandle,
    required this.title,
    this.imageUrl,
    required this.slot,
    this.reminderTime,
    required this.reminderEnabled,
    required this.dosesPerDay,
    this.usageHint,
  });

  final String id;
  final String productHandle;
  final String title;
  final String? imageUrl;
  final RoutineSlot slot;

  /// "07:30" (hora local do aparelho)
  final String? reminderTime;
  final bool reminderEnabled;
  final int dosesPerDay;

  /// "para que serve / como tomar" (metaobjects)
  final String? usageHint;

  factory RoutineItem.fromJson(Json json) => RoutineItem(
        id: asString(json['id']),
        productHandle: asString(json['productHandle']),
        title: asString(json['title']),
        imageUrl: asStringOrNull(json['imageUrl']),
        slot: RoutineSlot.parse(json['slot']),
        reminderTime: asStringOrNull(json['reminderTime']),
        reminderEnabled: asBool(json['reminderEnabled']),
        dosesPerDay: asInt(json['dosesPerDay'], 1),
        usageHint: asStringOrNull(json['usageHint']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'productHandle': productHandle,
        'title': title,
        'imageUrl': imageUrl,
        'slot': slot.wire,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'dosesPerDay': dosesPerDay,
        'usageHint': usageHint,
      });

  /// Versão para `UpdateRoutinePlanRequest.items` (sem title/imageUrl/usageHint).
  Json toUpdateJson() => compact(<String, dynamic>{
        'id': id,
        'productHandle': productHandle,
        'slot': slot.wire,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'dosesPerDay': dosesPerDay,
      });

  RoutineItem copyWith({
    RoutineSlot? slot,
    String? reminderTime,
    bool clearReminderTime = false,
    bool? reminderEnabled,
    int? dosesPerDay,
  }) {
    return RoutineItem(
      id: id,
      productHandle: productHandle,
      title: title,
      imageUrl: imageUrl,
      slot: slot ?? this.slot,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      dosesPerDay: dosesPerDay ?? this.dosesPerDay,
      usageHint: usageHint,
    );
  }
}

class RoutinePlan {
  const RoutinePlan({required this.items, required this.weeklyGoalDays, required this.timezone});

  final List<RoutineItem> items;

  /// 1–7
  final int weeklyGoalDays;

  /// IANA, ex.: America/Sao_Paulo
  final String timezone;

  static const RoutinePlan empty = RoutinePlan(items: <RoutineItem>[], weeklyGoalDays: 5, timezone: 'America/Sao_Paulo');

  factory RoutinePlan.fromJson(Json json) => RoutinePlan(
        items: asMapList(json['items']).map(RoutineItem.fromJson).toList(),
        weeklyGoalDays: asInt(json['weeklyGoalDays'], 5).clamp(1, 7).toInt(),
        timezone: asString(json['timezone'], 'America/Sao_Paulo'),
      );

  Json toJson() => <String, dynamic>{
        'items': items.map((e) => e.toJson()).toList(),
        'weeklyGoalDays': weeklyGoalDays,
        'timezone': timezone,
      };

  RoutinePlan copyWith({List<RoutineItem>? items, int? weeklyGoalDays, String? timezone}) {
    return RoutinePlan(
      items: items ?? this.items,
      weeklyGoalDays: weeklyGoalDays ?? this.weeklyGoalDays,
      timezone: timezone ?? this.timezone,
    );
  }
}

class UpdateRoutinePlanRequest {
  const UpdateRoutinePlanRequest({this.items, this.weeklyGoalDays, this.timezone});

  final List<RoutineItem>? items;
  final int? weeklyGoalDays;
  final String? timezone;

  Json toJson() => compact(<String, dynamic>{
        'items': items?.map((e) => e.toUpdateJson()).toList(),
        'weeklyGoalDays': weeklyGoalDays,
        'timezone': timezone,
      });
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.routineItemId,
    required this.date,
    required this.doneAt,
    required this.source,
  });

  final String id;
  final String routineItemId;

  /// YYYY-MM-DD (fuso do plano)
  final String date;

  /// ISO
  final String doneAt;
  final CheckInSource source;

  factory CheckIn.fromJson(Json json) => CheckIn(
        id: asString(json['id']),
        routineItemId: asString(json['routineItemId']),
        date: asString(json['date']),
        doneAt: asString(json['doneAt']),
        source: CheckInSource.parse(json['source']),
      );

  Json toJson() => <String, dynamic>{
        'id': id,
        'routineItemId': routineItemId,
        'date': date,
        'doneAt': doneAt,
        'source': source.wire,
      };
}

class CheckInRequest {
  const CheckInRequest({required this.routineItemId, required this.date, this.source});

  final String routineItemId;
  final String date;
  final CheckInSource? source;

  Json toJson() => compact(<String, dynamic>{
        'routineItemId': routineItemId,
        'date': date,
        'source': source?.wire,
      });
}

class RoutineTodayItem {
  const RoutineTodayItem({required this.routineItemId, required this.done});

  final String routineItemId;
  final bool done;

  factory RoutineTodayItem.fromJson(Json json) => RoutineTodayItem(
        routineItemId: asString(json['routineItemId']),
        done: asBool(json['done']),
      );

  Json toJson() => <String, dynamic>{'routineItemId': routineItemId, 'done': done};
}

class RoutineToday {
  const RoutineToday({required this.date, required this.items, required this.completion});

  final String date;
  final List<RoutineTodayItem> items;

  /// 0–1
  final double completion;

  factory RoutineToday.fromJson(Json? json) {
    if (json == null) return const RoutineToday(date: '', items: <RoutineTodayItem>[], completion: 0);
    return RoutineToday(
      date: asString(json['date']),
      items: asMapList(json['items']).map(RoutineTodayItem.fromJson).toList(),
      completion: asDouble(json['completion']),
    );
  }

  Json toJson() => <String, dynamic>{
        'date': date,
        'items': items.map((e) => e.toJson()).toList(),
        'completion': completion,
      };

  bool isDone(String routineItemId) {
    for (final RoutineTodayItem i in items) {
      if (i.routineItemId == routineItemId) return i.done;
    }
    return false;
  }
}

class DayCompletionEntry {
  const DayCompletionEntry({required this.date, required this.completion});

  final String date;
  final double completion;

  factory DayCompletionEntry.fromJson(Json json) => DayCompletionEntry(
        date: asString(json['date']),
        completion: asDouble(json['completion']),
      );

  Json toJson() => <String, dynamic>{'date': date, 'completion': completion};
}

class StockForecast {
  const StockForecast({required this.productHandle, required this.dosesLeft, this.runsOutAt, this.nextBoxAt});

  final String productHandle;
  final int dosesLeft;
  final String? runsOutAt;
  final String? nextBoxAt;

  factory StockForecast.fromJson(Json json) => StockForecast(
        productHandle: asString(json['productHandle']),
        dosesLeft: asInt(json['dosesLeft']),
        runsOutAt: asStringOrNull(json['runsOutAt']),
        nextBoxAt: asStringOrNull(json['nextBoxAt']),
      );

  Json toJson() => compact(<String, dynamic>{
        'productHandle': productHandle,
        'dosesLeft': dosesLeft,
        'runsOutAt': runsOutAt,
        'nextBoxAt': nextBoxAt,
      });
}

class RoutineSummary {
  const RoutineSummary({
    required this.today,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.weekCompletion,
    required this.last28Days,
    this.stockForecast,
  });

  final RoutineToday today;
  final int currentStreakDays;
  final int longestStreakDays;

  /// 0–1
  final double weekCompletion;
  final List<DayCompletionEntry> last28Days;
  final List<StockForecast>? stockForecast;

  factory RoutineSummary.fromJson(Json json) => RoutineSummary(
        today: RoutineToday.fromJson(asMap(json['today'])),
        currentStreakDays: asInt(json['currentStreakDays']),
        longestStreakDays: asInt(json['longestStreakDays']),
        weekCompletion: asDouble(json['weekCompletion']),
        last28Days: asMapList(json['last28Days']).map(DayCompletionEntry.fromJson).toList(),
        stockForecast:
            json['stockForecast'] == null ? null : asMapList(json['stockForecast']).map(StockForecast.fromJson).toList(),
      );

  Json toJson() => compact(<String, dynamic>{
        'today': today.toJson(),
        'currentStreakDays': currentStreakDays,
        'longestStreakDays': longestStreakDays,
        'weekCompletion': weekCompletion,
        'last28Days': last28Days.map((e) => e.toJson()).toList(),
        'stockForecast': stockForecast?.map((e) => e.toJson()).toList(),
      });
}
