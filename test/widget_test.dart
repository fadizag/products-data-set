import 'package:flutter_test/flutter_test.dart';
import 'package:products_dataset/main.dart';

void main() {
  testWidgets('shows Arabic catalog foundation', (tester) async {
    await tester.pumpWidget(const ProductsDatasetApp());
    expect(find.text('دليل المنتجات'), findsOneWidget);
    expect(find.text('قاعدة بيانات المنتجات'), findsOneWidget);
    expect(find.text('ابحث باسم المنتج أو الباركود'), findsOneWidget);
  });
}
