import { useState } from 'react';
import { Alert, StyleSheet, Switch, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import * as WebBrowser from 'expo-web-browser';
import Constants from 'expo-constants';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { NotificationPreferences } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import {
  useAppConfig,
  useDashboard,
  useDeleteAccountRequest,
  useMe,
  useNotificationPreferences,
  useShippingAddress,
  useUpdateNotificationPreferences,
  useUpdateProfile,
} from '@/api/hooks';
import { Button, Card, Input, ListItem, Screen, Section, Sheet, Text, toast } from '@/components';
import { maskPhone, onlyDigits } from '@/lib/format';
import { API_URL, FAKE_AUTH } from '@/lib/env';
import { signOut } from '@/lib/session';
import { useAuthStore } from '@/store/auth';
import { colors, radius, space } from '@/theme';

const profileSchema = z.object({
  firstName: z.string().trim().min(2, 'Informe seu nome'),
  lastName: z.string().trim().min(2, 'Informe seu sobrenome'),
  phone: z.string().refine((v) => !v || onlyDigits(v).length >= 10, 'Telefone inválido'),
  gender: z.string().trim().optional(),
});
type ProfileForm = z.infer<typeof profileSchema>;

const prefLabels: { key: keyof NotificationPreferences; title: string; subtitle: string }[] = [
  { key: 'billing', title: 'Cobranças', subtitle: 'Fatura gerada, PIX a vencer, cartão recusado' },
  { key: 'shipping', title: 'Entregas', subtitle: 'Pedido enviado, em trânsito e entregue' },
  { key: 'renewal', title: 'Renovação', subtitle: 'Aviso 3 dias antes de fechar a janela de edição' },
  { key: 'marketing', title: 'Novidades e ofertas', subtitle: 'Lançamentos e promoções exclusivas' },
];

export default function Profile() {
  const router = useRouter();
  const qc = useQueryClient();
  const storeUser = useAuthStore((s) => s.user);
  const me = useMe();
  const dashboard = useDashboard();
  const address = useShippingAddress();
  const prefs = useNotificationPreferences();
  const updatePrefs = useUpdateNotificationPreferences();
  const config = useAppConfig();
  const deleteRequest = useDeleteAccountRequest();
  const [editing, setEditing] = useState(false);
  const [signingOut, setSigningOut] = useState(false);

  const user = me.data ?? storeUser;
  const caps = dashboard.data?.capabilities;
  const sub = dashboard.data?.subscription;

  async function openLink(url: string | undefined, fallbackLabel: string) {
    if (!url) {
      toast.info(`${fallbackLabel} ainda não disponível.`);
      return;
    }
    try {
      await WebBrowser.openBrowserAsync(url);
    } catch {
      toast.error('Não foi possível abrir o link.');
    }
  }

  function confirmDelete() {
    Alert.alert(
      'Excluir conta',
      'Abriremos um pedido de exclusão dos seus dados. Sua assinatura precisa estar cancelada. Deseja continuar?',
      [
        { text: 'Voltar', style: 'cancel' },
        {
          text: 'Solicitar exclusão',
          style: 'destructive',
          onPress: () =>
            deleteRequest.mutate('app', {
              onSuccess: () => toast.success('Pedido registrado. Entraremos em contato por e-mail.'),
              onError: (e) => toast.error(errorMessage(e)),
            }),
        },
      ],
    );
  }

  async function onSignOut() {
    setSigningOut(true);
    await signOut(qc);
    setSigningOut(false);
  }

  return (
    <Screen safeTop title="Perfil" onRefresh={() => { void me.refetch(); void prefs.refetch(); void address.refetch(); }} refreshing={me.isRefetching}>
      <Card tone="elevated">
        <View style={styles.userRow}>
          <View style={styles.avatar}>
            <Text variant="heading" tone="accent">
              {(user?.firstName?.[0] ?? '?').toUpperCase()}
            </Text>
          </View>
          <View style={styles.flex1}>
            <Text variant="heading">{user ? `${user.firstName} ${user.lastName}`.trim() : '—'}</Text>
            <Text variant="small" tone="muted">
              {user?.email ?? ''}
            </Text>
            {user?.cpf ? (
              <Text variant="caption" tone="dim">
                CPF {user.cpf}
                {user.phone ? ` · ${maskPhone(user.phone)}` : ''}
              </Text>
            ) : null}
          </View>
        </View>
        <Button title="Editar dados" variant="secondary" size="sm" style={styles.mt3} onPress={() => setEditing(true)} />
      </Card>

      <Section title="Assinatura">
        <Card padded={false} style={styles.listCard}>
          <ListItem
            title="Cartões"
            subtitle={sub?.paymentProfile ? `${sub.paymentProfile.brand} •••• ${sub.paymentProfile.lastFour}` : 'Gerenciar formas de pagamento'}
            onPress={() => router.push('/payments/cards')}
          />
          <ListItem
            title="Endereço de entrega"
            subtitle={address.data ? `${address.data.street}, ${address.data.number} · ${address.data.city}/${address.data.state}` : 'Alterar endereço'}
            onPress={() => router.push('/shipping/address')}
          />
          {sub?.status === 'paused' ? <ListItem title="Retomar assinatura" onPress={() => router.push('/subscription/paused')} /> : null}
          {caps?.canPause.allowed ? <ListItem title="Pausar assinatura" subtitle={`${caps.canPause.creditsLeft ?? 0} crédito(s) de pausa`} onPress={() => router.push('/subscription/pause')} /> : null}
          {sub?.status === 'canceled' ? <ListItem title="Reativar assinatura" onPress={() => router.push('/subscription/canceled')} /> : null}
          {caps?.canCancel.allowed ? <ListItem title="Cancelar assinatura" danger onPress={() => router.push('/subscription/cancel')} last /> : null}
        </Card>
      </Section>

      <Section title="Notificações">
        <Card padded={false} style={styles.listCard}>
          {prefLabels.map((p, idx) => (
            <ListItem
              key={p.key}
              title={p.title}
              subtitle={p.subtitle}
              last={idx === prefLabels.length - 1}
              right={
                <Switch
                  value={prefs.data?.[p.key] ?? false}
                  disabled={!prefs.data}
                  onValueChange={(v) => updatePrefs.mutate({ [p.key]: v }, { onError: (e) => toast.error(errorMessage(e)) })}
                  trackColor={{ true: colors.accentDark, false: colors.borderStrong }}
                  thumbColor={prefs.data?.[p.key] ? colors.accent : colors.textMuted}
                />
              }
            />
          ))}
        </Card>
      </Section>

      <Section title="Privacidade">
        <Card padded={false} style={styles.listCard}>
          <ListItem title="Política de privacidade" onPress={() => openLink(config.data?.links.privacy, 'Política de privacidade')} />
          <ListItem title="Termos de uso" onPress={() => openLink(config.data?.links.terms, 'Termos de uso')} />
          <ListItem title="Falar com o suporte" onPress={() => openLink(config.data?.links.support, 'Suporte')} />
          <ListItem title="Excluir minha conta" danger onPress={confirmDelete} last />
        </Card>
      </Section>

      <Button title="Sair" variant="secondary" onPress={onSignOut} loading={signingOut} />
      <Text variant="caption" tone="dim" center style={styles.version}>
        Caffeine Prime v{Constants.expoConfig?.version ?? '1.0.0'}
        {FAKE_AUTH ? ' · modo fake' : ''} · {API_URL}
      </Text>

      <EditProfileSheet visible={editing} onClose={() => setEditing(false)} defaults={{ firstName: user?.firstName ?? '', lastName: user?.lastName ?? '', phone: user?.phone ? maskPhone(user.phone) : '', gender: user?.gender ?? '' }} />
    </Screen>
  );
}

function EditProfileSheet({ visible, onClose, defaults }: { visible: boolean; onClose: () => void; defaults: ProfileForm }) {
  const update = useUpdateProfile();
  const { control, handleSubmit, formState, reset } = useForm<ProfileForm>({ resolver: zodResolver(profileSchema), defaultValues: defaults, values: defaults });

  const onSubmit = handleSubmit((v) => {
    update.mutate(
      { firstName: v.firstName, lastName: v.lastName, phone: v.phone ? onlyDigits(v.phone) : undefined, gender: v.gender || undefined },
      {
        onSuccess: () => {
          toast.success('Dados atualizados.');
          onClose();
        },
        onError: (e) => toast.error(errorMessage(e)),
      },
    );
  });

  return (
    <Sheet visible={visible} onClose={() => { reset(defaults); onClose(); }} title="Editar dados">
      <Controller control={control} name="firstName" render={({ field: { onChange, onBlur, value } }) => <Input label="Nome" value={value} onChangeText={onChange} onBlur={onBlur} error={formState.errors.firstName?.message} />} />
      <Controller control={control} name="lastName" render={({ field: { onChange, onBlur, value } }) => <Input label="Sobrenome" value={value} onChangeText={onChange} onBlur={onBlur} error={formState.errors.lastName?.message} />} />
      <Controller control={control} name="phone" render={({ field: { onChange, onBlur, value } }) => <Input label="Telefone" value={value} onChangeText={(t) => onChange(maskPhone(t))} onBlur={onBlur} keyboardType="phone-pad" error={formState.errors.phone?.message} />} />
      <Controller control={control} name="gender" render={({ field: { onChange, onBlur, value } }) => <Input label="Gênero (opcional)" value={value ?? ''} onChangeText={onChange} onBlur={onBlur} />} />
      <Button title="Salvar" onPress={onSubmit} loading={update.isPending} />
    </Sheet>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  mt3: { marginTop: space(3) },
  userRow: { flexDirection: 'row', alignItems: 'center', gap: space(3) },
  avatar: { width: 52, height: 52, borderRadius: radius.pill, backgroundColor: colors.accentSoft, alignItems: 'center', justifyContent: 'center' },
  listCard: { paddingHorizontal: space(4) },
  version: { marginTop: space(4) },
});
