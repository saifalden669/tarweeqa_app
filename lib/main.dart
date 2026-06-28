import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ترويقة",
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
        fontFamily: 'Arial', 
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> products = [];
  double currentDollarRate = 15000.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDollarRate = prefs.getDouble('dollarRate') ?? 15000.0;
    });

    String? data = prefs.getString('products');
    if (data != null) {
      setState(() {
        products = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products));
  }

  Future<void> saveDollarRate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dollarRate', currentDollarRate);
  }

  String formatNumber(num number) {
    final formatter = NumberFormat("#,##0");
    return formatter.format(number);
  }

  void addProductDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة منتج جديد", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "اسم المنتج",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(
                labelText: "الكمية",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(
                labelText: "سعر البيع (دولار)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.brown[50],
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("حفظ"),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  products.add({
                    "id": DateTime.now().millisecondsSinceEpoch,
                    "name": nameCtrl.text.trim(),
                    "qty": int.tryParse(qtyCtrl.text) ?? 0,
                    "sellPriceUsd": double.tryParse(priceCtrl.text) ?? 0.0,
                    "date": DateTime.now().toString().substring(0, 10),
                  });
                });
                saveProducts();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void deleteProduct(int id) {
    setState(() {
      products.removeWhere((p) => p["id"] == id);
    });
    saveProducts();
  }

  void sell(int id) {
    final index = products.indexWhere((p) => p["id"] == id);
    if (index != -1 && products[index]["qty"] > 0) {
      setState(() {
        products[index]["qty"]--;
      });
      saveProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الكمية غير كافية للبيع!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void restock(int id) {
    final index = products.indexWhere((p) => p["id"] == id);
    if (index != -1) {
      setState(() {
        products[index]["qty"]++;
      });
      saveProducts();
    }
  }

  void changeDollarRate() {
    final rateCtrl = TextEditingController(text: currentDollarRate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تحديث سعر الدولار", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: rateCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "سعر الدولار (ل.س)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.brown[50],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("حفظ"),
            onPressed: () {
              final newRate = double.tryParse(rateCtrl.text);
              if (newRate != null && newRate > 0) {
                setState(() => currentDollarRate = newRate);
                saveDollarRate();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ترويقة", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: changeDollarRate,
            tooltip: "تغيير سعر الدولار",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.brown[100],
            child: Center(
              child: Text(
                "سعر الدولار اليوم: ${formatNumber(currentDollarRate)} ل.س",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.brown[300]),
                        const SizedBox(height: 16),
                        const Text(
                          "لا توجد منتجات بعد\nاضغط + لإضافة أول منتج",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final priceInLira = p["sellPriceUsd"] * currentDollarRate;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    p["name"],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "الكمية: ${p["qty"]}",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("💲 دولار: ${formatNumber(p["sellPriceUsd"])} \$"),
                                      const SizedBox(height: 4),
                                      Text("🇸🇾 ليرة: ${formatNumber(priceInLira)} ل.س"),
                                    ],
                                  ),
                                  Text(
                                    "📅 ${p["date"]}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () => deleteProduct(p["id"]),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => restock(p["id"]),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text("جلب"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => sell(p["id"]),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text("بيع"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addProductDialog,
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }
}
