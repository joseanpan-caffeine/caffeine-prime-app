import 'package:flutter/material.dart';

import '../../api/models/editing.dart';
import '../../core/theme/typography.dart';

/// Seleção de motivo (ReasonOption) com pergunta de acompanhamento opcional.
/// Usado em pausa e cancelamento.
class ReasonPicker extends StatelessWidget {
  const ReasonPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.followUpAnswer,
    required this.onSelected,
    required this.onFollowUp,
  });

  final List<ReasonOption> options;
  final ReasonOption? selected;
  final String? followUpAnswer;
  final ValueChanged<ReasonOption> onSelected;
  final ValueChanged<String> onFollowUp;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text('Não foi possível carregar os motivos. Você ainda pode continuar.', style: AppTypography.small);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ReasonOption o in options)
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: o.code,
            groupValue: selected?.code,
            title: Text(o.label, style: AppTypography.body),
            onChanged: (_) => onSelected(o),
          ),
        if (selected?.followUp != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(selected!.followUp!.question, style: AppTypography.bodyBold),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selected!.followUp!.options
                .map((String opt) => ChoiceChip(
                      label: Text(opt),
                      selected: followUpAnswer == opt,
                      onSelected: (_) => onFollowUp(opt),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Monta `answers` para PauseRequest/CancelRequest.
List<QuestionAnswer>? buildAnswers(ReasonOption? reason, String? followUpAnswer) {
  if (reason?.followUp == null || followUpAnswer == null) return null;
  return <QuestionAnswer>[QuestionAnswer(question: reason!.followUp!.question, answer: followUpAnswer)];
}
