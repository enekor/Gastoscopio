// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gastoscopio';

  @override
  String get home => 'Home';

  @override
  String get movements => 'Movements';

  @override
  String get summary => 'Summary';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get balance => 'Balance';

  @override
  String youSpentPercent(int percent) {
    return 'You have spent $percent% of your income';
  }

  @override
  String get categoryDistribution => 'Expense Distribution by Category';

  @override
  String get dailyExpenses => 'Daily Expenses';

  @override
  String get aiAnalysisTitle => 'Expense Analysis';

  @override
  String get generate => 'Generate';

  @override
  String get generateAnalysisHint =>
      'Press the \"Generate Analysis\" button to get a detailed analysis of your expenses and income for this month.';

  @override
  String noDataForMonth(String month, int year) {
    return 'No data for $year - $month ';
  }

  @override
  String get dataWillAppear =>
      'Data will appear here when you add at least 5 movements.';

  @override
  String get settings => 'Settings';

  @override
  String get newExpense => 'New Expense';

  @override
  String get newIncome => 'New Income';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get accept => 'Accept';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get selectDate => 'Select date';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get currency => 'Preferred Currency';

  @override
  String get navigationStyle => 'Navigation Style';

  @override
  String get transparentNavigation => 'Transparent';

  @override
  String get opaqueNavigation => 'Opaque';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String dateUpdatedToDay(int day) {
    return 'Date updated to day $day';
  }

  @override
  String errorUpdatingDate(String error) {
    return 'Error updating date: $error';
  }

  @override
  String get movementSaved => '✅ Movement saved';

  @override
  String get movementUpdated => '✅ Movement updated';

  @override
  String get saving => 'Saving...';

  @override
  String get sortByDate => 'By date';

  @override
  String get sortByAmount => 'By amount';

  @override
  String get sortByCategory => 'By category';

  @override
  String get personalization => 'Personalization';

  @override
  String get personalizationSubtitle => 'Configure your app experience.';

  @override
  String get languageDescription =>
      'Select the app language. Choosing \"System language\" will use your Android language setting.';

  @override
  String get currencyDescription =>
      'Select the currency to display throughout the app.';

  @override
  String get logoPersonalization => 'Logo Personalization.';

  @override
  String get logoDescription =>
      'Choose between static PNG or customizable SVG with color.';

  @override
  String get navigationStyleDescription =>
      'Customize the bottom navigation bar appearance.';

  @override
  String get artificialIntelligence => 'Artificial Intelligence';

  @override
  String get aiDescription => 'Configuration for advanced AI features.';

  @override
  String get backupManagement => 'Backup Management';

  @override
  String get backupDescription => 'Import and export your data.';

  @override
  String get languageUpdated => 'Language updated successfully';

  @override
  String errorChangingLanguage(String error) {
    return 'Error changing language: $error';
  }

  @override
  String get currencyUpdated => 'Currency updated successfully';

  @override
  String get logoUpdated => 'Logo updated successfully';

  @override
  String get avatarColorUpdated => 'Avatar color updated successfully';

  @override
  String get transparentBottomNav => 'Transparent bottom navigation applied';

  @override
  String get opaqueBottomNav => 'Opaque bottom navigation applied';

  @override
  String get staticLabel => 'Static';

  @override
  String get customizableLabel => 'Customizable';

  @override
  String get svgColorLabel => 'SVG Logo Color.';

  @override
  String get selectColor => 'Select a Color';

  @override
  String get apply => 'Apply';

  @override
  String get solidBackground => 'Solid background';

  @override
  String get glassEffect => 'Glass effect';

  @override
  String get loading => 'Loading...';

  @override
  String get manageRecurringMovements => 'Manage Recurring Movements';

  @override
  String get noMovementsToShow => 'No movements to show.';

  @override
  String get total => 'Total';

  @override
  String get incomes => 'Incomes';

  @override
  String get expenses => 'Expenses';

  @override
  String get monthBalance => 'Month Balance';

  @override
  String get expensesByCategory => 'Expenses by Category';

  @override
  String get noTagsGenerated =>
      'Could not generate tags for movements. Try again later or check the API key provided in settings.';

  @override
  String get sortBy => 'Sort by';

  @override
  String get byDate => 'By date';

  @override
  String get alphabetical => 'Alphabetical';

  @override
  String get byValue => 'By value';

  @override
  String get clearSort => 'Clear sort';

  @override
  String get generateTagsAutomatically => 'Generate tags automatically';

  @override
  String get filteredMovements => 'Filtered movements:';

  @override
  String get totalMovements => 'Total movements:';

  @override
  String get noExpenses => 'No expenses.';

  @override
  String get noIncomes => 'No incomes.';

  @override
  String get pleaseEnterValidAmountGreaterThanZero =>
      'Please enter a valid amount greater than 0';

  @override
  String get categoryNotGenerated =>
      'Could not generate category, will be saved with empty category. You can assign it manually later.';

  @override
  String get errorGeneratingCategory =>
      'Error generating category. Will be saved without category.';

  @override
  String get movementUpdatedSuccessfully => 'Movement updated successfully';

  @override
  String get movementSavedSuccessfully => 'Movement saved successfully';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get generalError => 'General error';

  @override
  String get databaseError => 'Database error';

  @override
  String get databaseErrorMessage =>
      'Could not access database. Check that you have enough storage space on the device.';

  @override
  String get formatError => 'Format error';

  @override
  String get formatErrorMessage =>
      'Amount format is invalid. Use numbers with dot or comma as decimal.';

  @override
  String get connectionError => 'Connection error';

  @override
  String get connectionErrorMessage =>
      'No internet connection. Movement will be saved without automatic category.';

  @override
  String get permissionError => 'Permission error';

  @override
  String get permissionErrorMessage =>
      'App doesn\'t have permission to save data. Check app permissions.';

  @override
  String get error => 'Error';

  @override
  String get noDataToImport => 'No data to import';

  @override
  String get importingData => 'Importing data...';

  @override
  String savingMovements(int count) {
    return 'Saving $count movements';
  }

  @override
  String get ok => 'Ok';

  @override
  String get dataImportedSuccessfully => 'Data has been imported successfully';

  @override
  String get errorSavingData => 'An error occurred while saving data';

  @override
  String get databaseInitializationError =>
      'Error initializing database. Please try again.';

  @override
  String get dataFormatError =>
      'Error saving data. Check that the file format is correct.';

  @override
  String get importError => 'Import Error';

  @override
  String get continueWithoutImporting => 'Continue without importing';

  @override
  String get tryAgain => 'Try again';

  @override
  String get euroSymbol => 'Euro (€)';

  @override
  String get dollarSymbol => 'US Dollar (\$)';

  @override
  String get poundSymbol => 'British Pound (£)';

  @override
  String get yenSymbol => 'Japanese Yen (¥)';

  @override
  String get swissFrancSymbol => 'Swiss Franc (CHF)';

  @override
  String get colombianPesoSymbol => 'Colombian Peso (COP)';

  @override
  String get png => 'PNG';

  @override
  String get svg => 'SVG';

  @override
  String get fixedMovements => 'Fixed Movements';

  @override
  String get automaticMovements => 'Automatic Movements';

  @override
  String get addedAutomaticallyEachMonth =>
      'Added automatically each new month.';

  @override
  String get noFixedMovements => 'No fixed movements';

  @override
  String get createRecurringMovements =>
      'Create movements that repeat automatically each month, like salaries, rent or subscriptions.';

  @override
  String get createFirstMovement => 'Create first movement.';

  @override
  String dayOfEachMonth(int day) {
    return 'Day $day of each month';
  }

  @override
  String movementDeleted(String description) {
    return 'Movement \"$description\" deleted.';
  }

  @override
  String errorLoadingMovements(String error) {
    return 'Error loading movements: $error';
  }

  @override
  String errorCreatingMovement(String error) {
    return 'Error creating movement: $error';
  }

  @override
  String errorDeletingMovement(String error) {
    return 'Error deleting movement: $error';
  }

  @override
  String errorUpdatingMovement(String error) {
    return 'Error updating movement: $error';
  }

  @override
  String get newFixedMovement => 'New Fixed Movement';

  @override
  String get editMovement => 'Edit Movement';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get amountRequired => 'Amount is required.';

  @override
  String get enterValidNumber => 'Enter a valid number.';

  @override
  String get amountMustBeGreaterThanZero => 'Amount must be greater than 0.';

  @override
  String get quantity => 'Amount';

  @override
  String get dayOfMonth => 'Day of month';

  @override
  String get from1To31 => 'From 1 to 31';

  @override
  String get dayRequired => 'Day is required';

  @override
  String get dayMustBeBetween1And31 => 'Day must be between 1 and 31.';

  @override
  String get movementType => 'Movement type';

  @override
  String get saveInCurrentMonth => 'Save expense in current month: ';

  @override
  String get create => 'Create';

  @override
  String errorInData(String error) {
    return 'Error in data: $error';
  }

  @override
  String get exampleSalaryRentNetflix => 'E.g: Salary, Rent, Netflix...';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get startDayWithEnergy => 'Start the day with renewed energy.';

  @override
  String get keepBuildingFinancialFuture =>
      'Keep building your financial future.';

  @override
  String get perfectTimeToReviewFinances =>
      'Perfect time to review your finances.';

  @override
  String get filters => 'Filters';

  @override
  String get lastMovements => 'Recent movements';

  @override
  String get all => 'All';

  @override
  String get search => 'Search';

  @override
  String get allCategories => 'All categories';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get dateLabel => 'Date';

  @override
  String get deleteMovement => 'Delete Movement';

  @override
  String confirmDeleteMovement(String description) {
    return 'Are you sure you want to delete this movement?';
  }

  @override
  String get changeCategory => 'Change Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String categoryUpdated(String category) {
    return 'Category updated successfully';
  }

  @override
  String get eliminatedSuccessfully => 'Eliminated successfully';

  @override
  String get elimError => 'Error deleting';

  @override
  String get currencyChangedSuccessfully => 'Currency updated successfully';

  @override
  String get logoChangedSuccessfully => 'Logo updated successfully';

  @override
  String get avatarColorChangedSuccessfully =>
      'Avatar color updated successfully';

  @override
  String get transparentBottomNavApplied =>
      'Transparent bottom navigation applied';

  @override
  String get opaqueBottomNavApplied => 'Opaque bottom navigation applied';

  @override
  String get languageChangedSuccessfully => 'Language updated successfully';

  @override
  String get cantOpenUrl => 'Cannot open the link';

  @override
  String get apiKeyCantBeEmpty => '❌ API Key cannot be empty';

  @override
  String get apiKeySavedSuccessfully => '✅ API Key saved successfully';

  @override
  String get apiKeySaved => 'API Key saved';

  @override
  String get importantRestart =>
      'IMPORTANT: For AI to work properly, you must completely restart the app.';

  @override
  String get appRestartAdvice => '💡 Close the app completely and reopen it.';

  @override
  String get aiFeaturesActivation =>
      'To activate artificial intelligence features, you need to obtain a Google API key. We guide you step by step:';

  @override
  String get step1 => '1. Go to Google AI Studio and sign in with your account';

  @override
  String get step2 =>
      '2. Click on \"Create API key\" and copy the generated key';

  @override
  String get step2_1 => '2.1. If this popup appears, close it with the X';

  @override
  String get step2_2 => '2.2. Scroll down until you find the keys table';

  @override
  String get step2_3 => '2.3. Click the blue link to access the key';

  @override
  String get step3 => '3. Paste the API key into the app\'s text field';

  @override
  String get step4 => '4. Press the save button to complete the setup';

  @override
  String get goToGoogleAiStudio => 'Go to Google AI Studio';

  @override
  String get googleApiKey => 'Google API Key';

  @override
  String get deleteDatabase => 'Delete database';

  @override
  String get dbDeleteWarning =>
      'WARNING: This action will delete ALL app data:';

  @override
  String get dbDeleteList1 => '• All recorded movements';

  @override
  String get dbDeleteList2 => '• All custom categories';

  @override
  String get dbDeleteList3 => '• All fixed movements';

  @override
  String get dbDeleteList4 => '• Color settings and preferences';

  @override
  String get dbDeleteUnrecoverable => 'This action CANNOT be undone.';

  @override
  String get dbDeleteRecomendation =>
      '💡 Recommendation: Make a backup before continuing.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get dbDeletedSuccesfully => '✅ Database cleaned successfully';

  @override
  String get dbDeleted => 'Database cleaned';

  @override
  String get deDeletedSubtitle => 'All data has been deleted successfully.';

  @override
  String get dbDeleteAppRestart =>
      'IMPORTANT: To fully apply the changes, it is recommended to restart the app.';

  @override
  String get dbDeleteAppRestartAdvice =>
      '💡 Close the app completely and reopen it.';

  @override
  String get errorCleaningDatabase => '❌ Error cleaning the database';

  @override
  String get developerOptions => 'Developer Options';

  @override
  String get developerOptionsSubtitle =>
      'Access to advanced and development features.';

  @override
  String get importFromJson => 'Import from JSON';

  @override
  String get importFromJsonSubtitle =>
      'Import data from a Gastoscopio JSON file.';

  @override
  String get deleteDatabaseSubtitle =>
      '⚠️ DANGER: Permanently deletes ALL app data. This action cannot be undone.';

  @override
  String get cleaning => 'Cleaning...';

  @override
  String get cleanAllData => 'Clean All Data';

  @override
  String get errorSavingApiKey => '❌ Error saving API Key';

  @override
  String get configureApiKey => 'Configure API Key';

  @override
  String get enterApiKeyMessage =>
      'To use AI features, please enter your API Key:';

  @override
  String get later => 'Later';

  @override
  String get letsGo => 'Let\'s go';

  @override
  String get noResponseGenerated => 'Could not generate a response';

  @override
  String get apiKeyNotConfigured => 'API Key not configured';

  @override
  String get noMonthSelected => 'No month selected';

  @override
  String get createNewMonth => 'Create new month';

  @override
  String monthDoesNotExist(String month, String year) {
    return 'The month $month of $year does not exist. Would you like to create it?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get loginRequired => 'Login Required';

  @override
  String get loginToAccess => 'Sign in to access this feature';

  @override
  String get login => 'Sign in';

  @override
  String get logout => 'Sign out';

  @override
  String get loggedOutSuccessfully => 'Signed out successfully';

  @override
  String get loggedInSuccessfully => 'Signed in successfully';

  @override
  String get loginError => 'Sign in error';

  @override
  String get accountSection => 'Account';

  @override
  String get accountDescription => 'Manage your account and sign-in options';

  @override
  String get futureMovements => 'Future Movements';

  @override
  String get noIaFeaturesHomeTitle =>
      'You are missing out on the app\'s smart features!\n\nEnable AI to get automatic analysis, personalized suggestions, and much more. It\'s free and very easy to set up.';

  @override
  String get noIaFeaturesHomeSubtitle =>
      'Discover smart analysis, recommendations and more. Tap to learn how to enable AI features.';

  @override
  String get activateIaFeatures => 'Enable AI Features!';

  @override
  String get iaFeaturesText => 'AI features';

  @override
  String get security => 'Security';

  @override
  String get securityDescription => 'Configure app access security features.';

  @override
  String get useAppLock => 'Enable app lock';

  @override
  String get useAppLockDescription =>
      'Require authentication to access the app.';

  @override
  String get useBiometrics => 'Use biometrics';

  @override
  String get useBiometricsDescription =>
      'Use fingerprint or face recognition to unlock.';

  @override
  String get pin => 'PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get enterPinToAccess => 'Enter PIN to access the app';

  @override
  String get enterPinSetup => 'Enter a 4-digit PIN to secure your app';

  @override
  String get setupPin => 'Setup PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinDescription => 'Change your security PIN code';

  @override
  String get invalidPin => 'Invalid PIN code';

  @override
  String get pinSetupSuccess => 'PIN setup successfully';

  @override
  String get verify => 'Verify';

  @override
  String get welcome => 'Welcome to Cashly';

  @override
  String get welcomeSubtitle => 'Your personal finance companion';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Finish';

  @override
  String get onboardingStep1Title => 'Track Your Finances';

  @override
  String get onboardingStep1Desc =>
      'Keep track of your income and expenses easily';

  @override
  String get onboardingStep2Title => 'Smart Analytics';

  @override
  String get onboardingStep2Desc =>
      'Get insights about your spending habits with AI assistance';

  @override
  String get onboardingStep3Title => 'Secure and Private';

  @override
  String get onboardingStep3Desc =>
      'Your data stays on your device, protected and private';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get agreeToTerms => 'I agree to the Terms and Conditions';

  @override
  String get pleaseAgreeToTerms =>
      'Please agree to the Terms and Conditions to continue';

  @override
  String get configureGeminiApiKey => 'Configure your Gemini API Key';

  @override
  String get apiKeyRequired =>
      'API Key is required for AI features.\nIt\'s free and easy to obtain.';

  @override
  String get continueAction => 'Continue';

  @override
  String get welcomeToApp => 'Welcome to Cashly';

  @override
  String get connectGoogleAccount =>
      'Connect your Google account to sync and backup your financial data';

  @override
  String get noAccountConnected => 'No account connected';

  @override
  String get loginForBackupSync =>
      'Sign in with Google to access backup and sync features';

  @override
  String get correctlyConnected => 'Successfully connected';

  @override
  String get user => 'User';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get optionalLogin =>
      'Optional: You can continue without an account, but you won\'t have access to backup features.';

  @override
  String get continueWithoutLogin => 'Continue without signing in';

  @override
  String get continueToNextStep => 'Continue to next step';

  @override
  String get signOut => 'Sign in out';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signingOut => 'Signing out...';

  @override
  String get authenticateToAccess => 'Please authenticate to access the app';

  @override
  String get biometricAuthFailed => 'Biometric authentication failed';

  @override
  String get showSummary => 'Monthly insights.';

  @override
  String get confrmTagDelete => 'Delete categories';

  @override
  String get confirmDeleteAllTags =>
      'Do you want to delete all the tags from this month\'s movements?';

  @override
  String get migrateMonth => 'Migrate to another month';

  @override
  String get selectMonthToMigrate =>
      'It only takes the month, not the selected day';
}
