export const API_URL = (process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:3333/v1').replace(/\/$/, '');
export const FAKE_AUTH = process.env.EXPO_PUBLIC_FAKE_AUTH === '1';
export const GOOGLE_IOS_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID || undefined;
export const GOOGLE_ANDROID_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID || undefined;
export const GOOGLE_WEB_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID || undefined;
export const EAS_PROJECT_ID = process.env.EXPO_PUBLIC_EAS_PROJECT_ID || undefined;
