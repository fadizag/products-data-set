import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProductsDatasetApp());
}

const _storageKey = 'products_dataset.records.v1';
const _uuid = Uuid();
const _categories = <String>['مواد غذائية', 'مشروبات', 'ألبان وأجبان', 'منظفات', 'عناية شخصية', 'أخرى'];

class ProductRecord {
  const ProductRecord({
    required this.id, required this.nameAr, required this.category,
    required this.createdAt, required this.updatedAt,
    this.nameEn = '', this.brand = '', this.barcode = '', this.origin = '',
    this.description = '', this.archived = false,
  });
  final String id, nameAr, nameEn, category, brand, barcode, origin, description;
  final bool archived;
  final DateTime createdAt, updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id, 'nameAr': nameAr, 'nameEn': nameEn, 'category': category,
    'brand': brand, 'barcode': barcode, 'origin': origin,
    'description': description, 'archived': archived,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(), 'schemaVersion': 1,
  };

  factory ProductRecord.fromJson(Map<String, dynamic> j) => ProductRecord(
    id: j['id'] as String, nameAr: j['nameAr'] as String? ?? '',
    nameEn: j['nameEn'] as String? ?? '', category: j['category'] as String? ?? 'أخرى',
    brand: j['brand'] as String? ?? '', barcode: j['barcode'] as String? ?? '',
    origin: j['origin'] as String? ?? '', description: j['description'] as String? ?? '',
    archived: j['archived'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now().toUtc(),
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now().toUtc(),
  );

  ProductRecord copyWith({bool? archived}) => ProductRecord(
    id: id, nameAr: nameAr, nameEn: nameEn, category: category, brand: brand,
    barcode: barcode, origin: origin, description: description,
    archived: archived ?? this.archived, createdAt: createdAt, updatedAt: DateTime.now().toUtc(),
  );
}

class ProductsDatasetApp extends StatelessWidget {
  const ProductsDatasetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'دليل المنتجات', debugShowCheckedModeBanner: false,
    locale: const Locale('ar'), supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF596B45)),
      scaffoldBackgroundColor: const Color(0xFFF7F6F0),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F6F0)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    ),
    home: const CatalogHomePage(),
  );
}

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({super.key});
  @override
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}

class _CatalogHomePageState extends State<CatalogHomePage> {
  final _search = TextEditingController();
  List<ProductRecord> _products = [];
  String _category = 'الكل';
  bool _archived = false, _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() { if (mounted) setState(() {}); });
  }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        _products = (jsonDecode(raw) as List<dynamic>)
          .map((e) => ProductRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر قراءة البيانات المحلية.')));
    }
    if (mounted) setState(() => _loading = false);
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_products.map((p) => p.toJson()).toList()));
  }

  List<ProductRecord> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _products.where((p) {
      if (p.archived != _archived || (_category != 'الكل' && p.category != _category)) return false;
      if (q.isEmpty) return true;
      return p.nameAr.toLowerCase().contains(q) || p.nameEn.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _edit({ProductRecord? old}) async {
    final result = await showDialog<ProductRecord>(context: context, builder: (_) => _ProductDialog(product: old));
    if (result == null || !mounted) return;
    final duplicate = result.barcode.isNotEmpty && _products.any((p) =>
      p.id != result.id && p.barcode.isNotEmpty && p.barcode == result.barcode);
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الباركود مسجّل لمنتج آخر.')));
      return;
    }
    setState(() {
      final i = _products.indexWhere((p) => p.id == result.id);
      if (i < 0) { _products.add(result); } else { _products[i] = result; }
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(old == null ? 'تم حفظ المنتج على هذا الجهاز.' : 'تم تحديث المنتج.')));
  }

  Future<void> _archive(ProductRecord p) async {
    setState(() {
      final i = _products.indexWhere((x) => x.id == p.id);
      if (i >= 0) _products[i] = p.copyWith(archived: !p.archived);
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.archived ? 'تمت استعادة المنتج.' : 'تمت أرشفة المنتج.')));
  }

  Future<void> _backup() async {
    final value = const JsonEncoder.withIndent('  ').convert(_products.map((p) => p.toJson()).toList());
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('نسخة احتياطية JSON'),
      content: SizedBox(width: 560, child: SingleChildScrollView(child: SelectableText(value))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final count = _products.where((p) => p.archived == _archived).length;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(
        title: const Text('دليل المنتجات'),
        actions: [
          IconButton(tooltip: 'نسخة JSON', onPressed: _backup, icon: const Icon(Icons.data_object_rounded)),
          PopupMenuButton<String>(
            tooltip: 'خيارات',
            onSelected: (v) => setState(() { _archived = v == 'archived' ? !_archived : _archived; _category = 'الكل'; }),
            itemBuilder: (_) => [PopupMenuItem(value: 'archived', child: Text(_archived ? 'عرض المنتجات النشطة' : 'عرض الأرشيف'))],
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: const Text('إضافة منتج'),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850),
        child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            Text('قاعدة بيانات المنتجات', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أضف المنتجات الفلسطينية وصنّفها. البيانات تُحفظ محليًا على هذا المتصفح أو الجهاز.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(controller: _search, textInputAction: TextInputAction.search, decoration: InputDecoration(
              hintText: 'ابحث باسم المنتج أو العلامة أو الباركود', prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty ? const Icon(Icons.qr_code_rounded) : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
            )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _category, isExpanded: true,
                decoration: const InputDecoration(labelText: 'التصنيف', prefixIcon: Icon(Icons.category_outlined)),
                items: ['الكل', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'الكل'),
              )),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFE8EDDF), borderRadius: BorderRadius.circular(14)), child: Text('$count منتج')),
            ]),
            const SizedBox(height: 16),
            if (items.isEmpty) Card(
              elevation: 0, color: const Color(0xFFE8EDDF),
              child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                Icon(_archived ? Icons.archive_outlined : Icons.inventory_2_outlined, size: 42, color: const Color(0xFF596B45)),
                const SizedBox(height: 12),
                Text(_search.text.isNotEmpty ? 'ما لقينا منتجات مطابقة' : (_archived ? 'الأرشيف فارغ' : 'لسّه ما أضفت منتجات'),
                  style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_search.text.isNotEmpty ? 'جرّب اسمًا آخر أو امسح البحث.' : (_archived ? 'المنتجات المؤرشفة ستظهر هنا.' : 'اضغط «إضافة منتج» لتسجيل أول منتج، وبعدها جرّب البحث والتعديل.'),
                  textAlign: TextAlign.center),
                if (!_archived && _search.text.isEmpty) ...[
                  const SizedBox(height: 14), FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('إضافة أول منتج')),
                ],
              ])),
            ) else ...items.map((p) => _ProductTile(product: p, onEdit: () => _edit(old: p), onArchive: () => _archive(p))),
            const SizedBox(height: 14),
            Text('الحفظ محلي على هذا المتصفح أو الجهاز؛ المزامنة السحابية لم تُضف بعد.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      )),
    ));
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit, required this.onArchive});
  final ProductRecord product;
  final VoidCallback onEdit, onArchive;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE8EDDF), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF596B45))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.nameAr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (product.nameEn.isNotEmpty) Text(product.nameEn, textDirection: TextDirection.ltr),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _Tag(product.category), if (product.brand.isNotEmpty) _Tag(product.brand),
          if (product.origin.isNotEmpty) _Tag('المنشأ: \${product.origin}'),
        ]),
        if (product.barcode.isNotEmpty) ...[const SizedBox(height: 7), Text('الباركود: \${product.barcode}', textDirection: TextDirection.ltr)],
        if (product.description.isNotEmpty) ...[const SizedBox(height: 5), Text(product.description)],
      ])),
      PopupMenuButton<String>(
        tooltip: 'إجراءات المنتج',
        onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'archive') onArchive(); },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('تعديل')),
          PopupMenuItem(value: 'archive', child: Text(product.archived ? 'استعادة من الأرشيف' : 'أرشفة')),
        ],
      ),
    ])),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFF0F1E9), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});
  final ProductRecord? product;
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ar, _en, _brand, _barcode, _origin, _description;
  late String _category;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _ar = TextEditingController(text: p?.nameAr ?? '');
    _en = TextEditingController(text: p?.nameEn ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _origin = TextEditingController(text: p?.origin ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = _categories.contains(p?.category) ? p!.category : _categories.last;
  }
  @override
  void dispose() { _ar.dispose(); _en.dispose(); _brand.dispose(); _barcode.dispose(); _origin.dispose(); _description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
    title: Text(widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _ar, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المنتج بالعربية *'),
        validator: (v) => v == null || v.trim().isEmpty ? 'اسم المنتج مطلوب' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _en, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية (اختياري)')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _category, isExpanded: true, decoration: const InputDecoration(labelText: 'التصنيف *'),
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _category = v ?? _categories.last)),
      const SizedBox(height: 12),
      TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'العلامة التجارية')),
      const SizedBox(height: 12),
      TextFormField(controller: _barcode, keyboardType: TextInputType.text, textDirection: TextDirection.ltr,
        decoration: const InputDecoration(labelText: 'الباركود (اختياري)')),
      const SizedBox(height: 12),
      TextFormField(controller: _origin, decoration: const InputDecoration(labelText: 'بلد المنشأ (اختياري)')),
      const SizedBox(height: 12),
      TextFormField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات أو وصف (اختياري)')),
    ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton.icon(onPressed: () {
        if (!_formKey.currentState!.validate()) return;
        final now = DateTime.now().toUtc(), old = widget.product;
        Navigator.pop(context, ProductRecord(
          id: old?.id ?? _uuid.v4(), nameAr: _ar.text.trim(), nameEn: _en.text.trim(),
          category: _category, brand: _brand.text.trim(), barcode: _barcode.text.trim(),
          origin: _origin.text.trim(), description: _description.text.trim(),
          archived: old?.archived ?? false, createdAt: old?.createdAt ?? now, updatedAt: now,
        ));
      }, icon: const Icon(Icons.save_outlined), label: const Text('حفظ المنتج')),
    ],
  ));
}
