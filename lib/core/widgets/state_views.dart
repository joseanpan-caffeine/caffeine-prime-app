import 'package:flutter/material.dart';

import '../../api/api_error.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'prime_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          if (message != null) ...<Widget>[const SizedBox(height: 12), Text(message!, style: AppTypography.small)],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final Future<void> Function()? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ApiError e = ApiError.from(error);
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(e.isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded, color: AppColors.textMuted, size: 36),
        const SizedBox(height: 12),
        Text(e.message, textAlign: TextAlign.center, style: AppTypography.body),
        if (onRetry != null) ...<Widget>[
          const SizedBox(height: 16),
          PrimeButton(label: 'Tentar novamente', onPressed: onRetry, variant: PrimeButtonVariant.secondary, expanded: false),
        ],
      ],
    );
    if (compact) return Padding(padding: const EdgeInsets.all(16), child: content);
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.body, this.icon = Icons.inbox_outlined, this.action});

  final String title;
  final String? body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
            if (body != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(body!, style: AppTypography.body, textAlign: TextAlign.center),
            ],
            if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Toasts (branco com sombra, ícone verde/vermelho) via SnackBar.
void showSuccessToast(BuildContext context, String title, {String? body}) {
  _toast(context, title, body, AppColors.success, Icons.check_circle_rounded);
}

void showErrorToast(BuildContext context, Object error, {String? title}) {
  final ApiError e = ApiError.from(error);
  _toast(context, title ?? 'Não deu certo', e.message, AppColors.danger, Icons.error_rounded);
}

void _toast(BuildContext context, String title, String? body, Color color, IconData icon) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: AppColors.bgSurface,
      elevation: 4,
      duration: const Duration(seconds: 4),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.bodyBold),
                if (body != null && body.isNotEmpty) Text(body, style: AppTypography.small),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
