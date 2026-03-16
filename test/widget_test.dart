import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_ifta_app/main.dart';

void main() {
  testWidgets('Fuel IFTA app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const FuelIftaApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
