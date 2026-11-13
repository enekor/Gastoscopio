import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key, required this.onLoginOk});

  final Function() onLoginOk;

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final LoginService _loginService = LoginService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    await _loginService.silentSignIn();
    if (mounted && _loginService.isSignedIn) setState(() {});
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _isError = false;
    });

    final status = await _loginService.signIn();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statusMessage = status.message;
      _isError = status.isError;
    });

    if (_loginService.isSignedIn) {
      widget.onLoginOk();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? Center(child: Loading(context))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 8),
                    _buildHero(context),
                    const SizedBox(height: 24),
                    _buildCloudCard(context),
                    const SizedBox(height: 20),
                    _buildDivider(context, 'O MÁXIMA PRIVACIDAD'),
                    const SizedBox(height: 20),
                    _buildOfflineCard(context),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isError ? glass.expenseColor : glass.mutedText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildFooterNote(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Text(
            'SIGN IN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: glass.glassBorder),
          ),
          child: Icon(Icons.person_outline, size: 20, color: glass.mutedText),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glass.glassBorder),
          ),
          child: Icon(Icons.query_stats, color: scheme.onSurface, size: 28),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: glass.incomeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: glass.incomeColor),
              const SizedBox(width: 8),
              Text(
                'TU DINERO BAJO CONTROL',
                style: TextStyle(
                  color: glass.incomeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gastoscopio',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conecta tu cuenta para respaldar tus finanzas o mantén el control de forma 100% privada y local.',
          textAlign: TextAlign.center,
          style: TextStyle(color: glass.mutedText, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCloudCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SINCRONIZACIÓN CLOUD',
                  style: TextStyle(
                    color: glass.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Google Drive Backup',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(glass.pillRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(glass.pillRadius),
              onTap: _handleGoogle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _feature(context, Icons.backup_outlined, 'Backup\nautomático'),
              _feature(context, Icons.devices_outlined, 'Multidispositivo'),
              _feature(context, Icons.restore, 'Restauración\ntotal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feature(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.mutedText, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context, String label) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Row(
      children: [
        Expanded(child: Divider(color: glass.glassBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: glass.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: glass.glassBorder)),
      ],
    );
  }

  Widget _buildOfflineCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      onTap: widget.onLoginOk,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: glass.incomeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shield_outlined, color: glass.incomeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Continuar en Modo Offline',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.circle, size: 8, color: glass.incomeColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sin registro ni servidores en la nube. Tus presupuestos y transacciones se almacenan de manera local y cifrada exclusivamente en este dispositivo.',
                  style: TextStyle(
                    color: glass.mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '100% Funcional sin Internet • Sin backup',
                  style: TextStyle(
                    color: glass.incomeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: glass.mutedText, size: 20),
        ],
      ),
    );
  }

  Widget _buildFooterNote(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: glass.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Podrás vincular Google Drive cuando quieras desde Ajustes.',
              style: TextStyle(color: glass.mutedText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
