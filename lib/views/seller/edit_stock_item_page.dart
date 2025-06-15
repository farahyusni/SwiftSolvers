import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/stock_service.dart'; // <-- Add this import and adjust path if needed

class EditStockItemPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditStockItemPage({Key? key, required this.item}) : super(key: key);

  @override
  _EditStockItemPageState createState() => _EditStockItemPageState();
}

class _EditStockItemPageState extends State<EditStockItemPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController categoryController;
  late TextEditingController unitController;

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name'] ?? '');
    priceController = TextEditingController(text: widget.item['price']?.toString() ?? '');
    stockController = TextEditingController(text: widget.item['stock']?.toString() ?? '');
    categoryController = TextEditingController(text: widget.item['category'] ?? '');
    unitController = TextEditingController(text: widget.item['unit'] ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    categoryController.dispose();
    unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Stock Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedItem = {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'unit': unitController.text,
                  'category': categoryController.text,
                };

                try {
                  final stockService = StockService();

                  if (widget.item['id'] == null || widget.item['id'].toString().isEmpty) {
                    await stockService.addStock(updatedItem);
                  } else {
                    await stockService.updateStock(widget.item['id'], updatedItem);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.item['id'] == '' ? 'Item added successfully' : 'Item updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
