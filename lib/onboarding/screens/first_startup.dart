import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashly/l10n/app_localizations.dart';

class FirstStartupScreen extends StatefulWidget {
  const FirstStartupScreen({Key? key, required this.onTermsAccepted})
    : super(key: key);

  final Future<void> Function() onTermsAccepted;

  @override
  State<FirstStartupScreen> createState() => _FirstStartupScreenState();
}

class _FirstStartupScreenState extends State<FirstStartupScreen> {
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _loadTermsFromAssets() async {
    try {
      final locale = AppLocalizations.of(context).localeName;
      final fileName =
          locale == 'es'
              ? 'terminos-y-condiciones.md'
              : 'terms-and-conditions-en.md';
      return await rootBundle.loadString('assets/$fileName');
    } catch (e) {
      return _fallbackTermsText;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).termsAndConditions,
          style: GoogleFonts.pacifico(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).welcome,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).welcomeSubtitle,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FutureBuilder<String>(
                  future: _loadTermsFromAssets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Markdown(
                      controller: _scrollController,
                      data: snapshot.data ?? _fallbackTermsText,
                      padding: const EdgeInsets.all(16),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 14, height: 1.5),
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        blockquote: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_hasScrolledToBottom)
              Text(
                AppLocalizations.of(context).pleaseAgreeToTerms,
                style: const TextStyle(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    exit(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                ElevatedButton(
                  onPressed:
                      _hasScrolledToBottom
                          ? () async {
                            await widget.onTermsAccepted();
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _hasScrolledToBottom ? Colors.green : Colors.grey,
                  ),
                  child: Text(AppLocalizations.of(context).accept),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

const String _fallbackTermsText = '''
# Terms and Conditions

This is a fallback text that appears if the main terms and conditions file cannot be loaded.

Please try restarting the app. If the problem persists, please contact support.
''';
