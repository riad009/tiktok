import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artistcase/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ArtistcaseApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
