import 'common.dart';
import 'json.dart';

class BoxItemInput {
  const BoxItemInput({required this.handle, required this.quantity, this.recurrence});

  final String handle;
  final int quantity;

  /// null no JSON = todo ciclo. Quando omitido no request mantém o padrão.
  final ItemRecurrence? recurrence;

  factory BoxItemInput.fromJson(Json json) => BoxItemInput(
        handle: asString(json['handle']),
        quantity: asInt(json['quantity']),
        recurrence: json.containsKey('recurrence') ? ItemRecurrence.parse(json['recurrence']) : null,
      );

  Json toJson() => <String, dynamic>{
        'handle': handle,
        'quantity': quantity,
        if (recurrence != null) 'recurrence': recurrence!.wire,
      };

  BoxItemInput copyWith({String? handle, int? quantity, ItemRecurrence? recurrence, bool clearRecurrence = false}) {
    return BoxItemInput(
      handle: handle ?? this.handle,
      quantity: quantity ?? this.quantity,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    );
  }
}

class PreviewRequest {
  const PreviewRequest({required this.frequency, required this.items, this.couponCode});

  final Frequency frequency;
  final List<BoxItemInput> items;
  final String? couponCode;

  Json toJson() => compact(<String, dynamic>{
        'frequency': frequency.wire,
        'items': items.map((e) => e.toJson()).toList(),
        'couponCode': couponCode,
      });
}

class PricePreviewItem {
  const PricePreviewItem({
    required this.handle,
    required this.quantity,
    this.recurrence,
    required this.title,
    required this.unitPrice,
    required this.discountPercentage,
    required this.finalUnitPrice,
  });

  final String handle;
  final int quantity;
  final ItemRecurrence? recurrence;
  final String title;
  final Money unitPrice;
  final double discountPercentage;
  final Money finalUnitPrice;

  factory PricePreviewItem.fromJson(Json json) => PricePreviewItem(
        handle: asString(json['handle']),
        quantity: asInt(json['quantity']),
        recurrence: json.containsKey('recurrence') ? ItemRecurrence.parse(json['recurrence']) : null,
        title: asString(json['title']),
        unitPrice: Money.fromJson(asMap(json['unitPrice'])),
        discountPercentage: asDouble(json['discountPercentage']),
        finalUnitPrice: Money.fromJson(asMap(json['finalUnitPrice'])),
      );

  Json toJson() => <String, dynamic>{
        'handle': handle,
        'quantity': quantity,
        'recurrence': recurrence?.wire,
        'title': title,
        'unitPrice': unitPrice.toJson(),
        'discountPercentage': discountPercentage,
        'finalUnitPrice': finalUnitPrice.toJson(),
      };
}

class PricePreview {
  const PricePreview({
    required this.frequency,
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
    required this.appliedDiscountPercentage,
    this.couponApplied,
    required this.warnings,
  });

  final Frequency frequency;
  final List<PricePreviewItem> items;
  final Money subtotal;
  final Money totalDiscount;
  final Money total;
  final double appliedDiscountPercentage;
  final String? couponApplied;
  final List<String> warnings;

  factory PricePreview.fromJson(Json json) => PricePreview(
        frequency: Frequency.parse(json['frequency']),
        items: asMapList(json['items']).map(PricePreviewItem.fromJson).toList(),
        subtotal: Money.fromJson(asMap(json['subtotal'])),
        totalDiscount: Money.fromJson(asMap(json['totalDiscount'])),
        total: Money.fromJson(asMap(json['total'])),
        appliedDiscountPercentage: asDouble(json['appliedDiscountPercentage']),
        couponApplied: asStringOrNull(json['couponApplied']),
        warnings: asStringList(json['warnings']),
      );

  Json toJson() => compact(<String, dynamic>{
        'frequency': frequency.wire,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal.toJson(),
        'totalDiscount': totalDiscount.toJson(),
        'total': total.toJson(),
        'appliedDiscountPercentage': appliedDiscountPercentage,
        'couponApplied': couponApplied,
        'warnings': warnings,
      });
}

class SchedulingRequest extends PreviewRequest {
  const SchedulingRequest({
    required super.frequency,
    required super.items,
    super.couponCode,
    this.giftHandles,
    this.nextCycleOnly,
    this.reason,
  });

  final List<String>? giftHandles;
  final bool? nextCycleOnly;
  final String? reason;

  @override
  Json toJson() => compact(<String, dynamic>{
        ...super.toJson(),
        'giftHandles': giftHandles,
        'nextCycleOnly': nextCycleOnly,
        'reason': reason,
      });
}

class QuestionAnswer {
  const QuestionAnswer({required this.question, required this.answer});

  final String question;
  final String answer;

  Json toJson() => <String, dynamic>{'question': question, 'answer': answer};
}

class PauseRequest {
  const PauseRequest({required this.cycles, required this.reason, this.answers});

  final int cycles;
  final String reason;
  final List<QuestionAnswer>? answers;

  Json toJson() => compact(<String, dynamic>{
        'cycles': cycles,
        'reason': reason,
        'answers': answers?.map((e) => e.toJson()).toList(),
      });
}

class CancelRequest {
  const CancelRequest({required this.reason, this.answers});

  final String reason;
  final List<QuestionAnswer>? answers;

  Json toJson() => compact(<String, dynamic>{
        'reason': reason,
        'answers': answers?.map((e) => e.toJson()).toList(),
      });
}

class ReasonFollowUp {
  const ReasonFollowUp({required this.question, required this.options});

  final String question;
  final List<String> options;

  factory ReasonFollowUp.fromJson(Json json) => ReasonFollowUp(
        question: asString(json['question']),
        options: asStringList(json['options']),
      );

  Json toJson() => <String, dynamic>{'question': question, 'options': options};
}

class ReasonOption {
  const ReasonOption({required this.code, required this.label, this.followUp});

  final String code;
  final String label;
  final ReasonFollowUp? followUp;

  factory ReasonOption.fromJson(Json json) => ReasonOption(
        code: asString(json['code']),
        label: asString(json['label']),
        followUp: asMap(json['followUp']) == null ? null : ReasonFollowUp.fromJson(asMap(json['followUp'])!),
      );

  Json toJson() => compact(<String, dynamic>{
        'code': code,
        'label': label,
        'followUp': followUp?.toJson(),
      });
}
