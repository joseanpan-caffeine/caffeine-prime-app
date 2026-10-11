import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useQueryClient } from '@tanstack/react-query';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { errorMessage } from '@/api/client';
import { authApi } from '@/api/endpoints';
import { Button, Input, Screen, Text, toast } from '@/components';
import { brDateToIso, isValidCpf, maskCpf, maskDateBR, maskPhone, onlyDigits } from '@/lib/format';
import { completeSignIn } from '@/lib/session';
import { colors, space } from '@/theme';

const schema = z.object({
  firstName: z.string().trim().min(2, 'Informe seu nome'),
  lastName: z.string().trim().min(2, 'Informe seu sobrenome'),
  email: z.string().trim().email('Informe um e-mail válido'),
  password: z.string().min(8, 'Mínimo de 8 caracteres'),
  cpf: z.string().refine(isValidCpf, 'CPF inválido'),
  phone: z.string().refine((v) => onlyDigits(v).length >= 10, 'Telefone inválido'),
  birthDate: z.string().refine((v) => brDateToIso(v) !== null, 'Data inválida (DD/MM/AAAA)'),
});
type FormValues = z.infer<typeof schema>;

export default function Register() {
  const qc = useQueryClient();
  const [submitting, setSubmitting] = useState(false);
  const { control, handleSubmit, formState } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { firstName: '', lastName: '', email: '', password: '', cpf: '', phone: '', birthDate: '' },
  });

  const onSubmit = handleSubmit(async (v) => {
    setSubmitting(true);
    try {
      const res = await authApi.register({
        firstName: v.firstName,
        lastName: v.lastName,
        email: v.email,
        password: v.password,
        cpf: onlyDigits(v.cpf),
        phone: onlyDigits(v.phone),
        birthDate: brDateToIso(v.birthDate) ?? v.birthDate,
      });
      await completeSignIn(res, qc);
    } catch (e) {
      toast.error(errorMessage(e, 'Não foi possível criar a conta.'));
    } finally {
      setSubmitting(false);
    }
  });

  const err = formState.errors;

  return (
    <Screen keyboard title="Criar conta" subtitle="A mesma conta vale para a loja e para o app." style={styles.root}>
      <View style={styles.row}>
        <View style={styles.half}>
          <Controller
            control={control}
            name="firstName"
            render={({ field: { onChange, onBlur, value } }) => (
              <Input label="Nome" value={value} onChangeText={onChange} onBlur={onBlur} textContentType="givenName" error={err.firstName?.message} />
            )}
          />
        </View>
        <View style={styles.half}>
          <Controller
            control={control}
            name="lastName"
            render={({ field: { onChange, onBlur, value } }) => (
              <Input label="Sobrenome" value={value} onChangeText={onChange} onBlur={onBlur} textContentType="familyName" error={err.lastName?.message} />
            )}
          />
        </View>
      </View>
      <Controller
        control={control}
        name="email"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="E-mail" value={value} onChangeText={onChange} onBlur={onBlur} autoCapitalize="none" keyboardType="email-address" textContentType="emailAddress" error={err.email?.message} />
        )}
      />
      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="Senha" value={value} onChangeText={onChange} onBlur={onBlur} secureTextEntry textContentType="newPassword" error={err.password?.message} />
        )}
      />
      <Controller
        control={control}
        name="cpf"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="CPF" value={value} onChangeText={(t) => onChange(maskCpf(t))} onBlur={onBlur} keyboardType="number-pad" placeholder="000.000.000-00" error={err.cpf?.message} />
        )}
      />
      <Controller
        control={control}
        name="phone"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="Telefone" value={value} onChangeText={(t) => onChange(maskPhone(t))} onBlur={onBlur} keyboardType="phone-pad" placeholder="(11) 99999-9999" textContentType="telephoneNumber" error={err.phone?.message} />
        )}
      />
      <Controller
        control={control}
        name="birthDate"
        render={({ field: { onChange, onBlur, value } }) => (
          <Input label="Data de nascimento" value={value} onChangeText={(t) => onChange(maskDateBR(t))} onBlur={onBlur} keyboardType="number-pad" placeholder="DD/MM/AAAA" error={err.birthDate?.message} />
        )}
      />
      <Button title="Criar conta" onPress={onSubmit} loading={submitting} style={styles.submit} />
      <Text variant="caption" tone="dim" center style={styles.terms}>
        Ao criar a conta você concorda com os Termos de uso e a Política de privacidade.
      </Text>
    </Screen>
  );
}

const styles = StyleSheet.create({
  root: { backgroundColor: colors.surface },
  row: { flexDirection: 'row', gap: space(3) },
  half: { flex: 1 },
  submit: { marginTop: space(2) },
  terms: { marginTop: space(4) },
});
