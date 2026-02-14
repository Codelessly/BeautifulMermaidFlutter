import 'package:flutter_test/flutter_test.dart';

import 'package:beautiful_mermaid_example/main.dart';

void main() {
  testWidgets('ExampleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Beautiful Mermaid'), findsOneWidget);
  });
}
