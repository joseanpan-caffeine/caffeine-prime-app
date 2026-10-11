import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_header.dart';

/// Tela exibida enquanto a sessão é restaurada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimeLogo(height: 28, onDark: true),
            SizedBox(height: 24),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary)),
          ],
        ),
      ),
    );
  }
}
