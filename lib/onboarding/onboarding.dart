import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/json_import_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/screens/apikey_setup.dart';
import 'package:cashly/onboarding/screens/first_startup.dart';
import 'package:cashly/onboarding/screens/import_from_gastoscopio.dart';
import 'package:cashly/onboarding/screens/login.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _statusMessage = '';

  List<Widget> _pages = [];

  void _handleNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  Future<void> _onTermsAccepted() async {
    // Primero guardar el valor y esperar a que termine
    await SharedPreferencesService().setBoolValue(
      SharedPreferencesKeys.isFirstStartup,
      false,
    );

    setState(() {
      _pages = [
        ApiKeySetupScreen(onApiKeySet: _handleNext),
        GoogleLoginScreen(onLoginOk: _checkExistingBackup),
        ImportFromGastoscopioScreen(onImportSuccess: _handleImportSuccess),
      ];
    });
  }

  void _checkExistingBackup() async {
    String status = await LoginService().checkExistingBackup();
    setState(() {
      _statusMessage = status;
    });
    _handleNext();
  }

  void _handleImportSuccess(Map<String, dynamic>? result) async {
    if (result == null) {
      await SqliteService().initializeDatabase();
      _navigateToMainScreen();
      return;
    }
    try {
      // Si hay datos para importar, los guardamos
      _importResult = result;

      // Inicializar la base de datos primero
      await SqliteService().initializeDatabase(forceRecreate: true);
      AppDatabase db = SqliteService().db;

      // Show progress dialog only after DB is initialized
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Importando datos...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Guardando ${result['Movements'].length} movimientos'),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Ok'),
                ),
              ],
            ),
          );
        },
      );

      // Import months first
      for (Month month in _importResult!['Months']) {
        await db.monthDao.insertMonth(month);
      }

      // Then import movements
      for (MovementValue movement in _importResult!['Movements']) {
        await db.movementValueDao.insertMovementValue(movement);
      }

      // Finally, import fixed movements if they exist
      if (_importResult!.containsKey('FixedMovements')) {
        for (FixedMovement fixedMovement in _importResult!['FixedMovements']) {
          await db.fixedMovementDao.insertFixedMovement(fixedMovement);
        }
      }

      // Upload to backup
      await LoginService().uploadDatabase();

      // Pop the progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los datos se han importado correctamente'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      _navigateToMainScreen();
    } catch (e) {
      if (!mounted) return;

      // Pop the progress dialog only if we're showing it
      try {
        Navigator.pop(context);
      } catch (popError) {
        // Ignore pop errors
      }

      // Show error dialog with more specific messages
      String errorMessage = 'Ocurrió un error al guardar los datos';
      if (e.toString().contains('database')) {
        errorMessage =
            'Error al inicializar la base de datos. Por favor, intenta de nuevo.';
      } else if (e.toString().contains('insert')) {
        errorMessage =
            'Error al guardar los datos. Verifica que el formato del archivo sea correcto.';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error al importar'),
            content: Text('$errorMessage\n\nDetalles: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToMainScreen();
                },
                child: Text('Continuar sin importar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Intentar de nuevo'),
              ),
            ],
          );
        },
      );
    }
  }

  void _navigateToMainScreen() {
    // Usamos push normal

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Map<String, dynamic>?
  _importResult; // Add this field to store the import result

  @override
  void initState() {
    _pages = [FirstStartupScreen(onTermsAccepted: _onTermsAccepted)];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: _pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color:
                        _statusMessage.isEmpty
                            ? Colors.transparent
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
