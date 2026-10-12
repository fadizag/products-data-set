import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const ProductsDatasetApp()); }
const _storageKey = 'products_dataset.records.v2';
const _uuid = Uuid();

class ProductRecord {
  const ProductRecord({required this.id, required this.nameAr, required this.barcode, required this.images, required this.createdAt, required this.updatedAt, this.archived = false});
  final String id, nameAr, barcode;
  final List<String> images;
  final DateTime createdAt, updatedAt;
  final bool archived;
  Map<String, dynamic> toJson() => {'id': id, 'nameAr': nameAr, 'barcode': barcode, 'images': images, 'archived': archived, 'createdAt': createdAt.toUtc().toIso8601String(), 'updatedAt': updatedAt.toUtc().toIso8601String(), 'schemaVersion': 2};
  factory ProductRecord.fromJson(Map<String, dynamic> j) => ProductRecord(
    id: j['id'] as String? ?? _uuid.v4(), nameAr: j['nameAr'] as String? ?? '', barcode: j['barcode'] as String? ?? '',
    images: (j['images'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    archived: j['archived'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now().toUtc(),
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now().toUtc());
  ProductRecord copyWith({bool? archived}) => ProductRecord(id: id, nameAr: nameAr, barcode: barcode, images: images, archived: archived ?? this.archived, createdAt: createdAt, updatedAt: DateTime.now().toUtc());
}

class ProductsDatasetApp extends StatelessWidget {
  const ProductsDatasetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'دليل المنتجات', debugShowCheckedModeBanner: false, locale: const Locale('ar'), supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF596B45)), scaffoldBackgroundColor: const Color(0xFFF7F6F0),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F6F0)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
    home: const CatalogHomePage());
}

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({super.key});
  @override
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}
class _CatalogHomePageState extends State<CatalogHomePage> {
  final _search = TextEditingController();
  List<ProductRecord> _products = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); _search.addListener(() { if (mounted) setState(() {}); }); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance(), raw = prefs.getString(_storageKey);
      if (raw != null) _products = (jsonDecode(raw) as List<dynamic>).map((e) => ProductRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّرت قراءة البيانات المحلية.'))); }
    if (mounted) setState(() => _loading = false);
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_products.map((p) => p.toJson()).toList()));
  }
  List<ProductRecord> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _products.where((p) => q.isEmpty || p.nameAr.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q)).toList()..sort((a,b) => b.updatedAt.compareTo(a.updatedAt));
  }
  Future<void> _edit({ProductRecord? old}) async {
    final result = await showDialog<ProductRecord>(context: context, builder: (_) => _ProductDialog(product: old));
    if (result == null || !mounted) return;
    if (result.barcode.trim().isNotEmpty && _products.any((p) => p.id != result.id && p.barcode.trim().isNotEmpty && p.barcode.trim() == result.barcode.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الباركود مسجّل لمنتج آخر.'))); return;
    }
    final previous = List<ProductRecord>.from(_products);
    setState(() { final i = _products.indexWhere((p) => p.id == result.id); if (i < 0) { _products.add(result); } else { _products[i] = result; } });
    try {
      await _save();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(old == null ? 'تم حفظ المنتج.' : 'تم تحديث المنتج.')));
    } catch (_) {
      setState(() => _products = previous);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الحفظ؛ جرّب صورًا أقل أو أصغر.')));
    }
  }
  Future<void> _deleteProduct(ProductRecord product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنتج؟'),
        content: Text('هل تريد حذف «${product.nameAr}» نهائيًا؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final previous = List<ProductRecord>.from(_products);
    setState(() => _products.removeWhere((p) => p.id == product.id));
    try {
      await _save();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنتج.')));
    } catch (_) {
      if (mounted) setState(() => _products = previous);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ الحذف.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible, count = _products.length;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('دليل المنتجات')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), tooltip: 'إضافة منتج', child: const Icon(Icons.add_rounded, size: 32)),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(18,10,18,100), children: [
        Text('قاعدة بيانات المنتجات', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('سجّل صورة المنتج واسمه العربي والباركود فقط. الأسعار والحقول الأخرى نضيفها لاحقًا عند الاستيراد.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        TextField(controller: _search, textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'ابحث باسم المنتج أو الباركود', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? const Icon(Icons.qr_code_rounded) : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded)))),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: Text('المنتجات', style: Theme.of(context).textTheme.titleMedium)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFE8EDDF), borderRadius: BorderRadius.circular(14)), child: Text('$count منتج'))]),
        const SizedBox(height: 12),
        if (items.isEmpty) Card(elevation: 0, color: const Color(0xFFE8EDDF), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF596B45)), const SizedBox(height: 12),
          Text(_search.text.isNotEmpty ? 'ما لقينا منتجات مطابقة' : 'لسّه ما أضفت منتجات', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8), Text(_search.text.isNotEmpty ? 'جرّب اسمًا آخر أو امسح البحث.' : 'اضغط «إضافة منتج» لتسجيل أول منتج.', textAlign: TextAlign.center),
          if (_search.text.isEmpty) ...[const SizedBox(height: 14), FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('إضافة أول منتج'))],
        ]))) else ...items.map((p) => _ProductTile(product: p, onEdit: () => _edit(old: p), onDelete: () => _deleteProduct(p))),
        const SizedBox(height: 14),
        Text('الحفظ محلي في هذا المتصفح أو الجهاز؛ لم تتم إضافة المزامنة السحابية بعد.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54), textAlign: TextAlign.center),
      ]))),
    ));
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit, required this.onDelete});
  final ProductRecord product; final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      _ProductImage(data: product.images.isEmpty ? null : product.images.first), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.nameAr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (product.barcode.isNotEmpty) ...[const SizedBox(height: 5), Text('الباركود: ${product.barcode}', textDirection: TextDirection.ltr)],
        if (product.images.length > 1) ...[const SizedBox(height: 5), Text('عدد الصور: ${product.images.length}')],
      ])),
      PopupMenuButton<String>(tooltip: 'إجراءات المنتج', onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'delete') onDelete(); },
        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]),
    ])));
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.data}); final String? data;
  @override
  Widget build(BuildContext context) {
    final bytes = data == null ? null : base64Decode(data!);
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 68, height: 68, color: const Color(0xFFE8EDDF),
      child: bytes == null ? const Icon(Icons.image_outlined, size: 30, color: Color(0xFF596B45)) : Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))));
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product}); final ProductRecord? product;
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}
class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>(); final _picker = ImagePicker();
  late final TextEditingController _name, _barcode;
  late List<String> _images; bool _picking = false;
  @override
  void initState() { super.initState(); _name = TextEditingController(text: widget.product?.nameAr ?? ''); _barcode = TextEditingController(text: widget.product?.barcode ?? ''); _images = List<String>.from(widget.product?.images ?? const []); }
  @override
  void dispose() { _name.dispose(); _barcode.dispose(); super.dispose(); }
  Future<void> _pickImages() async {
    setState(() => _picking = true);
    try {
      // Keep product details legible while reducing storage size.
      final files = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
      for (final file in files) { final bytes = await file.readAsBytes(); if (bytes.isNotEmpty) _images.add(base64Encode(bytes)); }
      if (mounted) setState(() {});
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر اختيار الصور. جرّب صور JPG أو PNG.'))); }
    finally { if (mounted) setState(() => _picking = false); }
  }
  Future<void> _takePhoto() async {
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) _images.add(base64Encode(bytes));
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح الكاميرا. تأكد من صلاحية الكاميرا وجرب مرة أخرى.')));
    } finally { if (mounted) setState(() => _picking = false); }
  }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
    title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل المنتج'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _picking ? null : _takePhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('تصوير بالكاميرا'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: _picking ? null : _pickImages, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('من المعرض'))),
      ]),
      if (_picking) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      if (_images.isNotEmpty) ...[const SizedBox(height: 12), SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _images.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, i) => Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(_images[i]), width: 88, height: 88, fit: BoxFit.cover)),
        Positioned(top: 2, left: 2, child: InkWell(onTap: () => setState(() => _images.removeAt(i)), child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(3), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
      ])))],
      const SizedBox(height: 16),
      TextFormField(controller: _name, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المنتج بالعربية *', hintText: 'مثال: زيت زيتون فلسطيني'), validator: (v) => v == null || v.trim().isEmpty ? 'اسم المنتج مطلوب' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _barcode, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'الباركود (اختياري)', hintText: 'أدخل الرقم كما هو على العبوة')),
      const SizedBox(height: 8),
      Text('لا توجد حقول أسعار في هذه المرحلة؛ سنضيفها ضمن الاستيراد لاحقًا.', style: Theme.of(context).textTheme.bodySmall),
    ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton.icon(onPressed: _picking ? null : () {
        if (!_formKey.currentState!.validate()) return;
        final now = DateTime.now().toUtc(), old = widget.product;
        Navigator.pop(context, ProductRecord(id: old?.id ?? _uuid.v4(), nameAr: _name.text.trim(), barcode: _barcode.text.trim(), images: List<String>.from(_images), archived: old?.archived ?? false, createdAt: old?.createdAt ?? now, updatedAt: now));
      }, icon: const Icon(Icons.save_outlined), label: const Text('حفظ المنتج')),
    ],
  ));
}
