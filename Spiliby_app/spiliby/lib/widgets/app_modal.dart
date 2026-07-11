import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';


Future<T?> showAppModal<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
}) {
  final c = AppColors(Theme.of(context).brightness == Brightness.dark);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.modalScrim,
    builder: (ctx) {
      return _AppModalBody(title: title, child: builder(ctx));
    },
  );
}

class _AppModalBody extends StatelessWidget {
  final String title;
  final Widget child;
  const _AppModalBody({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: c.modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppFonts.display(size: 18, weight: FontWeight.w600, color: c.textPrimary)),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: c.chipBg, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 16, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}