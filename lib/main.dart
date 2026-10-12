import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProductsDatasetApp());
}

class ProductsDatasetApp extends StatelessWidget {
  const ProductsDatasetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF596B45);
    return MaterialApp(
      title: 'دليل المنتجات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF7F6F0),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F6F0)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const CatalogHomePage(),
    );
  }
}

class CatalogHomePage extends StatelessWidget {
  const CatalogHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دليل المنتجات'),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'قاعدة بيانات المنتجات',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ابدأ بتجميع المنتجات الفلسطينية وتصنيفها، مع إمكانية التوسع لاحقاً.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const TextField(
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المنتج أو الباركود',
                    prefixIcon: Icon(Icons.search_rounded),
                    suffixIcon: Icon(Icons.qr_code_scanner_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: const Color(0xFFE8EDDF),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 32),
                        const SizedBox(height: 12),
                        Text('الهيكل الأولي جاهز للتطوير', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text('هذه شاشة تأسيسية فقط. لم يتم توصيل قاعدة بيانات أو البحث الفعلي أو المزامنة السحابية بعد.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
