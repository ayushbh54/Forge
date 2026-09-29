import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_app/main.dart';

void main() {
  testWidgets('Nirmaan OS app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NirmaanApp());
    expect(find.text('NIRMAAN OS'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 2600));
  });
}
