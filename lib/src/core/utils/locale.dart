import 'package:flutter/material.dart';

abstract final class LocaleUtil {
  static Locale? resolve(
    List<Locale>? locales,
    Iterable<Locale> supportedLocales,
  ) {
    const defaultLocale = Locale('en');
    if (locales == null || locales.isEmpty) return defaultLocale;
    final supported = supportedLocales.toList(growable: false);
    if (supported.isEmpty) return defaultLocale;

    final preferred = [
      for (final locale in locales) _withChineseScript(locale),
    ];
    final match = basicLocaleListResolution(preferred, supported);

    // `basicLocaleListResolution` falls back to the first supported locale
    // when no language matches. Keep this app's default instead of allowing a
    // regional mismatch to select, for example, Azerbaijani.
    final languages = {for (final locale in preferred) locale.languageCode};
    return languages.contains(match.languageCode) ? match : defaultLocale;
  }

  /// Flutter resolves language-only matches, but a bare `zh` supported locale
  /// otherwise also catches Traditional Chinese systems. The runners report
  /// regions (`zh_CN`, `zh_HK`) or scripts (`zh_Hans`, `zh_Hant`), while this
  /// app ships one Simplified and one Traditional translation.
  static Locale _withChineseScript(Locale locale) {
    if (locale.languageCode != 'zh') return locale;

    final script = locale.scriptCode?.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    if (script == 'hant' ||
        country == 'TW' ||
        country == 'HK' ||
        country == 'MO') {
      return const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW');
    }
    return const Locale('zh');
  }
}
