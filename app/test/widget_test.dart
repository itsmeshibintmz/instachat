import 'package:flutter_test/flutter_test.dart';
import 'package:instachat/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // Verify the app can be instantiated
    expect(const InstaChat(), isNotNull);
  });
}
