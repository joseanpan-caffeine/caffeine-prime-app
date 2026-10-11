import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/profile.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/prime_button.dart';
import '../../core/widgets/section_list.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/providers.dart';

/// Dados do perfil (PATCH /me/profile). E-mail e CPF só leitura (CPF mascarado).
class ProfileDataScreen extends ConsumerStatefulWidget {
  const ProfileDataScreen({super.key});

  @override
  ConsumerState<ProfileDataScreen> createState() => _ProfileDataScreenState();
}

class _ProfileDataScreenState extends ConsumerState<ProfileDataScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  String? _gender;

  static const List<String> _genders = <String>['Feminino', 'Masculino', 'Outro', 'Prefiro não informar'];

  @override
  void initState() {
    super.initState();
    final UserProfile? u = ref.read(currentUserProvider);
    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName = TextEditingController(text: u?.lastName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _gender = u?.gender;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      final UserProfile updated = await ref.read(accountApiProvider).updateProfile(
            UpdateProfileRequest(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              gender: _gender,
            ),
          );
      await ref.read(sessionProvider.notifier).updateUser(updated);
      ref.invalidate(dashboardProvider);
      if (!mounted) return;
      showSuccessToast(context, 'Dados atualizados');
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProfile? u = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus dados')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppDims.pageMargin),
          children: <Widget>[
            SurfaceCard(
              child: Column(
                children: <Widget>[
                  KeyValueRow(label: 'E-mail', value: u?.email ?? '—'),
                  KeyValueRow(label: 'CPF', value: u?.cpf ?? '—'),
                  const SizedBox(height: 4),
                  Text(
                    'E-mail e CPF identificam sua assinatura e só podem ser alterados pelo atendimento.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (String? v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                    validator: (String? v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular com DDD'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _genders.contains(_gender) ? _gender : null,
              decoration: const InputDecoration(labelText: 'Gênero (opcional)'),
              items: _genders.map((g) => DropdownMenuItem<String>(value: g, child: Text(g))).toList(),
              onChanged: (String? v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 20),
            PrimeButton(label: 'Salvar', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
