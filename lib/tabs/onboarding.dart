import 'package:flutter/material.dart';

import '../l10n.dart';
import '../widgets/mascot.dart';

class OnboardingScreen extends StatefulWidget {
  final AppSettings settings;
  const OnboardingScreen({super.key, required this.settings});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  LangMode _selection = LangMode.bilingual;

  // Bilingual preview strings so a user can see the effect before choosing.
  static const _previewEn = 'Good morning — how can we help today?';
  static const _previewEs = 'Buenos días — ¿cómo podemos ayudarle hoy?';

  @override
  void initState() {
    super.initState();
    _selection = widget.settings.onboarded ? widget.settings.mode : LangMode.bilingual;
  }

  void _continue() {
    widget.settings.setMode(_selection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7ED), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Mascot(size: 120, mood: MascotMood.wave),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Somos 956',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const _PickTitle(),
                    const SizedBox(height: 4),
                    const _PickSubtitle(),
                    const SizedBox(height: 22),
                    _option(
                      theme,
                      mode: LangMode.english,
                      title: 'English',
                      subtitle: 'Show everything in English',
                      samplePrimary: _previewEn,
                      sampleSecondary: null,
                    ),
                    const SizedBox(height: 12),
                    _option(
                      theme,
                      mode: LangMode.spanish,
                      title: 'Español',
                      subtitle: 'Todo en español',
                      samplePrimary: _previewEs,
                      sampleSecondary: null,
                    ),
                    const SizedBox(height: 12),
                    _option(
                      theme,
                      mode: LangMode.bilingual,
                      title: 'Bilingual · Bilingüe',
                      subtitle: 'English, with Spanish underneath',
                      samplePrimary: _previewEn,
                      sampleSecondary: _previewEs,
                      recommended: true,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        '${_continueLabel()}  →',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _continueLabel() => switch (_selection) {
        LangMode.english => 'Continue',
        LangMode.spanish => 'Continuar',
        LangMode.bilingual => 'Continue · Continuar',
      };

  Widget _option(
    ThemeData theme, {
    required LangMode mode,
    required String title,
    required String subtitle,
    required String samplePrimary,
    required String? sampleSecondary,
    bool recommended = false,
  }) {
    final selected = _selection == mode;
    final color = theme.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _selection = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? color : Colors.black38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (recommended && !selected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('★',
                        style: TextStyle(color: color, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(samplePrimary,
                      style: const TextStyle(fontSize: 13.5)),
                  if (sampleSecondary != null)
                    Text(
                      sampleSecondary,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickTitle extends StatelessWidget {
  const _PickTitle();

  @override
  Widget build(BuildContext context) {
    return const _BilingualLine(
      primary: 'Choose your language',
      secondary: 'Elija su idioma',
      primaryStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      secondaryStyle: TextStyle(fontSize: 13, color: Colors.black54),
      textAlign: TextAlign.center,
    );
  }
}

class _PickSubtitle extends StatelessWidget {
  const _PickSubtitle();

  @override
  Widget build(BuildContext context) {
    return const _BilingualLine(
      primary: 'You can change this any time in Settings.',
      secondary: 'Puede cambiarlo cuando quiera en Ajustes.',
      primaryStyle: TextStyle(fontSize: 12.5, color: Colors.black54),
      secondaryStyle: TextStyle(fontSize: 11, color: Colors.black38),
      textAlign: TextAlign.center,
    );
  }
}

class _BilingualLine extends StatelessWidget {
  final String primary;
  final String secondary;
  final TextStyle primaryStyle;
  final TextStyle secondaryStyle;
  final TextAlign textAlign;

  const _BilingualLine({
    required this.primary,
    required this.secondary,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(primary, textAlign: textAlign, style: primaryStyle),
        Text(secondary, textAlign: textAlign, style: secondaryStyle),
      ],
    );
  }
}
