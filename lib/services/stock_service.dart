import 'package:cloud_firestore/cloud_firestore.dart';

class StockService {
  final CollectionReference stockRef = FirebaseFirestore.instance.collection('stocks');

  // Get all stock items
  Future<List<Map<String, dynamic>>> getAllStocks() async {
    final snapshot = await stockRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Add new stock item
  Future<void> addStock(Map<String, dynamic> data) async {
    await stockRef.add(data);
  }

  // Update existing stock item
  Future<void> updateStock(String id, Map<String, dynamic> data) async {
    await stockRef.doc(id).update(data);
  }

  // Delete stock item
  Future<void> deleteStock(String id) async {
    await stockRef.doc(id).delete();
  }
}
