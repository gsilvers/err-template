import 'package:flutter_test/flutter_test.dart';

import 'package:err_template/main.dart';

void main() {
  testWidgets('tapping the button counts taps', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Tapped 0 times'), findsOneWidget);

    await tester.tap(find.byTooltip('Tap'));
    await tester.pump();
    expect(find.text('Tapped 1 times'), findsOneWidget);
  });
}
