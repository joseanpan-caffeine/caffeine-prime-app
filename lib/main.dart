import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale pt-BR para intl (datas/números).
  Intl.defaultLocale = 'pt_BR';
  try {
    await initializeDateFormatting('pt_BR');
  } catch (_) {
    // Sem dados de locale o app continua: Fmt não depende de DateFormat.
  }

  // Restaura a sessão antes do primeiro frame para o router decidir a rota.
  final ProviderContainer container = ProviderContainer();
  await container.read(sessionProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CaffeinePrimeApp(),
    ),
  );
}
