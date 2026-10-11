/**
 * Formulário de cartão: número, nome, validade, CVV → tokeniza na Vindi
 * (ou gera "fake-token-<last4>" em FAKE_AUTH) e devolve o gatewayToken.
 */
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Controller, useForm, useWatch } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useVindiConfig } from '@/api/hooks';
import { Button, Input, Text, toast } from '@/components';
import { FAKE_AUTH } from '@/lib/env';
import { luhn, maskCardNumber, maskExpiry, onlyDigits } from '@/lib/format';
import { brandLabel, detectBrand, tokenizeCard, type TokenizedCard } from '@/lib/vindi';
import { space } from '@/theme';

const schema = z.object({
  number: z.string().refine((v) => luhn(v), 'Número de cartão inválido'),
  holderName: z.string().trim().min(3, 'Nome como está no cartão'),
  expiry: z.string().refine((v) => {
    const m = /^(\d{2})\/(\d{2}|\d{4})$/.exec(v);
    if (!m) return false;
    const month = Number(m[1]);
    const year = m[2]!.length === 2 ? 2000 + Number(m[2]) : Number(m[2]);
    if (month < 1 || month > 12) return false;
    const now = new Date();
    return year > now.getFullYear() || (year === now.getFullYear() && month >= now.getMonth() + 1);
  }, 'Validade inválida'),
  cvv: z.string().refine((v) => /^\d{3,4}$/.test(v), 'CVV inválido'),
});
type FormValues = z.infer<typeof schema>;

interface CardFormProps {
  submitLabel: string;
  onTokenized: (card: TokenizedCard) => Promise<void> | void;
  busy?: boolean;
}

export function CardForm({ submitLabel, onTokenized, busy }: CardFormProps) {
  const vindi = useVindiConfig(!FAKE_AUTH);
  const [tokenizing, setTokenizing] = useState(false);
  const { control, handleSubmit, formState } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { number: '', holderName: '', expiry: '', cvv: '' },
  });
  const numberValue = useWatch({ control, name: 'number' });
  const brand = detectBrand(numberValue);

  const onSubmit = handleSubmit(async (v) => {
    setTokenizing(true);
    try {
      const token = await tokenizeCard({ number: v.number, holderName: v.holderName, expiry: v.expiry, cvv: v.cvv }, vindi.data);
      await onTokenized(token);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Não foi possível validar o cartão.');
    } finally {
      setTokenizing(false);
    }
  });

  const err = formState.errors;
  return (
    <View>
      <Controller
        control={control}
        name="number"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input
            label="Número do cartão"
            value={value}
            onChangeText={(t) => onChange(maskCardNumber(t))}
            onBlur={onBlur}
            keyboardType="number-pad"
            textContentType="creditCardNumber"
            autoComplete="cc-number"
            placeholder="0000 0000 0000 0000"
            error={err.number?.message}
            right={brand ? <Text variant="caption" tone="accent">{brandLabel[brand]}</Text> : null}
          />
        )}
      />
      <Controller
        control={control}
        name="holderName"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="Nome impresso" value={value} onChangeText={onChange} onBlur={onBlur} autoCapitalize="characters" autoComplete="cc-name" error={err.holderName?.message} />
        )}
      />
      <View style={styles.row}>
        <View style={styles.half}>
          <Controller
            control={control}
            name="expiry"
            render={({ field: { onChange, onBlur, value } }) => (
              <Input label="Validade" value={value} onChangeText={(t) => onChange(maskExpiry(t))} onBlur={onBlur} keyboardType="number-pad" placeholder="MM/AA" autoComplete="cc-exp" error={err.expiry?.message} />
            )}
          />
        </View>
        <View style={styles.half}>
          <Controller
            control={control}
            name="cvv"
            render={({ field: { onChange, onBlur, value } }) => (
              <Input label="CVV" value={value} onChangeText={(t) => onChange(onlyDigits(t).slice(0, 4))} onBlur={onBlur} keyboardType="number-pad" secureTextEntry autoComplete="cc-csc" placeholder="123" error={err.cvv?.message} />
            )}
          />
        </View>
      </View>
      <Button title={submitLabel} onPress={onSubmit} loading={tokenizing || busy} />
      <Text variant="caption" tone="dim" center style={styles.hint}>
        {FAKE_AUTH ? 'Modo fake: o cartão não é validado na Vindi.' : 'Seus dados vão direto para a Vindi (PCI). Guardamos só a bandeira e os últimos 4 dígitos.'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: space(3) },
  half: { flex: 1 },
  hint: { marginTop: space(3) },
});
