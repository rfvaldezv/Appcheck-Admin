import 'package:flutter_test/flutter_test.dart';
import 'package:appcheck_admin/main.dart';

void main() {
  testWidgets('La app carga la pantalla de Login', (WidgetTester tester) async {
    // Construir la app
    await tester.pumpWidget(const AppCheckAdminApp());

    // Verificar que se muestra el título del login
    expect(find.text('AppCheck Admin'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
