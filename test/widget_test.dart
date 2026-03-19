import 'package:flutter_test/flutter_test.dart';
import 'package:start_hack_2026/app.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('InvestQuest'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });
}
