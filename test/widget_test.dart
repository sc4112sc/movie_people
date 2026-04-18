import 'package:flutter_test/flutter_test.dart';

import 'package:movie_people/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('現正上映'), findsOneWidget);
  });
}
