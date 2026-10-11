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
import { AppHeader, Button, CardBrandLogo, Input, Logo, Screen, SectionList, SectionRow, Sheet, Text, toast } from '@/components';
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
    <Screen
      header={<AppHeader onMenu={() => router.push('/(tabs)')} onProfile={() => setEditing(true)} />}
      onRefresh={() => { void me.refetch(); void prefs.refetch(); void address.refetch(); }}
      refreshing={me.isRefetching}
    >
      <View style={styles.hero}>
        <View style={styles.avatar}>
          <Text variant="title" tone="onDark">
            {(user?.firstName?.[0] ?? '?').toUpperCase()}
          </Text>
        </View>
        <View style={styles.flex1}>
          <Text variant="heading" tone="onDark">{user ? `${user.firstName} ${user.lastName}`.trim() : '—'}</Text>
          <Text variant="small" tone="onDarkMuted">
            {user?.email ?? ''}
          </Text>
          {user?.cpf ? (
            <Text variant="caption" tone="onDarkMuted">
              CPF {user.cpf}
              {user.phone ? ` · ${maskPhone(user.phone)}` : ''}
            </Text>
          ) : null}
        </View>
        <Logo variant="white" width={120} />
      </View>
      <Button title="Editar dados" variant="secondary" size="sm" style={styles.editBtn} onPress={() => setEditing(true)} />

      <SectionList title="Assinatura">
        <SectionRow
          icon="cash-outline"
          iconNode={sub?.paymentProfile ? <CardBrandLogo brand={sub.paymentProfile.brand} width={26} height={16} /> : undefined}
          title="Cartões"
          subtitle={sub?.paymentProfile ? `${sub.paymentProfile.brand} (final ${sub.paymentProfile.lastFour})` : 'Gerenciar formas de pagamento'}
          onPress={() => router.push('/payments/cards')}
        />
        <SectionRow
          icon="car-outline"
          title="Endereço de entrega"
          subtitle={address.data ? `${address.data.street}, ${address.data.number} · ${address.data.city}/${address.data.state}` : 'Alterar endereço'}
          onPress={() => router.push('/shipping/address')}
        />
        <SectionRow icon="time-outline" title="Histórico de pedidos" onPress={() => router.push('/(tabs)/orders')} />
        {sub?.status === 'paused' ? <SectionRow icon="play-outline" title="Retomar assinatura" onPress={() => router.push('/subscription/paused')} /> : null}
        {caps?.canPause.allowed ? <SectionRow icon="pause-outline" title="Pausar assinatura" subtitle={`Você tem ${caps.canPause.creditsLeft ?? 0} ${(caps.canPause.creditsLeft ?? 0) === 1 ? 'crédito de pausa' : 'créditos de pausa'}`} onPress={() => router.push('/subscription/pause')} /> : null}
        {sub?.status === 'canceled' ? <SectionRow icon="refresh-outline" title="Reativar assinatura" onPress={() => router.push('/subscription/canceled')} /> : null}
        {caps?.canCancel.allowed ? <SectionRow icon="close-circle-outline" title="Cancelar e perder benefícios" danger onPress={() => router.push('/subscription/cancel')} last /> : <View />}
      </SectionList>

      <SectionList title="Notificações">
        {prefLabels.map((p, idx) => (
          <SectionRow
            key={p.key}
            icon="notifications-outline"
            title={p.title}
            subtitle={p.subtitle}
            chevron={false}
            last={idx === prefLabels.length - 1}
            right={
              <Switch
                value={prefs.data?.[p.key] ?? false}
                disabled={!prefs.data}
                onValueChange={(v) => updatePrefs.mutate({ [p.key]: v }, { onError: (e) => toast.error(errorMessage(e)) })}
                trackColor={{ true: colors.primaryStrong, false: colors.borderStrong }}
                thumbColor={prefs.data?.[p.key] ? colors.gold : colors.surface}
              />
            }
          />
        ))}
      </SectionList>

      <SectionList title="Ajuda e privacidade">
        <SectionRow icon="headset-outline" title="Fale com nossos especialistas" onPress={() => openLink(config.data?.links.support, 'Suporte')} />
        <SectionRow icon="document-text-outline" title="Política de privacidade" onPress={() => openLink(config.data?.links.privacy, 'Política de privacidade')} />
        <SectionRow icon="reader-outline" title="Termos de uso" onPress={() => openLink(config.data?.links.terms, 'Termos de uso')} />
        <SectionRow icon="trash-outline" title="Excluir minha conta" danger onPress={confirmDelete} last />
      </SectionList>

      <Button title="Sair" variant="secondary" onPress={onSignOut} loading={signingOut} />
      <Text variant="caption" tone="dim" center style={styles.version}>
        Caffeine Army Prime v{Constants.expoConfig?.version ?? '1.0.0'}
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
  hero: { flexDirection: 'row', alignItems: 'center', gap: space(3), backgroundColor: colors.brandDark, borderRadius: radius.md, padding: space(4), marginBottom: space(2) },
  avatar: { width: 56, height: 56, borderRadius: radius.pill, backgroundColor: colors.gold, alignItems: 'center', justifyContent: 'center' },
  editBtn: { alignSelf: 'flex-end', marginBottom: space(3) },
  version: { marginTop: space(4) },
});
