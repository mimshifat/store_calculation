import 'package:flutter_test/flutter_test.dart';
import 'package:shukriya_store/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShukriyaStoreApp());
    expect(find.byType(ShukriyaStoreApp), findsOneWidget);
  });
}
