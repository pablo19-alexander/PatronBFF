import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('Pantalla inicial muestra titulo y los dos botones de carga',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TallerApp());

    expect(find.text('Taller 4 - BFF vs Carga Directa'), findsOneWidget);
    expect(find.text('Carga Directa'), findsOneWidget);
    expect(find.text('Carga BFF'), findsOneWidget);
    expect(find.text('Selecciona un modo de carga'), findsOneWidget);
  });
}
