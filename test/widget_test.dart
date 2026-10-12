import 'package:flutter_test/flutter_test.dart';
import 'package:products_dataset/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows simplified Arabic product catalog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProductsDatasetApp());
    await tester.pumpAndSettle();

    expect(find.text('دليل المنتجات'), findsOneWidget);
    expect(find.text('قاعدة بيانات المنتجات'), findsOneWidget);
    expect(find.text('ابحث باسم المنتج أو الباركود'), findsOneWidget);
    expect(find.text('إضافة أول منتج'), findsOneWidget);
  });
}
