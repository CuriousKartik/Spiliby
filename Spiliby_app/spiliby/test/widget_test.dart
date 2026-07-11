import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiliby/data/app_store.dart';
import 'package:spiliby/main.dart';

void main() {
  testWidgets('Spiliby app shows onboarding on clean start', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appStore = AppStore();
    await appStore.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: appStore, child: const SpilibyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Spiliby'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
