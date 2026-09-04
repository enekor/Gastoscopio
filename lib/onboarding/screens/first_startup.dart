import 'dart:io';

import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full Terms & Conditions (same documents published on the Play Store).
const String kTermsUrlEs =
    'https://github.com/enekor/Gastoscopio/blob/main/assets/terminos-y-condiciones.md';
const String kTermsUrlEn =
    'https://github.com/enekor/Gastoscopio/blob/main/assets/terms-and-conditions-en.md';

class FirstStartupScreen extends StatefulWidget {
  const FirstStartupScreen({Key? key, required this.onTermsAccepted})
    : super(key: key);

  final Future<void> Function() onTermsAccepted;

  @override
  State<FirstStartupScreen> createState() => _FirstStartupScreenState();
}

class _FirstStartupScreenState extends State<FirstStartupScreen> {
  bool _accepted = false;

  Future<void> _openFullTerms() async {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final uri = Uri.parse(isEs ? kTermsUrlEs : kTermsUrlEn);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              // Shield icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Icon(Icons.shield_outlined, color: scheme.primary, size: 30),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Términos y Condiciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, revisa y acepta nuestras condiciones de uso y política de privacidad antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: glass.mutedText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: glass.incomeColor),
                      const SizedBox(width: 8),
                      Text(
                        'Última actualización: Septiembre 2024',
                        style: TextStyle(color: scheme.onSurface, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _section(
                context,
                icon: Icons.receipt_long,
                iconColor: scheme.primary,
                title: '1. USO Y GESTIÓN DE GASTOS',
                body:
                    'La aplicación procesa transacciones monetarias mediante almacenamiento criptográfico en local. Las sincronizaciones en la nube son encriptadas punto a punto (E2EE), asegurando control absoluto sobre tus libros contables personales sin rastreo arbitrario.',
              ),
              const SizedBox(height: 12),
              _section(
                context,
                icon: Icons.lock_outline,
                iconColor: glass.incomeColor,
                title: '2. PRIVACIDAD DE DATOS FINANCIEROS',
                body:
                    'Garantizamos estrictamente no comercializar, ceder ni monetizar historiales crediticios o hábitos de compra con terceros. Los balances, importes y cuentas son anonimizados y protegidos bajo el estándar bancario AES-256.',
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _openFullTerms,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Leer términos completos'),
                ),
              ),
              const SizedBox(height: 8),
              _buildAcceptTile(context),
              const SizedBox(height: 20),
              PrimaryPillButton(
                label: 'Continuar y Aceptar',
                icon: Icons.arrow_forward,
                onPressed: _accepted
                    ? () async {
                        await widget.onTermsAccepted();
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => exit(0),
                  child: Text(
                    'Rechazar y salir',
                    style: TextStyle(color: glass.mutedText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(color: glass.mutedText, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      onTap: () => setState(() => _accepted = !_accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _accepted,
            onChanged: (v) => setState(() => _accepted = v ?? false),
            activeColor: scheme.primary,
            checkColor: scheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'He leído y acepto los Términos del Servicio',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('*', style: TextStyle(color: glass.expenseColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Establece los lineamientos operacionales y derechos de propiedad.',
                  style: TextStyle(color: glass.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
