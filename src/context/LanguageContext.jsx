import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react';
import {
  DEFAULT_LANGUAGE,
  LANGUAGE_STORAGE_KEY,
  isSupportedLanguage,
  languageOptions,
  translate,
} from '../i18n/index.js';

export const LanguageContext = createContext(null);

function safeLocalStorage() {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

function readStoredLanguage() {
  const storedLanguage = safeLocalStorage()?.getItem(LANGUAGE_STORAGE_KEY);
  return isSupportedLanguage(storedLanguage) ? storedLanguage : DEFAULT_LANGUAGE;
}

export function LanguageProvider({ children }) {
  const [language, setLanguageState] = useState(readStoredLanguage);

  const setLanguage = useCallback((nextLanguage) => {
    setLanguageState(isSupportedLanguage(nextLanguage) ? nextLanguage : DEFAULT_LANGUAGE);
  }, []);

  const t = useCallback((key, params) => translate(language, key, params), [language]);

  useEffect(() => {
    safeLocalStorage()?.setItem(LANGUAGE_STORAGE_KEY, language);

    if (typeof document !== 'undefined') {
      document.documentElement.lang = language;
    }
  }, [language]);

  const value = useMemo(
    () => ({
      language,
      languageOptions,
      setLanguage,
      t,
    }),
    [language, setLanguage, t],
  );

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const context = React.useContext(LanguageContext);

  if (!context) {
    throw new Error('useLanguage must be used inside LanguageProvider.');
  }

  return context;
}
