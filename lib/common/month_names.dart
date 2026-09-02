import 'package:cashly/l10n/app_localizations.dart';

/// Localized full month names, index 0 = January.
List<String> monthFullNames(AppLocalizations l) => [
      l.january,
      l.february,
      l.march,
      l.april,
      l.may,
      l.june,
      l.july,
      l.august,
      l.september,
      l.october,
      l.november,
      l.december,
    ];

/// Localized 3-letter month abbreviations, index 0 = Jan/Ene.
List<String> monthShortNames(AppLocalizations l) => monthFullNames(l)
    .map((m) => m.length >= 3 ? m.substring(0, 3) : m)
    .toList();
