import { de } from './de.js';
import { en } from './en.js';
import { fr } from './fr.js';

export const DEFAULT_LANGUAGE = 'en';
export const LANGUAGE_STORAGE_KEY = 'agm_language';

export const languageOptions = [
  { code: 'en', labelKey: 'language.en' },
  { code: 'fr', labelKey: 'language.fr' },
  { code: 'de', labelKey: 'language.de' },
];

export const translations = {
  en,
  fr,
  de,
};

export function isSupportedLanguage(language) {
  return Boolean(translations[language]);
}

function getValueByPath(source, key) {
  return key.split('.').reduce((current, part) => {
    if (!current || typeof current !== 'object') {
      return undefined;
    }

    return current[part];
  }, source);
}

function interpolate(value, params = {}) {
  if (typeof value !== 'string') {
    return value;
  }

  return value.replaceAll(/\{(\w+)\}/g, (_, name) => String(params[name] ?? ''));
}

export function translate(language, key, params) {
  const dictionary = translations[language] ?? translations[DEFAULT_LANGUAGE];
  const localizedValue = getValueByPath(dictionary, key);
  const fallbackValue = getValueByPath(translations[DEFAULT_LANGUAGE], key);
  const value = localizedValue ?? fallbackValue ?? key;

  return interpolate(value, params);
}
