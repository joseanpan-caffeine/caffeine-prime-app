import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { AddressQuote } from '@/api/contracts';
import { errorMessage } from '@/api/client';
import { useDashboard, useQuoteAddress, useShippingAddress, useUpdateAddress } from '@/api/hooks';
import { AlertCard, Button, Card, Input, Money, RadioRow, Screen, Section, SkeletonCard, Text, toast } from '@/components';
import { maskCep, onlyDigits } from '@/lib/format';
import { capabilityReasonLabel } from '@/lib/labels';
import { space } from '@/theme';

const schema = z.object({
  recipient: z.string().trim().min(3, 'Informe quem recebe'),
  street: z.string().trim().min(2, 'Informe a rua'),
  number: z.string().trim().min(1, 'Informe o número'),
  complement: z.string().trim().optional(),
  neighborhood: z.string().trim().min(2, 'Informe o bairro'),
  city: z.string().trim().min(2, 'Informe a cidade'),
  state: z.string().trim().length(2, 'UF com 2 letras'),
});
type FormValues = z.infer<typeof schema>;

export default function AddressScreen() {
  const router = useRouter();
  const current = useShippingAddress();
  const { data: dashboard } = useDashboard();
  const quote = useQuoteAddress();
  const update = useUpdateAddress();
  const [cepInput, setCep] = useState<string | null>(null);
  const [quoteData, setQuoteData] = useState<AddressQuote | null>(null);
  const [optionId, setOptionId] = useState<string | null>(null);

  const cap = dashboard?.capabilities.canChangeAddress;
  const blocked = cap ? !cap.allowed : false;

  const { control, handleSubmit, formState, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { recipient: '', street: '', number: '', complement: '', neighborhood: '', city: '', state: '' },
  });

  const cep = cepInput ?? (current.data ? maskCep(current.data.postalCode) : '');

  function runQuote() {
    const postalCode = onlyDigits(cep);
    if (postalCode.length !== 8) {
      toast.error('Informe um CEP com 8 dígitos.');
      return;
    }
    quote.mutate(
      { postalCode },
      {
        onSuccess: (q) => {
          setQuoteData(q);
          const first = q.options[0];
          setOptionId(first ? first.id : null);
          const sameCep = current.data && onlyDigits(current.data.postalCode) === postalCode;
          reset({
            recipient: current.data?.recipient ?? '',
            street: q.street ?? (sameCep ? current.data?.street : '') ?? '',
            number: sameCep ? (current.data?.number ?? '') : '',
            complement: sameCep ? (current.data?.complement ?? '') : '',
            neighborhood: q.neighborhood ?? (sameCep ? current.data?.neighborhood : '') ?? '',
            city: q.city,
            state: q.state,
          });
        },
        onError: (e) => toast.error(errorMessage(e, 'CEP não atendido ou inválido.')),
      },
    );
  }

  const onSubmit = handleSubmit((v) => {
    if (!quoteData || !optionId) {
      toast.error('Escolha uma opção de entrega.');
      return;
    }
    update.mutate(
      {
        recipient: v.recipient,
        postalCode: quoteData.postalCode,
        street: v.street,
        number: v.number,
        complement: v.complement || undefined,
        neighborhood: v.neighborhood,
        city: v.city,
        state: v.state.toUpperCase(),
        quoteOptionId: optionId,
      },
      {
        onSuccess: () => {
          toast.success('Endereço atualizado.');
          router.back();
        },
        onError: (e) => toast.error(errorMessage(e, 'Não foi possível salvar o endereço.')),
      },
    );
  });

  const err = formState.errors;

  return (
    <Screen keyboard title="Endereço de entrega" subtitle="Informe o CEP para cotar o frete e confirmar o endereço.">
      {blocked && cap ? (
        <AlertCard variant="why_cant_edit" title="Troca de endereço indisponível">
          {capabilityReasonLabel(cap.reason, cap.until)}
        </AlertCard>
      ) : null}

      {current.isLoading ? (
        <SkeletonCard lines={2} />
      ) : current.data ? (
        <Card title="Endereço atual" subtitle={current.data.deliveryMethod ? `${current.data.deliveryMethod}${current.data.deliveryEstimateDays ? ` · ${current.data.deliveryEstimateDays} dias úteis` : ''}` : undefined}>
          <Text variant="small">
            {current.data.recipient}
          </Text>
          <Text variant="small" tone="muted">
            {current.data.street}, {current.data.number}
            {current.data.complement ? ` · ${current.data.complement}` : ''}
          </Text>
          <Text variant="small" tone="muted">
            {current.data.neighborhood} · {current.data.city}/{current.data.state} · CEP {maskCep(current.data.postalCode)}
          </Text>
        </Card>
      ) : null}

      <Section title="1. CEP">
        <Input
          label="CEP"
          value={cep}
          onChangeText={(t) => {
            setCep(maskCep(t));
            setQuoteData(null);
          }}
          keyboardType="number-pad"
          placeholder="00000-000"
          textContentType="postalCode"
          editable={!blocked}
          onSubmitEditing={runQuote}
          returnKeyType="search"
        />
        <Button title="Cotar frete" variant="secondary" onPress={runQuote} loading={quote.isPending} disabled={blocked || onlyDigits(cep).length !== 8} />
      </Section>

      {quoteData ? (
        <>
          <Section title="2. Entrega">
            {quoteData.options.length === 0 ? (
              <Card>
                <Text variant="small" tone="danger">
                  Nenhuma opção de entrega para este CEP.
                </Text>
              </Card>
            ) : null}
            {quoteData.options.map((o) => (
              <RadioRow
                key={o.id}
                boxed
                label={o.method}
                hint={`${o.carrier} · até ${o.estimateDays} dias úteis`}
                selected={o.id === optionId}
                onPress={() => setOptionId(o.id)}
                right={<Money value={o.price} variant="smallStrong" tone={o.price.amount === 0 ? 'successText' : 'default'} />}
              />
            ))}
          </Section>

          <Section title="3. Endereço">
            <Controller control={control} name="recipient" render={({ field: { onChange, onBlur, value } }) => <Input label="Quem recebe" value={value} onChangeText={onChange} onBlur={onBlur} textContentType="name" error={err.recipient?.message} />} />
            <Controller control={control} name="street" render={({ field: { onChange, onBlur, value } }) => <Input label="Rua" value={value} onChangeText={onChange} onBlur={onBlur} textContentType="streetAddressLine1" error={err.street?.message} />} />
            <View style={styles.row}>
              <View style={styles.third}>
                <Controller control={control} name="number" render={({ field: { onChange, onBlur, value } }) => <Input label="Número" value={value} onChangeText={onChange} onBlur={onBlur} error={err.number?.message} />} />
              </View>
              <View style={styles.flex1}>
                <Controller control={control} name="complement" render={({ field: { onChange, onBlur, value } }) => <Input label="Complemento" value={value ?? ''} onChangeText={onChange} onBlur={onBlur} placeholder="apto, bloco…" />} />
              </View>
            </View>
            <Controller control={control} name="neighborhood" render={({ field: { onChange, onBlur, value } }) => <Input label="Bairro" value={value} onChangeText={onChange} onBlur={onBlur} error={err.neighborhood?.message} />} />
            <View style={styles.row}>
              <View style={styles.flex1}>
                <Controller control={control} name="city" render={({ field: { onChange, onBlur, value } }) => <Input label="Cidade" value={value} onChangeText={onChange} onBlur={onBlur} textContentType="addressCity" error={err.city?.message} />} />
              </View>
              <View style={styles.third}>
                <Controller control={control} name="state" render={({ field: { onChange, onBlur, value } }) => <Input label="UF" value={value} onChangeText={(t) => onChange(t.toUpperCase().slice(0, 2))} onBlur={onBlur} autoCapitalize="characters" error={err.state?.message} />} />
              </View>
            </View>
            <Text variant="small" tone="muted" style={styles.summary}>
              CEP {maskCep(quoteData.postalCode)}
            </Text>
            <Button title="Salvar endereço" onPress={onSubmit} loading={update.isPending} disabled={blocked || !optionId} />
          </Section>
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex1: { flex: 1 },
  row: { flexDirection: 'row', gap: space(3) },
  third: { width: 110 },
  summary: { marginBottom: space(3) },
});
