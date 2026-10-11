import type { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'Caffeine Prime',
  slug: 'caffeine-prime',
  version: '1.0.0',
  orientation: 'portrait',
  scheme: 'caffeineprime',
  icon: './assets/icon.png',
  userInterfaceStyle: 'dark',
  backgroundColor: '#0E0B09',
  ios: {
    bundleIdentifier: 'com.caffeinearmy.prime',
    supportsTablet: false,
    usesAppleSignIn: true,
    infoPlist: {
      ITSAppUsesNonExemptEncryption: false,
    },
  },
  android: {
    package: 'com.caffeinearmy.prime',
    adaptiveIcon: {
      backgroundColor: '#0E0B09',
      foregroundImage: './assets/android-icon-foreground.png',
      backgroundImage: './assets/android-icon-background.png',
      monochromeImage: './assets/android-icon-monochrome.png',
    },
    intentFilters: [
      {
        action: 'VIEW',
        autoVerify: true,
        data: [{ scheme: 'caffeineprime', host: 'auth', pathPrefix: '/magic' }],
        category: ['BROWSABLE', 'DEFAULT'],
      },
    ],
  },
  web: {
    bundler: 'metro',
    favicon: './assets/favicon.png',
  },
  plugins: [
    'expo-router',
    'expo-secure-store',
    'expo-apple-authentication',
    [
      'expo-notifications',
      {
        color: '#E0A24A',
      },
    ],
    [
      'expo-splash-screen',
      {
        image: './assets/splash-icon.png',
        resizeMode: 'contain',
        backgroundColor: '#0E0B09',
      },
    ],
  ],
  extra: {
    eas: {
      projectId: process.env.EXPO_PUBLIC_EAS_PROJECT_ID ?? undefined,
    },
  },
});
