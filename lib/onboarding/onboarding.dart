import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/screens/first_startup.dart';
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
        // ApiKeySetupScreen(onApiKeySet: _handleNext),
        GoogleLoginScreen(onLoginOk: _checkExistingBackup),
      ];
    });
  }

  void _checkExistingBackup() async {
    String status = await LoginService().checkExistingBackup();
    setState(() {
      _statusMessage = status;
    });

    _navigateToMainScreen();
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
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: _pages,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
