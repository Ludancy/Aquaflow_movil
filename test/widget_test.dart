import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aguaexpress/main.dart';
import 'package:aguaexpress/state/app_state.dart';

void main() {
  testWidgets('AguaExpressApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const AguaExpressApp(),
      ),
    );

    expect(find.text('AguaExpress'), findsOneWidget);
  });
}
