// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gastoscopio';

  @override
  String get home => 'Inicio';

  @override
  String get movements => 'Movimientos';

  @override
  String get summary => 'Resumen';

  @override
  String get aiAnalysis => 'Análisis IA';

  @override
  String get monthlySummary => 'Resumen del Mes';

  @override
  String get balance => 'Balance';

  @override
  String youSpentPercent(int percent) {
    return 'Has gastado el $percent% de tus ingresos';
  }

  @override
  String get categoryDistribution => 'Distribución de Gastos por Categoría';

  @override
  String get dailyExpenses => 'Gastos Diarios';

  @override
  String get aiAnalysisTitle => 'Análisis de Gastos';

  @override
  String get generate => 'Generar';

  @override
  String get generateAnalysisHint =>
      'Pulsa el botón \"Generar Análisis\" para obtener un análisis detallado de tus gastos e ingresos de este mes.';

  @override
  String noDataForMonth(String month, int year) {
    return 'No hay datos para $month - $year';
  }

  @override
  String get dataWillAppear =>
      'Los datos aparecerán aquí cuando agregues mínimo 5 movimientos.';

  @override
  String get settings => 'Configuración';

  @override
  String get newExpense => 'Nuevo Gasto';

  @override
  String get newIncome => 'Nuevo Ingreso';

  @override
  String get expense => 'Gasto';

  @override
  String get income => 'Ingreso';

  @override
  String get description => 'Descripción';

  @override
  String get amount => 'Monto';

  @override
  String get date => 'Fecha';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get accept => 'Aceptar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get add => 'Añadir';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'English';

  @override
  String get currency => 'Moneda Preferida';

  @override
  String get navigationStyle => 'Estilo de Navegación';

  @override
  String get transparentNavigation => 'Transparente';

  @override
  String get opaqueNavigation => 'Opaca';

  @override
  String get pleaseEnterDescription => 'Por favor ingrese una descripción';

  @override
  String get pleaseEnterAmount => 'Por favor ingrese un monto';

  @override
  String get pleaseEnterValidAmount => 'Por favor ingrese un monto válido';

  @override
  String dateUpdatedToDay(int day) {
    return 'Fecha actualizada al día $day';
  }

  @override
  String errorUpdatingDate(String error) {
    return 'Error al actualizar la fecha: $error';
  }

  @override
  String get movementSaved => '✅ Movimiento guardado';

  @override
  String get movementUpdated => '✅ Movimiento actualizado';

  @override
  String get saving => 'Guardando...';

  @override
  String get sortByDate => 'Por fecha';

  @override
  String get sortByAmount => 'Por monto';

  @override
  String get sortByCategory => 'Por categoría';

  @override
  String get personalization => 'Personalización';

  @override
  String get personalizationSubtitle =>
      'Configura tu experiencia en la aplicación.';

  @override
  String get languageDescription =>
      'Selecciona el idioma de la aplicación. Al elegir \"Idioma del sistema\", la app usará el idioma configurado en Android.';

  @override
  String get currencyDescription =>
      'Selecciona la moneda que se mostrará en toda la aplicación.';

  @override
  String get logoPersonalization => 'Personalización del Logo.';

  @override
  String get logoDescription =>
      'Elige entre PNG estático o SVG personalizable con color.';

  @override
  String get navigationStyleDescription =>
      'Personaliza la apariencia de la barra de navegación inferior.';

  @override
  String get backgroundImage => 'Imagen de fondo';

  @override
  String get backgroundImageDescription =>
      'Selecciona una imagen para usar como fondo en las pantallas de inicio de sesión e inicio.';

  @override
  String get selectImage => 'Seleccionar imagen';

  @override
  String get removeImage => 'Eliminar imagen';

  @override
  String get imageChangedSuccessfully =>
      'Imagen de fondo actualizada correctamente';

  @override
  String get artificialIntelligence => 'Inteligencia Artificial';

  @override
  String get aiDescription => 'Configuración para funciones avanzadas con IA.';

  @override
  String get backupManagement => 'Gestión de copia de seguridad';

  @override
  String get backupDescription => 'Importa y exporta tus datos.';

  @override
  String get languageUpdated => 'Idioma actualizado correctamente';

  @override
  String errorChangingLanguage(String error) {
    return 'Error al cambiar idioma: $error';
  }

  @override
  String get currencyUpdated => 'Moneda actualizada correctamente';

  @override
  String get logoUpdated => 'Logo actualizado correctamente';

  @override
  String get avatarColorUpdated => 'Color de avatar actualizado correctamente';

  @override
  String get transparentBottomNav =>
      'Navegación inferior transparente aplicada';

  @override
  String get opaqueBottomNav => 'Navegación inferior opaca aplicada';

  @override
  String get staticLabel => 'Estático';

  @override
  String get customizableLabel => 'Personalizable';

  @override
  String get svgColorLabel => 'Color del Logo SVG.';

  @override
  String get selectColor => 'Selecciona un Color';

  @override
  String get apply => 'Aplicar';

  @override
  String get solidBackground => 'Fondo sólido';

  @override
  String get glassEffect => 'Efecto cristal';

  @override
  String get loading => 'Cargando...';

  @override
  String get manageRecurringMovements => 'Recurrentes';

  @override
  String get noMovementsToShow => 'No hay movimientos para mostrar.';

  @override
  String get total => 'Total';

  @override
  String get incomes => 'Ingresos';

  @override
  String get expenses => 'Gastos';

  @override
  String get monthBalance => 'Balance del mes';

  @override
  String get expensesByCategory => 'Gastos por Categoría';

  @override
  String get noTagsGenerated =>
      'No se pudieron generar etiquetas para los movimientos. Intente de nuevo más tarde o revise la API key proporcionada en ajustes.';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get byDate => 'Por fecha';

  @override
  String get alphabetical => 'Alfabético';

  @override
  String get byValue => 'Por valor';

  @override
  String get clearSort => 'Limpiar orden';

  @override
  String get generateTagsAutomatically => 'Generar etiquetas automáticamente';

  @override
  String get filteredMovements => 'Mis movimientos';

  @override
  String get totalMovements => 'Total de movimientos:';

  @override
  String get noExpenses => 'No hay gastos.';

  @override
  String get noIncomes => 'No hay ingresos.';

  @override
  String get pleaseEnterValidAmountGreaterThanZero =>
      'Por favor, introduce un monto válido mayor que 0';

  @override
  String get categoryNotGenerated =>
      'No se pudo generar la categoría, se guardará con categoría vacía. Puedes asignarla manualmente más tarde.';

  @override
  String get errorGeneratingCategory =>
      'Error al generar categoría. Se guardará sin categoría.';

  @override
  String get movementUpdatedSuccessfully => 'Movimiento actualizado con éxito';

  @override
  String get movementSavedSuccessfully => 'Movimiento guardado con éxito';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get generalError => 'Error general';

  @override
  String get databaseError => 'Error de base de datos';

  @override
  String get databaseErrorMessage =>
      'No se pudo acceder a la base de datos. Verifica que tengas espacio suficiente en el dispositivo.';

  @override
  String get formatError => 'Error de formato';

  @override
  String get formatErrorMessage =>
      'El formato del monto no es válido. Usa números con punto o coma como decimal.';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get connectionErrorMessage =>
      'Sin conexión a internet. El movimiento se guardará sin categoría automática.';

  @override
  String get permissionError => 'Error de permisos';

  @override
  String get permissionErrorMessage =>
      'La aplicación no tiene permisos para guardar datos. Verifica los permisos de la app.';

  @override
  String get error => 'Error';

  @override
  String get noDataToImport => 'No hay datos para importar';

  @override
  String get importingData => 'Importando datos...';

  @override
  String savingMovements(int count) {
    return 'Guardando $count movimientos';
  }

  @override
  String get ok => 'Ok';

  @override
  String get dataImportedSuccessfully =>
      'Los datos se han importado correctamente';

  @override
  String get errorSavingData => 'Ocurrió un error al guardar los datos';

  @override
  String get databaseInitializationError =>
      'Error al inicializar la base de datos. Por favor, intenta de nuevo.';

  @override
  String get dataFormatError =>
      'Error al guardar los datos. Verifica que el formato del archivo sea correcto.';

  @override
  String get importError => 'Error al importar';

  @override
  String get continueWithoutImporting => 'Continuar sin importar';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get euroSymbol => 'Euro (€)';

  @override
  String get dollarSymbol => 'Dólar Estadounidense (\$)';

  @override
  String get poundSymbol => 'Libra Esterlina (£)';

  @override
  String get yenSymbol => 'Yen Japonés (¥)';

  @override
  String get swissFrancSymbol => 'Franco Suizo (CHF)';

  @override
  String get colombianPesoSymbol => 'Peso Colombiano (COP)';

  @override
  String get png => 'PNG';

  @override
  String get svg => 'SVG';

  @override
  String get fixedMovements => 'Movimientos Fijos';

  @override
  String get automaticMovements => 'Movimientos Automáticos';

  @override
  String get addedAutomaticallyEachMonth =>
      'Se añaden automáticamente cada mes nuevo.';

  @override
  String get noFixedMovements => 'Sin movimientos fijos';

  @override
  String get createRecurringMovements =>
      'Crea movimientos que se repitan automáticamente cada mes, como salarios, alquileres o suscripciones.';

  @override
  String get createFirstMovement => 'Crear primer movimiento.';

  @override
  String dayOfEachMonth(int day) {
    return 'Día $day de cada mes';
  }

  @override
  String movementDeleted(String description) {
    return 'Movimiento \"$description\" eliminado.';
  }

  @override
  String errorLoadingMovements(String error) {
    return 'Error al cargar movimientos: $error';
  }

  @override
  String errorCreatingMovement(String error) {
    return 'Error al crear movimiento: $error';
  }

  @override
  String errorDeletingMovement(String error) {
    return 'Error al eliminar movimiento: $error';
  }

  @override
  String errorUpdatingMovement(String error) {
    return 'Error al actualizar movimiento: $error';
  }

  @override
  String get newFixedMovement => 'Nuevo Movimiento Fijo';

  @override
  String get editMovement => 'Editar Movimiento';

  @override
  String get descriptionRequired => 'La descripción es obligatoria';

  @override
  String get amountRequired => 'La cantidad es obligatoria.';

  @override
  String get enterValidNumber => 'Introduce un número válido.';

  @override
  String get amountMustBeGreaterThanZero => 'La cantidad debe ser mayor que 0.';

  @override
  String get quantity => 'Cantidad';

  @override
  String get dayOfMonth => 'Día del mes';

  @override
  String get from1To31 => 'Del 1 al 31';

  @override
  String get dayRequired => 'El día es obligatorio';

  @override
  String get dayMustBeBetween1And31 => 'El día debe estar entre 1 y 31.';

  @override
  String get movementType => 'Tipo de movimiento';

  @override
  String get saveInCurrentMonth => 'Guardar gasto en mes actual: ';

  @override
  String get create => 'Crear';

  @override
  String errorInData(String error) {
    return 'Error en los datos: $error';
  }

  @override
  String get exampleSalaryRentNetflix => 'Ej: Salario, Alquiler, Netflix...';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get startDayWithEnergy => 'Comienza el día con energía renovada.';

  @override
  String get keepBuildingFinancialFuture =>
      'Sigue construyendo tu futuro financiero.';

  @override
  String get perfectTimeToReviewFinances =>
      'Momento perfecto para revisar tus finanzas.';

  @override
  String get filters => 'Filtros';

  @override
  String get lastMovements => 'Últimos movimientos';

  @override
  String get all => 'Todos';

  @override
  String get search => 'Buscar';

  @override
  String get allCategories => 'Todas las categorías';

  @override
  String get pleaseEnterValidNumber => 'Por favor, ingresa un número válido.';

  @override
  String get dateLabel => 'Fecha:';

  @override
  String get deleteMovement => '¿Eliminar movimiento?';

  @override
  String confirmDeleteMovement(String description) {
    return '¿Estás seguro de que quieres eliminar \"$description\"?';
  }

  @override
  String get changeCategory => 'Cambiar categoría';

  @override
  String get selectCategory => 'Selecciona una categoría';

  @override
  String categoryUpdated(String category) {
    return 'Categoría actualizada: $category.';
  }

  @override
  String get eliminatedSuccessfully => 'eliminado con éxito';

  @override
  String get elimError => 'Error al eliminar ';

  @override
  String get currencyChangedSuccessfully => 'Moneda actualizada correctamente';

  @override
  String get logoChangedSuccessfully => 'Logo actualizado correctamente';

  @override
  String get avatarColorChangedSuccessfully =>
      'Color de avatar actualizado correctamente';

  @override
  String get transparentBottomNavApplied =>
      'Navegación inferior transparente aplicada';

  @override
  String get opaqueBottomNavApplied => 'Navegación inferior opaca aplicada';

  @override
  String get languageChangedSuccessfully => 'Idioma actualizado correctamente';

  @override
  String get cantOpenUrl => 'No se puede abrir el enlace';

  @override
  String get apiKeyCantBeEmpty => '❌ El API Key no puede estar vacío';

  @override
  String get apiKeySavedSuccessfully => '✅ API Key guardada correctamente';

  @override
  String get apiKeySaved => 'API Key guardada';

  @override
  String get importantRestart =>
      'IMPORTANTE: Para que la IA funcione correctamente, debes reiniciar completamente la aplicación.';

  @override
  String get appRestartAdvice =>
      '💡 Cierra la app completamente y vuelve a abrirla.';

  @override
  String get aiFeaturesActivation =>
      'Para activar las funciones de inteligencia artificial, necesitas obtener una clave API de Google. Te guiamos paso a paso:';

  @override
  String get step1 =>
      '1. Accede a Google AI Studio e inicia sesión con tu cuenta';

  @override
  String get step2 =>
      '2. Haz clic en \"Crear clave de API\" y copia la clave generada';

  @override
  String get step2_1 =>
      '2.1. Si aparece esta ventana emergente, ciérrala con la X';

  @override
  String get step2_2 =>
      '2.2. Desplázate hacia abajo hasta encontrar la tabla de claves';

  @override
  String get step2_3 =>
      '2.3. Haz clic en el enlace azul para acceder a la clave';

  @override
  String get step3 =>
      '3. Pega la clave API en el campo de texto de la aplicación';

  @override
  String get step4 =>
      '4. Presiona el botón guardar para completar la configuración';

  @override
  String get goToGoogleAiStudio => 'Ir a Google AI Studio';

  @override
  String get googleApiKey => 'Clave API de Google';

  @override
  String get deleteDatabase => 'Borrar base de datos';

  @override
  String get dbDeleteWarning =>
      'ATENCIÓN: Esta acción eliminará TODOS los datos de la aplicación:';

  @override
  String get dbDeleteList1 => '• Todos los movimientos registrados';

  @override
  String get dbDeleteList2 => '• Todas las categorías personalizadas';

  @override
  String get dbDeleteList3 => '• Todos los movimientos fijos';

  @override
  String get dbDeleteList4 => '• Configuración de colores y preferencias';

  @override
  String get dbDeleteUnrecoverable => 'Esta acción NO se puede deshacer.';

  @override
  String get dbDeleteRecomendation =>
      '💡 Recomendación: Haz un backup antes de continuar.';

  @override
  String get deleteAll => 'Eliminar Todo';

  @override
  String get dbDeletedSuccesfully => '✅ Base de datos limpiada correctamente';

  @override
  String get dbDeleted => 'Base de datos limpiada';

  @override
  String get deDeletedSubtitle =>
      'Todos los datos se han eliminado correctamente.';

  @override
  String get dbDeleteAppRestart =>
      'IMPORTANTE: Para que los cambios se apliquen completamente, es recomendable reiniciar la aplicación.';

  @override
  String get dbDeleteAppRestartAdvice =>
      '💡 Cierra la app completamente y vuelve a abrirla.';

  @override
  String get errorCleaningDatabase => '❌ Error al limpiar la base de datos';

  @override
  String get developerOptions => 'Opciones de Desarrollador';

  @override
  String get developerOptionsSubtitle =>
      'Acceso a funciones avanzadas y de desarrollo.';

  @override
  String get importFromJson => 'Importar desde JSON';

  @override
  String get importFromJsonSubtitle =>
      'Importa datos desde un archivo JSON de Gastoscopio.';

  @override
  String get deleteDatabaseSubtitle =>
      '⚠️ PELIGRO: Borra TODOS los datos de la aplicación de forma permanente. Esta acción no se puede deshacer.';

  @override
  String get cleaning => 'Limpiando...';

  @override
  String get cleanAllData => 'Limpiar Todos los Datos';

  @override
  String get errorSavingApiKey => 'No se ha podido guardar la API Key';

  @override
  String get configureApiKey => 'Configurar API Key';

  @override
  String get enterApiKeyMessage =>
      'Para utilizar las funciones de IA, por favor ingrese su API Key:';

  @override
  String get later => 'Más tarde';

  @override
  String get letsGo => 'Vamos allá';

  @override
  String get noResponseGenerated => 'No se pudo generar una respuesta';

  @override
  String get apiKeyNotConfigured => 'API Key no configurada';

  @override
  String get noMonthSelected => 'Mes no seleccionado';

  @override
  String get createNewMonth => 'Crear nuevo mes';

  @override
  String monthDoesNotExist(String month, String year) {
    return 'El mes $month de $year no existe. ¿Deseas crearlo?';
  }

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get january => 'Enero';

  @override
  String get february => 'Febrero';

  @override
  String get march => 'Marzo';

  @override
  String get april => 'Abril';

  @override
  String get may => 'Mayo';

  @override
  String get june => 'Junio';

  @override
  String get july => 'Julio';

  @override
  String get august => 'Agosto';

  @override
  String get september => 'Septiembre';

  @override
  String get october => 'Octubre';

  @override
  String get november => 'Noviembre';

  @override
  String get december => 'Diciembre';

  @override
  String get name => 'Nombre';

  @override
  String get nameRequired => 'El nombre es requerido';

  @override
  String get invalidAmount => 'Monto inválido';

  @override
  String get loginRequired => 'Inicio de sesión requerido';

  @override
  String get loginToAccess => 'Inicia sesión para acceder a esta función';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get loggedOutSuccessfully => 'Sesión cerrada correctamente';

  @override
  String get loggedInSuccessfully => 'Sesión iniciada correctamente';

  @override
  String get loginError => 'Error al iniciar sesión';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get accountDescription =>
      'Gestiona tu cuenta y las opciones de inicio de sesión';

  @override
  String get futureMovements => 'Movimientos futuros';

  @override
  String get noIaFeaturesHomeTitle =>
      '¡Estás perdiendo acceso a las funciones inteligentes de la app!\n\nActiva la IA para obtener análisis automáticos, sugerencias personalizadas y mucho más. Es gratuito y muy facil de configurar.';

  @override
  String get noIaFeaturesHomeSubtitle =>
      'Para activar las funciones IA, ve a Ajustes > Sección IA y sigue los pasos para introducir tu API Key.';

  @override
  String get activateIaFeatures => '¡Activa las funciones IA!';

  @override
  String get iaFeaturesText => 'Funciones de IA';

  @override
  String get security => 'Seguridad';

  @override
  String get securityDescription =>
      'Configura las funciones de seguridad de acceso a la app.';

  @override
  String get useAppLock => 'Activar bloqueo de la app';

  @override
  String get useAppLockDescription =>
      'Requiere autenticación para acceder a la app.';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get useBiometricsDescription =>
      'Utiliza huella digital o reconocimiento facial para desbloquear.';

  @override
  String get pin => 'PIN';

  @override
  String get enterPin => 'Introduce el PIN';

  @override
  String get enterPinToAccess => 'Introduce el PIN para acceder a la app';

  @override
  String get enterPinSetup =>
      'Introduce un PIN de 4 dígitos para proteger tu app';

  @override
  String get setupPin => 'Configurar PIN';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get changePinDescription => 'Cambia tu código PIN de seguridad';

  @override
  String get invalidPin => 'Código PIN inválido';

  @override
  String get pinSetupSuccess => 'PIN configurado correctamente';

  @override
  String get verify => 'Verificar';

  @override
  String get welcome => 'Bienvenido a Cashly';

  @override
  String get welcomeSubtitle => 'Tu compañero de finanzas personales';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get finish => 'Finalizar';

  @override
  String get onboardingStep1Title => 'Controla tus Finanzas';

  @override
  String get onboardingStep1Desc =>
      'Mantén un registro de tus ingresos y gastos fácilmente';

  @override
  String get onboardingStep2Title => 'Análisis Inteligente';

  @override
  String get onboardingStep2Desc =>
      'Obtén información sobre tus hábitos de gasto con ayuda de IA';

  @override
  String get onboardingStep3Title => 'Seguro y Privado';

  @override
  String get onboardingStep3Desc =>
      'Tus datos permanecen en tu dispositivo, protegidos y privados';

  @override
  String get termsAndConditions => 'Términos y Condiciones';

  @override
  String get agreeToTerms => 'Acepto los Términos y Condiciones';

  @override
  String get pleaseAgreeToTerms =>
      'Por favor acepta los Términos y Condiciones para continuar';

  @override
  String get configureGeminiApiKey => 'Configura tu API Key de Gemini';

  @override
  String get apiKeyRequired =>
      'La API Key es necesaria para utilizar las funciones de IA.\nEs gratis y fácil de obtener.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get welcomeToApp => 'Bienvenido a Gastoscopio';

  @override
  String get connectGoogleAccount =>
      'Conecta tu cuenta de Google para sincronizar y respaldar tus datos financieros';

  @override
  String get noAccountConnected => 'Sin cuenta conectada';

  @override
  String get loginForBackupSync =>
      'Inicia sesión con Google para acceder a funciones de respaldo y sincronización';

  @override
  String get correctlyConnected => 'Conectado correctamente';

  @override
  String get user => 'Usuario';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get optionalLogin =>
      'Opcional: Puedes continuar sin cuenta, pero no tendrás acceso a funciones de respaldo.';

  @override
  String get continueWithoutLogin => 'Continuar sin iniciar sesión';

  @override
  String get continueToNextStep => 'Continuar al siguiente paso';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signingIn => 'Iniciando sesión...';

  @override
  String get signingOut => 'Cerrando sesión...';

  @override
  String get authenticateToAccess =>
      'Por favor, autentícate para acceder a la aplicación';

  @override
  String get biometricAuthFailed => 'Autenticación biométrica fallida';

  @override
  String get showSummary => 'Resumen mensual';

  @override
  String get confrmTagDelete => 'Borrar categorias';

  @override
  String get confirmDeleteAllTags =>
      '¿Quieres borrar las categorias de los movimientos de este mes?';

  @override
  String get migrateMonth => 'Migrar a otro mes';

  @override
  String get selectMonthToMigrate =>
      'Solo se cogerá el mes, no el dia seleccinado';

  @override
  String get savings => 'Ahorros';

  @override
  String get savingsManagement => 'Gestión de ahorros';

  @override
  String get exportComingSoon => 'Función de exportar próximamente';

  @override
  String get setSavingsGoal => 'Establecer objetivo de ahorro';

  @override
  String get enterTargetSavings =>
      'Introduce tu objetivo de ahorro para seguir tu progreso.';

  @override
  String get goalAmount => 'Cantidad objetivo';

  @override
  String get enterAmountHint => 'Introduce la cantidad...';

  @override
  String get saveGoal => 'Guardar objetivo';

  @override
  String get savingsGoal => 'Objetivo de ahorro';

  @override
  String get editGoal => 'Editar objetivo';

  @override
  String percentComplete(Object percent) {
    return '$percent% completado';
  }

  @override
  String get toGo => 'restantes';

  @override
  String get goalAchieved => '¡Objetivo alcanzado! 🎉';

  @override
  String get keyMetrics => 'Métricas clave';

  @override
  String get monthlyAverage => 'Promedio mensual';

  @override
  String get bestMonth => 'Mejor mes';

  @override
  String get worstMonth => 'Peor mes';

  @override
  String get yearlyView => 'Vista anual';

  @override
  String get monthlyView => 'Vista mensual';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get savingsOverview => 'Resumen de ahorros';

  @override
  String get deleteInitialSave => 'Eliminar ahorro inicial';

  @override
  String get addInitialSave => 'Añadir ahorro inicial';

  @override
  String get addInitialSaveTitle => 'Añadir ahorro inicial';

  @override
  String get addInitialSaveDescription =>
      'Introduce tu ahorro inicial para empezar a seguir tu progreso financiero.';

  @override
  String get addSave => 'Añadir ahorro';

  @override
  String get initialLabel => 'Inicial';

  @override
  String get createNextMonth => 'Siguiente mes';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get logs => 'Logs';

  @override
  String get selectDateRange =>
      'Selecciona un rango de fechas para ver los movimientos.';

  @override
  String get viewBreakdown => 'Ver desglose';

  @override
  String get pendingNotifications => 'Transacciones pendientes';

  @override
  String get pendingNotificationsDescription =>
      'Se han detectado transacciones desde tus notificaciones. Revisa y guarda las que quieras.';

  @override
  String get pendingNotificationsSaved =>
      'Transacciones guardadas correctamente';

  @override
  String get saveAll => 'Terminado';

  @override
  String get dismissAll => 'Descartar todo';

  @override
  String savingProgress(int current, int total) {
    return 'Guardando $current de $total...';
  }

  @override
  String get notificationListenerTitle => 'Notificaciones';

  @override
  String get notificationListenerDescription =>
      'Detectar transacciones automáticamente desde tus notificaciones.';

  @override
  String get notificationListenerPermission => 'Escucha de notificaciones';

  @override
  String get notificationListenerActive =>
      'Escuchando transacciones en tus notificaciones.';

  @override
  String get notificationListenerInactive =>
      'No está activo. Actívalo para detectar transacciones automáticamente.';

  @override
  String get notificationListenerGrantPermission => 'Conceder permiso';

  @override
  String get notificationListenerPermissionExplanation =>
      'Para detectar transacciones automáticamente, la app necesita acceso a tus notificaciones. Se te redirigirá a los Ajustes de Android donde debes activar el acceso a notificaciones para Gastoscopio. Solo se procesarán notificaciones que contengan símbolos de moneda (€, \$).';

  @override
  String get notificationListenerPermissionDenied =>
      'No se ha concedido acceso a las notificaciones. No se puede activar el escuchador.';

  @override
  String get notificationBannerTitle => 'Detecta gastos automáticamente';

  @override
  String get notificationBannerSubtitle =>
      'Activa la escucha de notificaciones para capturar tus gastos bancarios sin esfuerzo.';

  @override
  String get blockedApps => 'Apps bloqueadas';

  @override
  String get blockedAppsDescription =>
      'Gestiona qué apps se ignoran al leer notificaciones.';

  @override
  String blockedAppsCount(int count) {
    return '$count apps bloqueadas';
  }

  @override
  String get searchApps => 'Buscar aplicación...';

  @override
  String get noBlockedApps => 'No hay apps bloqueadas';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get addBlockedApp => 'Añadir app a bloquear';

  @override
  String get blockApp => 'Bloquear app';

  @override
  String get block => 'Bloquear';

  @override
  String blockAppConfirmation(String appName) {
    return '¿Bloquear notificaciones de $appName? No se leerán más transacciones de esta app. Puedes desbloquearlo en Ajustes.';
  }

  @override
  String fromApp(String appName) {
    return 'Desde $appName';
  }
}
