import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en')
  ];

  /// El título de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Gastoscopio'**
  String get appTitle;

  /// Pestaña de inicio
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// Pestaña de movimientos
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get movements;

  /// Pestaña de resumen
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summary;

  /// Pestaña de análisis IA
  ///
  /// In es, this message translates to:
  /// **'Análisis IA'**
  String get aiAnalysis;

  /// Título del resumen mensual
  ///
  /// In es, this message translates to:
  /// **'Resumen del Mes'**
  String get monthlySummary;

  /// Etiqueta para balance
  ///
  /// In es, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Mensaje de porcentaje de gastos
  ///
  /// In es, this message translates to:
  /// **'Has gastado el {percent}% de tus ingresos'**
  String youSpentPercent(int percent);

  /// Título de distribución de gastos por categoría
  ///
  /// In es, this message translates to:
  /// **'Distribución de Gastos por Categoría'**
  String get categoryDistribution;

  /// Título de gastos diarios
  ///
  /// In es, this message translates to:
  /// **'Gastos Diarios'**
  String get dailyExpenses;

  /// Título del análisis de gastos
  ///
  /// In es, this message translates to:
  /// **'Análisis de Gastos'**
  String get aiAnalysisTitle;

  /// Botón para generar análisis
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get generate;

  /// Instrucción para generar análisis
  ///
  /// In es, this message translates to:
  /// **'Pulsa el botón \"Generar Análisis\" para obtener un análisis detallado de tus gastos e ingresos de este mes.'**
  String get generateAnalysisHint;

  /// Mensaje cuando no hay datos para un mes específico
  ///
  /// In es, this message translates to:
  /// **'No hay datos para {month} - {year}'**
  String noDataForMonth(String month, int year);

  /// Mensaje cuando no hay datos
  ///
  /// In es, this message translates to:
  /// **'Los datos aparecerán aquí cuando agregues mínimo 5 movimientos.'**
  String get dataWillAppear;

  /// Pantalla de ajustes
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// Título para nuevo gasto
  ///
  /// In es, this message translates to:
  /// **'Nuevo Gasto'**
  String get newExpense;

  /// Título para nuevo ingreso
  ///
  /// In es, this message translates to:
  /// **'Nuevo Ingreso'**
  String get newIncome;

  /// Etiqueta para gasto
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get expense;

  /// Etiqueta para ingreso
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get income;

  /// Campo de descripción
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// Campo de monto
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amount;

  /// Campo de fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// Botón guardar
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// Botón cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Botón aceptar
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// Botón editar
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// Botón eliminar
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// Botón añadir
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// Título del selector de fecha
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get selectDate;

  /// Configuración de idioma
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// Opción para usar idioma del sistema
  ///
  /// In es, this message translates to:
  /// **'Idioma del sistema'**
  String get systemLanguage;

  /// Idioma español
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// Idioma inglés
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get english;

  /// Configuración de moneda
  ///
  /// In es, this message translates to:
  /// **'Moneda Preferida'**
  String get currency;

  /// Configuración del estilo de navegación
  ///
  /// In es, this message translates to:
  /// **'Estilo de Navegación'**
  String get navigationStyle;

  /// Opción de navegación transparente
  ///
  /// In es, this message translates to:
  /// **'Transparente'**
  String get transparentNavigation;

  /// Opción de navegación opaca
  ///
  /// In es, this message translates to:
  /// **'Opaca'**
  String get opaqueNavigation;

  /// Mensaje de validación para descripción
  ///
  /// In es, this message translates to:
  /// **'Por favor ingrese una descripción'**
  String get pleaseEnterDescription;

  /// Mensaje de validación para monto
  ///
  /// In es, this message translates to:
  /// **'Por favor ingrese un monto'**
  String get pleaseEnterAmount;

  /// Mensaje de validación para monto válido
  ///
  /// In es, this message translates to:
  /// **'Por favor ingrese un monto válido'**
  String get pleaseEnterValidAmount;

  /// Mensaje de confirmación de actualización de fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha actualizada al día {day}'**
  String dateUpdatedToDay(int day);

  /// Mensaje de error al actualizar fecha
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar la fecha: {error}'**
  String errorUpdatingDate(String error);

  /// Mensaje de éxito al guardar movimiento
  ///
  /// In es, this message translates to:
  /// **'✅ Movimiento guardado'**
  String get movementSaved;

  /// Mensaje de éxito al actualizar movimiento
  ///
  /// In es, this message translates to:
  /// **'✅ Movimiento actualizado'**
  String get movementUpdated;

  /// Texto mostrado mientras se guarda
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get saving;

  /// Opción de ordenar por fecha
  ///
  /// In es, this message translates to:
  /// **'Por fecha'**
  String get sortByDate;

  /// Opción de ordenar por monto
  ///
  /// In es, this message translates to:
  /// **'Por monto'**
  String get sortByAmount;

  /// Opción de ordenar por categoría
  ///
  /// In es, this message translates to:
  /// **'Por categoría'**
  String get sortByCategory;

  /// Sección de personalización
  ///
  /// In es, this message translates to:
  /// **'Personalización'**
  String get personalization;

  /// Subtítulo de personalización
  ///
  /// In es, this message translates to:
  /// **'Configura tu experiencia en la aplicación.'**
  String get personalizationSubtitle;

  /// Descripción de configuración de idioma
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma de la aplicación. Al elegir \"Idioma del sistema\", la app usará el idioma configurado en Android.'**
  String get languageDescription;

  /// Descripción de configuración de moneda
  ///
  /// In es, this message translates to:
  /// **'Selecciona la moneda que se mostrará en toda la aplicación.'**
  String get currencyDescription;

  /// Título de personalización de logo
  ///
  /// In es, this message translates to:
  /// **'Personalización del Logo.'**
  String get logoPersonalization;

  /// Descripción de configuración de logo
  ///
  /// In es, this message translates to:
  /// **'Elige entre PNG estático o SVG personalizable con color.'**
  String get logoDescription;

  /// Descripción de estilo de navegación
  ///
  /// In es, this message translates to:
  /// **'Personaliza la apariencia de la barra de navegación inferior.'**
  String get navigationStyleDescription;

  /// Sección de IA
  ///
  /// In es, this message translates to:
  /// **'Inteligencia Artificial'**
  String get artificialIntelligence;

  /// Descripción de IA
  ///
  /// In es, this message translates to:
  /// **'Configuración para funciones avanzadas con IA.'**
  String get aiDescription;

  /// Sección de backup
  ///
  /// In es, this message translates to:
  /// **'Gestión de copia de seguridad'**
  String get backupManagement;

  /// Descripción de backup
  ///
  /// In es, this message translates to:
  /// **'Importa y exporta tus datos.'**
  String get backupDescription;

  /// Mensaje de éxito al cambiar idioma
  ///
  /// In es, this message translates to:
  /// **'Idioma actualizado correctamente'**
  String get languageUpdated;

  /// Mensaje de error al cambiar idioma
  ///
  /// In es, this message translates to:
  /// **'Error al cambiar idioma: {error}'**
  String errorChangingLanguage(String error);

  /// Mensaje de éxito al cambiar moneda
  ///
  /// In es, this message translates to:
  /// **'Moneda actualizada correctamente'**
  String get currencyUpdated;

  /// Mensaje de éxito al cambiar logo
  ///
  /// In es, this message translates to:
  /// **'Logo actualizado correctamente'**
  String get logoUpdated;

  /// Mensaje de éxito al cambiar color
  ///
  /// In es, this message translates to:
  /// **'Color de avatar actualizado correctamente'**
  String get avatarColorUpdated;

  /// Mensaje de navegación transparente
  ///
  /// In es, this message translates to:
  /// **'Navegación inferior transparente aplicada'**
  String get transparentBottomNav;

  /// Mensaje de navegación opaca
  ///
  /// In es, this message translates to:
  /// **'Navegación inferior opaca aplicada'**
  String get opaqueBottomNav;

  /// Etiqueta para PNG estático
  ///
  /// In es, this message translates to:
  /// **'Estático'**
  String get staticLabel;

  /// Etiqueta para SVG personalizable
  ///
  /// In es, this message translates to:
  /// **'Personalizable'**
  String get customizableLabel;

  /// Etiqueta para color de SVG
  ///
  /// In es, this message translates to:
  /// **'Color del Logo SVG.'**
  String get svgColorLabel;

  /// Título del selector de color
  ///
  /// In es, this message translates to:
  /// **'Selecciona un Color'**
  String get selectColor;

  /// Botón aplicar
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// Descripción de fondo sólido
  ///
  /// In es, this message translates to:
  /// **'Fondo sólido'**
  String get solidBackground;

  /// Descripción de efecto cristal
  ///
  /// In es, this message translates to:
  /// **'Efecto cristal'**
  String get glassEffect;

  /// Texto de carga
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// Título para gestionar movimientos recurrentes
  ///
  /// In es, this message translates to:
  /// **'Gestionar Movimientos Recurrentes'**
  String get manageRecurringMovements;

  /// Mensaje cuando no hay movimientos
  ///
  /// In es, this message translates to:
  /// **'No hay movimientos para mostrar.'**
  String get noMovementsToShow;

  /// Etiqueta para total
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// Etiqueta para ingresos
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get incomes;

  /// Etiqueta para gastos
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get expenses;

  /// Título del balance del mes
  ///
  /// In es, this message translates to:
  /// **'Balance del mes'**
  String get monthBalance;

  /// Título de gastos por categoría
  ///
  /// In es, this message translates to:
  /// **'Gastos por Categoría'**
  String get expensesByCategory;

  /// Error al generar etiquetas automáticamente
  ///
  /// In es, this message translates to:
  /// **'No se pudieron generar etiquetas para los movimientos. Intente de nuevo más tarde o revise la API key proporcionada en ajustes.'**
  String get noTagsGenerated;

  /// Tooltip para ordenar
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// Ordenar por fecha
  ///
  /// In es, this message translates to:
  /// **'Por fecha'**
  String get byDate;

  /// Ordenar alfabéticamente
  ///
  /// In es, this message translates to:
  /// **'Alfabético'**
  String get alphabetical;

  /// Ordenar por valor
  ///
  /// In es, this message translates to:
  /// **'Por valor'**
  String get byValue;

  /// Limpiar ordenamiento
  ///
  /// In es, this message translates to:
  /// **'Limpiar orden'**
  String get clearSort;

  /// Tooltip para generar etiquetas
  ///
  /// In es, this message translates to:
  /// **'Generar etiquetas automáticamente'**
  String get generateTagsAutomatically;

  /// Texto para movimientos filtrados
  ///
  /// In es, this message translates to:
  /// **'Movimientos filtrados:'**
  String get filteredMovements;

  /// Texto para total de movimientos
  ///
  /// In es, this message translates to:
  /// **'Total de movimientos:'**
  String get totalMovements;

  /// Mensaje cuando no hay gastos
  ///
  /// In es, this message translates to:
  /// **'No hay gastos.'**
  String get noExpenses;

  /// Mensaje cuando no hay ingresos
  ///
  /// In es, this message translates to:
  /// **'No hay ingresos.'**
  String get noIncomes;

  /// Validación de monto mayor que cero
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un monto válido mayor que 0'**
  String get pleaseEnterValidAmountGreaterThanZero;

  /// Error al generar categoría
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar la categoría, se guardará con categoría vacía. Puedes asignarla manualmente más tarde.'**
  String get categoryNotGenerated;

  /// Error general al generar categoría
  ///
  /// In es, this message translates to:
  /// **'Error al generar categoría. Se guardará sin categoría.'**
  String get errorGeneratingCategory;

  /// Movimiento actualizado exitosamente
  ///
  /// In es, this message translates to:
  /// **'Movimiento actualizado con éxito'**
  String get movementUpdatedSuccessfully;

  /// Movimiento guardado exitosamente
  ///
  /// In es, this message translates to:
  /// **'Movimiento guardado con éxito'**
  String get movementSavedSuccessfully;

  /// Error desconocido
  ///
  /// In es, this message translates to:
  /// **'Error desconocido'**
  String get unknownError;

  /// Error general
  ///
  /// In es, this message translates to:
  /// **'Error general'**
  String get generalError;

  /// Error de base de datos
  ///
  /// In es, this message translates to:
  /// **'Error de base de datos'**
  String get databaseError;

  /// Mensaje de error de base de datos
  ///
  /// In es, this message translates to:
  /// **'No se pudo acceder a la base de datos. Verifica que tengas espacio suficiente en el dispositivo.'**
  String get databaseErrorMessage;

  /// Error de formato
  ///
  /// In es, this message translates to:
  /// **'Error de formato'**
  String get formatError;

  /// Mensaje de error de formato
  ///
  /// In es, this message translates to:
  /// **'El formato del monto no es válido. Usa números con punto o coma como decimal.'**
  String get formatErrorMessage;

  /// Error de conexión
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get connectionError;

  /// Mensaje de error de conexión
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. El movimiento se guardará sin categoría automática.'**
  String get connectionErrorMessage;

  /// Error de permisos
  ///
  /// In es, this message translates to:
  /// **'Error de permisos'**
  String get permissionError;

  /// Mensaje de error de permisos
  ///
  /// In es, this message translates to:
  /// **'La aplicación no tiene permisos para guardar datos. Verifica los permisos de la app.'**
  String get permissionErrorMessage;

  /// Título de error
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// Error cuando no hay datos para importar
  ///
  /// In es, this message translates to:
  /// **'No hay datos para importar'**
  String get noDataToImport;

  /// Título de diálogo de importación
  ///
  /// In es, this message translates to:
  /// **'Importando datos...'**
  String get importingData;

  /// Texto de guardando movimientos
  ///
  /// In es, this message translates to:
  /// **'Guardando {count} movimientos'**
  String savingMovements(int count);

  /// Botón Ok
  ///
  /// In es, this message translates to:
  /// **'Ok'**
  String get ok;

  /// Mensaje de éxito al importar
  ///
  /// In es, this message translates to:
  /// **'Los datos se han importado correctamente'**
  String get dataImportedSuccessfully;

  /// Error al guardar datos
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al guardar los datos'**
  String get errorSavingData;

  /// Error de inicialización de base de datos
  ///
  /// In es, this message translates to:
  /// **'Error al inicializar la base de datos. Por favor, intenta de nuevo.'**
  String get databaseInitializationError;

  /// Error de formato de datos
  ///
  /// In es, this message translates to:
  /// **'Error al guardar los datos. Verifica que el formato del archivo sea correcto.'**
  String get dataFormatError;

  /// Título de error de importación
  ///
  /// In es, this message translates to:
  /// **'Error al importar'**
  String get importError;

  /// Opción de continuar sin importar
  ///
  /// In es, this message translates to:
  /// **'Continuar sin importar'**
  String get continueWithoutImporting;

  /// Opción de intentar de nuevo
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get tryAgain;

  /// Moneda Euro
  ///
  /// In es, this message translates to:
  /// **'Euro (€)'**
  String get euroSymbol;

  /// Moneda Dólar
  ///
  /// In es, this message translates to:
  /// **'Dólar Estadounidense (\$)'**
  String get dollarSymbol;

  /// Moneda Libra
  ///
  /// In es, this message translates to:
  /// **'Libra Esterlina (£)'**
  String get poundSymbol;

  /// Moneda Yen
  ///
  /// In es, this message translates to:
  /// **'Yen Japonés (¥)'**
  String get yenSymbol;

  /// Moneda Franco Suizo
  ///
  /// In es, this message translates to:
  /// **'Franco Suizo (CHF)'**
  String get swissFrancSymbol;

  /// Moneda Peso Colombiano
  ///
  /// In es, this message translates to:
  /// **'Peso Colombiano (COP)'**
  String get colombianPesoSymbol;

  /// Tipo de imagen PNG
  ///
  /// In es, this message translates to:
  /// **'PNG'**
  String get png;

  /// Tipo de imagen SVG
  ///
  /// In es, this message translates to:
  /// **'SVG'**
  String get svg;

  /// Título de movimientos fijos
  ///
  /// In es, this message translates to:
  /// **'Movimientos Fijos'**
  String get fixedMovements;

  /// Título de movimientos automáticos
  ///
  /// In es, this message translates to:
  /// **'Movimientos Automáticos'**
  String get automaticMovements;

  /// Descripción de movimientos automáticos
  ///
  /// In es, this message translates to:
  /// **'Se añaden automáticamente cada mes nuevo.'**
  String get addedAutomaticallyEachMonth;

  /// Título cuando no hay movimientos fijos
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos fijos'**
  String get noFixedMovements;

  /// Descripción para crear movimientos recurrentes
  ///
  /// In es, this message translates to:
  /// **'Crea movimientos que se repitan automáticamente cada mes, como salarios, alquileres o suscripciones.'**
  String get createRecurringMovements;

  /// Botón para crear primer movimiento
  ///
  /// In es, this message translates to:
  /// **'Crear primer movimiento.'**
  String get createFirstMovement;

  /// Texto del día de cada mes
  ///
  /// In es, this message translates to:
  /// **'Día {day} de cada mes'**
  String dayOfEachMonth(int day);

  /// Mensaje de movimiento eliminado
  ///
  /// In es, this message translates to:
  /// **'Movimiento \"{description}\" eliminado.'**
  String movementDeleted(String description);

  /// Error al cargar movimientos
  ///
  /// In es, this message translates to:
  /// **'Error al cargar movimientos: {error}'**
  String errorLoadingMovements(String error);

  /// Error al crear movimiento
  ///
  /// In es, this message translates to:
  /// **'Error al crear movimiento: {error}'**
  String errorCreatingMovement(String error);

  /// Error al eliminar movimiento
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar movimiento: {error}'**
  String errorDeletingMovement(String error);

  /// Error al actualizar movimiento
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar movimiento: {error}'**
  String errorUpdatingMovement(String error);

  /// Título de nuevo movimiento fijo
  ///
  /// In es, this message translates to:
  /// **'Nuevo Movimiento Fijo'**
  String get newFixedMovement;

  /// Título de editar movimiento
  ///
  /// In es, this message translates to:
  /// **'Editar Movimiento'**
  String get editMovement;

  /// Validación de descripción requerida
  ///
  /// In es, this message translates to:
  /// **'La descripción es obligatoria'**
  String get descriptionRequired;

  /// Validación de cantidad requerida
  ///
  /// In es, this message translates to:
  /// **'La cantidad es obligatoria.'**
  String get amountRequired;

  /// Validación de número válido
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido.'**
  String get enterValidNumber;

  /// Validación de cantidad mayor que cero
  ///
  /// In es, this message translates to:
  /// **'La cantidad debe ser mayor que 0.'**
  String get amountMustBeGreaterThanZero;

  /// Etiqueta de cantidad
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// Etiqueta del día del mes
  ///
  /// In es, this message translates to:
  /// **'Día del mes'**
  String get dayOfMonth;

  /// Placeholder para días del mes
  ///
  /// In es, this message translates to:
  /// **'Del 1 al 31'**
  String get from1To31;

  /// Validación de día requerido
  ///
  /// In es, this message translates to:
  /// **'El día es obligatorio'**
  String get dayRequired;

  /// Validación de día válido
  ///
  /// In es, this message translates to:
  /// **'El día debe estar entre 1 y 31.'**
  String get dayMustBeBetween1And31;

  /// Etiqueta de tipo de movimiento
  ///
  /// In es, this message translates to:
  /// **'Tipo de movimiento'**
  String get movementType;

  /// Etiqueta para guardar en mes actual
  ///
  /// In es, this message translates to:
  /// **'Guardar gasto en mes actual: '**
  String get saveInCurrentMonth;

  /// Botón crear
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// Error en los datos
  ///
  /// In es, this message translates to:
  /// **'Error en los datos: {error}'**
  String errorInData(String error);

  /// Placeholder para descripción de movimientos fijos
  ///
  /// In es, this message translates to:
  /// **'Ej: Salario, Alquiler, Netflix...'**
  String get exampleSalaryRentNetflix;

  /// Saludo de buenos días
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get goodMorning;

  /// Saludo de buenas tardes
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get goodAfternoon;

  /// Saludo de buenas noches
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get goodEvening;

  /// Mensaje de buenos días
  ///
  /// In es, this message translates to:
  /// **'Comienza el día con energía renovada.'**
  String get startDayWithEnergy;

  /// Mensaje de buenas tardes
  ///
  /// In es, this message translates to:
  /// **'Sigue construyendo tu futuro financiero.'**
  String get keepBuildingFinancialFuture;

  /// Mensaje de buenas noches
  ///
  /// In es, this message translates to:
  /// **'Momento perfecto para revisar tus finanzas.'**
  String get perfectTimeToReviewFinances;

  /// Título de filtros
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get filters;

  /// Título de últimos movimientos
  ///
  /// In es, this message translates to:
  /// **'Últimos movimientos'**
  String get lastMovements;

  /// Texto para mostrar todos los elementos
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// Texto del campo de búsqueda
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// Texto para todas las categorías
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get allCategories;

  /// Validación de número válido
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un número válido.'**
  String get pleaseEnterValidNumber;

  /// Etiqueta de fecha en el botón
  ///
  /// In es, this message translates to:
  /// **'Fecha:'**
  String get dateLabel;

  /// Título del diálogo de confirmación de eliminación
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar movimiento?'**
  String get deleteMovement;

  /// Mensaje de confirmación de eliminación
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar \"{description}\"?'**
  String confirmDeleteMovement(String description);

  /// Título del diálogo de cambio de categoría
  ///
  /// In es, this message translates to:
  /// **'Cambiar categoría'**
  String get changeCategory;

  /// Título del selector de categorías
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get selectCategory;

  /// Mensaje de éxito al actualizar categoría
  ///
  /// In es, this message translates to:
  /// **'Categoría actualizada: {category}.'**
  String categoryUpdated(String category);

  /// Mensaje de éxito al eliminar
  ///
  /// In es, this message translates to:
  /// **'eliminado con éxito'**
  String get eliminatedSuccessfully;

  /// Mensaje de error al eliminar
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar '**
  String get elimError;

  /// Mensaje de éxito al cambiar la moneda
  ///
  /// In es, this message translates to:
  /// **'Moneda actualizada correctamente'**
  String get currencyChangedSuccessfully;

  /// Mensaje de éxito al cambiar el logo
  ///
  /// In es, this message translates to:
  /// **'Logo actualizado correctamente'**
  String get logoChangedSuccessfully;

  /// Mensaje de éxito al cambiar el color del avatar
  ///
  /// In es, this message translates to:
  /// **'Color de avatar actualizado correctamente'**
  String get avatarColorChangedSuccessfully;

  /// Mensaje de navegación inferior transparente aplicada
  ///
  /// In es, this message translates to:
  /// **'Navegación inferior transparente aplicada'**
  String get transparentBottomNavApplied;

  /// Mensaje de navegación inferior opaca aplicada
  ///
  /// In es, this message translates to:
  /// **'Navegación inferior opaca aplicada'**
  String get opaqueBottomNavApplied;

  /// Mensaje de éxito al cambiar el idioma
  ///
  /// In es, this message translates to:
  /// **'Idioma actualizado correctamente'**
  String get languageChangedSuccessfully;

  /// Mensaje de error al intentar abrir un enlace
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir el enlace'**
  String get cantOpenUrl;

  /// Mensaje de error cuando el API Key está vacío
  ///
  /// In es, this message translates to:
  /// **'❌ El API Key no puede estar vacío'**
  String get apiKeyCantBeEmpty;

  /// Mensaje de éxito al guardar el API Key
  ///
  /// In es, this message translates to:
  /// **'✅ API Key guardada correctamente'**
  String get apiKeySavedSuccessfully;

  /// Mensaje de éxito al guardar el API Key
  ///
  /// In es, this message translates to:
  /// **'API Key guardada'**
  String get apiKeySaved;

  /// Mensaje importante sobre reinicio de la aplicación
  ///
  /// In es, this message translates to:
  /// **'IMPORTANTE: Para que la IA funcione correctamente, debes reiniciar completamente la aplicación.'**
  String get importantRestart;

  /// Consejo sobre reinicio de la aplicación
  ///
  /// In es, this message translates to:
  /// **'💡 Cierra la app completamente y vuelve a abrirla.'**
  String get appRestartAdvice;

  /// Instrucciones para activar funciones de IA
  ///
  /// In es, this message translates to:
  /// **'Para activar las funciones de inteligencia artificial, necesitas obtener una clave API de Google. Te guiamos paso a paso:'**
  String get aiFeaturesActivation;

  /// Primer paso para activar funciones de IA
  ///
  /// In es, this message translates to:
  /// **'1. Accede a Google AI Studio e inicia sesión con tu cuenta'**
  String get step1;

  /// Segundo paso para activar funciones de IA
  ///
  /// In es, this message translates to:
  /// **'2. Haz clic en \"Crear clave de API\" y copia la clave generada'**
  String get step2;

  /// Instrucciones para cerrar la ventana emergente
  ///
  /// In es, this message translates to:
  /// **'2.1. Si aparece esta ventana emergente, ciérrala con la X'**
  String get step2_1;

  /// Instrucciones para encontrar la tabla de claves
  ///
  /// In es, this message translates to:
  /// **'2.2. Desplázate hacia abajo hasta encontrar la tabla de claves'**
  String get step2_2;

  /// Instrucciones para acceder a la clave
  ///
  /// In es, this message translates to:
  /// **'2.3. Haz clic en el enlace azul para acceder a la clave'**
  String get step2_3;

  /// Tercer paso para activar funciones de IA
  ///
  /// In es, this message translates to:
  /// **'3. Pega la clave API en el campo de texto de la aplicación'**
  String get step3;

  /// Cuarto paso para activar funciones de IA
  ///
  /// In es, this message translates to:
  /// **'4. Presiona el botón guardar para completar la configuración'**
  String get step4;

  /// Enlace para ir a Google AI Studio
  ///
  /// In es, this message translates to:
  /// **'Ir a Google AI Studio'**
  String get goToGoogleAiStudio;

  /// Etiqueta para la clave API de Google
  ///
  /// In es, this message translates to:
  /// **'Clave API de Google'**
  String get googleApiKey;

  /// Etiqueta para borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'Borrar base de datos'**
  String get deleteDatabase;

  /// Advertencia al borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'ATENCIÓN: Esta acción eliminará TODOS los datos de la aplicación:'**
  String get dbDeleteWarning;

  /// Lista de datos que se eliminarán al borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'• Todos los movimientos registrados'**
  String get dbDeleteList1;

  /// Lista de datos que se eliminarán al borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'• Todas las categorías personalizadas'**
  String get dbDeleteList2;

  /// Lista de datos que se eliminarán al borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'• Todos los movimientos fijos'**
  String get dbDeleteList3;

  /// Lista de datos que se eliminarán al borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'• Configuración de colores y preferencias'**
  String get dbDeleteList4;

  /// Mensaje de que la acción de borrar la base de datos no se puede deshacer
  ///
  /// In es, this message translates to:
  /// **'Esta acción NO se puede deshacer.'**
  String get dbDeleteUnrecoverable;

  /// Recomendación de hacer un backup antes de borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'💡 Recomendación: Haz un backup antes de continuar.'**
  String get dbDeleteRecomendation;

  /// Botón para eliminar todos los datos
  ///
  /// In es, this message translates to:
  /// **'Eliminar Todo'**
  String get deleteAll;

  /// Mensaje de éxito al limpiar la base de datos
  ///
  /// In es, this message translates to:
  /// **'✅ Base de datos limpiada correctamente'**
  String get dbDeletedSuccesfully;

  /// Mensaje de éxito al limpiar la base de datos
  ///
  /// In es, this message translates to:
  /// **'Base de datos limpiada'**
  String get dbDeleted;

  /// Subtítulo de éxito al limpiar la base de datos
  ///
  /// In es, this message translates to:
  /// **'Todos los datos se han eliminado correctamente.'**
  String get deDeletedSubtitle;

  /// Mensaje importante sobre reinicio de la aplicación tras borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'IMPORTANTE: Para que los cambios se apliquen completamente, es recomendable reiniciar la aplicación.'**
  String get dbDeleteAppRestart;

  /// Consejo sobre el reinicio de la aplicación tras borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'💡 Cierra la app completamente y vuelve a abrirla.'**
  String get dbDeleteAppRestartAdvice;

  /// Mensaje de error al limpiar la base de datos
  ///
  /// In es, this message translates to:
  /// **'❌ Error al limpiar la base de datos'**
  String get errorCleaningDatabase;

  /// Título de opciones de desarrollador
  ///
  /// In es, this message translates to:
  /// **'Opciones de Desarrollador'**
  String get developerOptions;

  /// Subtítulo de opciones de desarrollador
  ///
  /// In es, this message translates to:
  /// **'Acceso a funciones avanzadas y de desarrollo.'**
  String get developerOptionsSubtitle;

  /// Título para importar desde JSON
  ///
  /// In es, this message translates to:
  /// **'Importar desde JSON'**
  String get importFromJson;

  /// Subtítulo para importar desde JSON
  ///
  /// In es, this message translates to:
  /// **'Importa datos desde un archivo JSON de Gastoscopio.'**
  String get importFromJsonSubtitle;

  /// Subtítulo para borrar la base de datos
  ///
  /// In es, this message translates to:
  /// **'⚠️ PELIGRO: Borra TODOS los datos de la aplicación de forma permanente. Esta acción no se puede deshacer.'**
  String get deleteDatabaseSubtitle;

  /// Texto mostrado mientras se limpia la base de datos
  ///
  /// In es, this message translates to:
  /// **'Limpiando...'**
  String get cleaning;

  /// Botón para limpiar todos los datos
  ///
  /// In es, this message translates to:
  /// **'Limpiar Todos los Datos'**
  String get cleanAllData;

  /// Mensaje de error al guardar la API Key
  ///
  /// In es, this message translates to:
  /// **'No se ha podido guardar la API Key'**
  String get errorSavingApiKey;

  /// Título del diálogo para configurar la API Key
  ///
  /// In es, this message translates to:
  /// **'Configurar API Key'**
  String get configureApiKey;

  /// Mensaje que solicita al usuario ingresar su API Key
  ///
  /// In es, this message translates to:
  /// **'Para utilizar las funciones de IA, por favor ingrese su API Key:'**
  String get enterApiKeyMessage;

  /// Botón para posponer una acción
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get later;

  /// Botón para proceder con una acción
  ///
  /// In es, this message translates to:
  /// **'Vamos allá'**
  String get letsGo;

  /// Mensaje cuando la IA no puede generar una respuesta
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar una respuesta'**
  String get noResponseGenerated;

  /// Mensaje de error cuando la API Key no está configurada
  ///
  /// In es, this message translates to:
  /// **'API Key no configurada'**
  String get apiKeyNotConfigured;

  /// Mensaje de error cuando no se ha seleccionado un mes
  ///
  /// In es, this message translates to:
  /// **'Mes no seleccionado'**
  String get noMonthSelected;

  /// Título del diálogo para crear un nuevo mes
  ///
  /// In es, this message translates to:
  /// **'Crear nuevo mes'**
  String get createNewMonth;

  /// No description provided for @monthDoesNotExist.
  ///
  /// In es, this message translates to:
  /// **'El mes {month} de {year} no existe. ¿Deseas crearlo?'**
  String monthDoesNotExist(String month, String year);

  /// Botón Sí
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// Botón No
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// Mes de enero
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get january;

  /// Mes de febrero
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get february;

  /// Mes de marzo
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get march;

  /// Mes de abril
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get april;

  /// Mes de mayo
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get may;

  /// Mes de junio
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get june;

  /// Mes de julio
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get july;

  /// Mes de agosto
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get august;

  /// Mes de septiembre
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get september;

  /// Mes de octubre
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get october;

  /// Mes de noviembre
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get november;

  /// Mes de diciembre
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get december;

  /// Etiqueta para nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// Mensaje de error cuando el nombre es requerido
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get nameRequired;

  /// Mensaje de error cuando el monto es inválido
  ///
  /// In es, this message translates to:
  /// **'Monto inválido'**
  String get invalidAmount;

  /// Mensaje cuando se requiere iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión requerido'**
  String get loginRequired;

  /// Mensaje explicativo de por qué se necesita iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para acceder a esta función'**
  String get loginToAccess;

  /// Botón de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// Botón de cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// Mensaje de éxito al cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Sesión cerrada correctamente'**
  String get loggedOutSuccessfully;

  /// Mensaje de éxito al iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada correctamente'**
  String get loggedInSuccessfully;

  /// Mensaje de error al iniciar sesión
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get loginError;

  /// Título de la sección de cuenta en ajustes
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get accountSection;

  /// Descripción de la sección de cuenta
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu cuenta y las opciones de inicio de sesión'**
  String get accountDescription;

  /// Título de movimientos futuros
  ///
  /// In es, this message translates to:
  /// **'Movimientos futuros'**
  String get futureMovements;

  /// Título para la pantalla de inicio cuando las funciones de IA no están activadas
  ///
  /// In es, this message translates to:
  /// **'¡Estás perdiendo acceso a las funciones inteligentes de la app!\n\nActiva la IA para obtener análisis automáticos, sugerencias personalizadas y mucho más. Es gratuito y muy facil de configurar.'**
  String get noIaFeaturesHomeTitle;

  /// Subtítulo para la pantalla de inicio cuando las funciones de IA no están activadas
  ///
  /// In es, this message translates to:
  /// **'Para activar las funciones IA, ve a Ajustes > Sección IA y sigue los pasos para introducir tu API Key.'**
  String get noIaFeaturesHomeSubtitle;

  /// Botón para activar las funciones de IA
  ///
  /// In es, this message translates to:
  /// **'¡Activa las funciones IA!'**
  String get activateIaFeatures;

  /// Texto para las funciones de IA
  ///
  /// In es, this message translates to:
  /// **'Funciones de IA'**
  String get iaFeaturesText;

  /// Sección de seguridad de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get security;

  /// Descripción de la sección de seguridad
  ///
  /// In es, this message translates to:
  /// **'Configura las funciones de seguridad de acceso a la app.'**
  String get securityDescription;

  /// Opción para activar el bloqueo de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Activar bloqueo de la app'**
  String get useAppLock;

  /// Descripción de la opción de bloqueo de la app
  ///
  /// In es, this message translates to:
  /// **'Requiere autenticación para acceder a la app.'**
  String get useAppLockDescription;

  /// Opción para usar huella o reconocimiento facial
  ///
  /// In es, this message translates to:
  /// **'Usar biometría'**
  String get useBiometrics;

  /// Descripción de la opción de biometría
  ///
  /// In es, this message translates to:
  /// **'Utiliza huella digital o reconocimiento facial para desbloquear.'**
  String get useBiometricsDescription;

  /// Etiqueta para PIN
  ///
  /// In es, this message translates to:
  /// **'PIN'**
  String get pin;

  /// Mensaje para introducir el PIN
  ///
  /// In es, this message translates to:
  /// **'Introduce el PIN'**
  String get enterPin;

  /// Mensaje para introducir el PIN al acceder
  ///
  /// In es, this message translates to:
  /// **'Introduce el PIN para acceder a la app'**
  String get enterPinToAccess;

  /// Mensaje para configurar el PIN
  ///
  /// In es, this message translates to:
  /// **'Introduce un PIN de 4 dígitos para proteger tu app'**
  String get enterPinSetup;

  /// Botón para configurar el PIN
  ///
  /// In es, this message translates to:
  /// **'Configurar PIN'**
  String get setupPin;

  /// Botón para cambiar el PIN
  ///
  /// In es, this message translates to:
  /// **'Cambiar PIN'**
  String get changePin;

  /// Descripción para cambiar el PIN
  ///
  /// In es, this message translates to:
  /// **'Cambia tu código PIN de seguridad'**
  String get changePinDescription;

  /// Mensaje de error para PIN inválido
  ///
  /// In es, this message translates to:
  /// **'Código PIN inválido'**
  String get invalidPin;

  /// Mensaje de éxito al configurar el PIN
  ///
  /// In es, this message translates to:
  /// **'PIN configurado correctamente'**
  String get pinSetupSuccess;

  /// Botón para verificar
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get verify;

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Cashly'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu compañero de finanzas personales'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finish;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Controla tus Finanzas'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Desc.
  ///
  /// In es, this message translates to:
  /// **'Mantén un registro de tus ingresos y gastos fácilmente'**
  String get onboardingStep1Desc;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In es, this message translates to:
  /// **'Análisis Inteligente'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Desc.
  ///
  /// In es, this message translates to:
  /// **'Obtén información sobre tus hábitos de gasto con ayuda de IA'**
  String get onboardingStep2Desc;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Seguro y Privado'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Desc.
  ///
  /// In es, this message translates to:
  /// **'Tus datos permanecen en tu dispositivo, protegidos y privados'**
  String get onboardingStep3Desc;

  /// No description provided for @termsAndConditions.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones'**
  String get termsAndConditions;

  /// No description provided for @agreeToTerms.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos y Condiciones'**
  String get agreeToTerms;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In es, this message translates to:
  /// **'Por favor acepta los Términos y Condiciones para continuar'**
  String get pleaseAgreeToTerms;

  /// No description provided for @configureGeminiApiKey.
  ///
  /// In es, this message translates to:
  /// **'Configura tu API Key de Gemini'**
  String get configureGeminiApiKey;

  /// No description provided for @apiKeyRequired.
  ///
  /// In es, this message translates to:
  /// **'La API Key es necesaria para utilizar las funciones de IA.\nEs gratis y fácil de obtener.'**
  String get apiKeyRequired;

  /// No description provided for @continueAction.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// No description provided for @welcomeToApp.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Gastoscopio'**
  String get welcomeToApp;

  /// No description provided for @connectGoogleAccount.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu cuenta de Google para sincronizar y respaldar tus datos financieros'**
  String get connectGoogleAccount;

  /// No description provided for @noAccountConnected.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta conectada'**
  String get noAccountConnected;

  /// No description provided for @loginForBackupSync.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con Google para acceder a funciones de respaldo y sincronización'**
  String get loginForBackupSync;

  /// No description provided for @correctlyConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado correctamente'**
  String get correctlyConnected;

  /// No description provided for @user.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get user;

  /// No description provided for @signInWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Google'**
  String get signInWithGoogle;

  /// No description provided for @optionalLogin.
  ///
  /// In es, this message translates to:
  /// **'Opcional: Puedes continuar sin cuenta, pero no tendrás acceso a funciones de respaldo.'**
  String get optionalLogin;

  /// No description provided for @continueWithoutLogin.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin iniciar sesión'**
  String get continueWithoutLogin;

  /// No description provided for @continueToNextStep.
  ///
  /// In es, this message translates to:
  /// **'Continuar al siguiente paso'**
  String get continueToNextStep;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @signingIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión...'**
  String get signingIn;

  /// No description provided for @signingOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrando sesión...'**
  String get signingOut;

  /// No description provided for @authenticateToAccess.
  ///
  /// In es, this message translates to:
  /// **'Por favor, autentícate para acceder a la aplicación'**
  String get authenticateToAccess;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In es, this message translates to:
  /// **'Autenticación biométrica fallida'**
  String get biometricAuthFailed;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @notificationsHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de Notificaciones'**
  String get notificationsHistory;

  /// No description provided for @enableNotifications.
  ///
  /// In es, this message translates to:
  /// **'Activar Notificaciones'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In es, this message translates to:
  /// **'Desactivar Notificaciones'**
  String get disableNotifications;

  /// No description provided for @notificationsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones Desactivadas'**
  String get notificationsDisabled;

  /// No description provided for @notificationsEnabled.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones Activadas'**
  String get notificationsEnabled;

  /// No description provided for @goToSettings.
  ///
  /// In es, this message translates to:
  /// **'Ir a Ajustes'**
  String get goToSettings;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Se requiere permiso de notificaciones'**
  String get notificationPermissionRequired;

  /// No description provided for @disableNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Desactivar Notificaciones'**
  String get disableNotificationsTitle;

  /// No description provided for @disableNotificationsMessage.
  ///
  /// In es, this message translates to:
  /// **'Para desactivar completamente las notificaciones, necesitas revocar el permiso en los ajustes del dispositivo. ¿Quieres abrir los ajustes ahora?'**
  String get disableNotificationsMessage;

  /// No description provided for @noNotificationsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notificaciones'**
  String get noNotificationsYet;

  /// No description provided for @movementAdded.
  ///
  /// In es, this message translates to:
  /// **'Movimiento añadido correctamente'**
  String get movementAdded;

  /// No description provided for @noActiveMonth.
  ///
  /// In es, this message translates to:
  /// **'No hay un mes activo'**
  String get noActiveMonth;

  /// No description provided for @addMovement.
  ///
  /// In es, this message translates to:
  /// **'Añadir movimiento'**
  String get addMovement;

  /// No description provided for @isExpense.
  ///
  /// In es, this message translates to:
  /// **'Es un gasto'**
  String get isExpense;

  /// No description provided for @notificationSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Notificaciones'**
  String get notificationSettings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
