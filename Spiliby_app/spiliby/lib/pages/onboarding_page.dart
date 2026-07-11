import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final name = TextEditingController();
  final btId = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    btId.dispose();
    super.dispose();
  }

  bool get canSave => name.text.trim().isNotEmpty && btId.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.account_balance_wallet_rounded, size: 28, color: c.onAccent),
                  ),
                  Text('Welcome to Spiliby',
                      style: AppFonts.display(size: 30, weight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Split bills with your hostel mates in seconds. No login, no password, no internet, no fuss — just tell us who you are.',
                    style: AppFonts.body(size: 13, color: c.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(controller: name, hint: 'Your name', autofocus: true, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: btId,
                    hint: 'BT ID (e.g. BT25CSE032)',
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Get started',
                    onPressed: canSave
                        ? () => context
                            .read<AppStore>()
                            .createProfile(name: name.text.trim(), btId: btId.text.trim().toUpperCase())
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Everything stays on this device. Always.',
                      textAlign: TextAlign.center, style: AppFonts.body(size: 12, color: c.textMuted)),
                  const SizedBox(height: 4),
                  Text('Free to use · no accounts · protected as a proprietary app.',
                      textAlign: TextAlign.center, style: AppFonts.body(size: 11, color: c.textMutedLight)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}