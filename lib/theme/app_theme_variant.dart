enum AppThemeVariant {
  etherealLedger,
  obsidian;

  String get storageValue => switch (this) {
        AppThemeVariant.etherealLedger => 'ethereal_ledger',
        AppThemeVariant.obsidian => 'obsidian',
      };

  /// Localization key for the human-readable name.
  String get displayNameKey => switch (this) {
        AppThemeVariant.etherealLedger => 'themeEthereal',
        AppThemeVariant.obsidian => 'themeObsidian',
      };

  static AppThemeVariant fromStorage(String? value) {
    return AppThemeVariant.values.firstWhere(
      (v) => v.storageValue == value,
      orElse: () => AppThemeVariant.etherealLedger,
    );
  }
}
