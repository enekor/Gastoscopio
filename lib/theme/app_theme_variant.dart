enum AppThemeVariant {
  etherealLedger,
  obsidian,
  monochromeGlyph;

  String get storageValue => switch (this) {
        AppThemeVariant.etherealLedger => 'ethereal_ledger',
        AppThemeVariant.obsidian => 'obsidian',
        AppThemeVariant.monochromeGlyph => 'monochrome_glyph',
      };

  /// Localization key for the human-readable name.
  String get displayNameKey => switch (this) {
        AppThemeVariant.etherealLedger => 'themeEthereal',
        AppThemeVariant.obsidian => 'themeObsidian',
        AppThemeVariant.monochromeGlyph => 'themeMonochrome',
      };

  static AppThemeVariant fromStorage(String? value) {
    return AppThemeVariant.values.firstWhere(
      (v) => v.storageValue == value,
      orElse: () => AppThemeVariant.etherealLedger,
    );
  }
}
