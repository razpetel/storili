import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storili/app/app.dart';

void main() {
  testWidgets('App starts successfully', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StoriliApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Storili'), findsOneWidget);
  });
}
