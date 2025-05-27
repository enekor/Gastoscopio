import 'package:cashly/data/services/login_service.dart';
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

  void _checkExistingBackup() async {
    String status = await LoginService().checkExistingBackup();
    setState(() {
      _statusMessage = status;
    });
    _handleNext();
  }

  @override
  void initState() {
    _pages = [
      FirstStartupScreen(onTermsAccepted: _handleNext),
      GoogleLoginScreen(onLoginOk: _checkExistingBackup),
    ];

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
