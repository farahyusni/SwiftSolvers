import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeName;

  const RecipeDetailPage({super.key, required this.recipeName});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late Future<DocumentSnapshot> recipeData;

  @override
  void initState() {
    super.initState();
    recipeData = FirebaseFirestore.instance
        .collection('recipes') // Firestore collection name
        .doc(widget.recipeName) // Use the recipe name or ID as the document ID
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: recipeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Recipe not found"));
          }

          // Extract the data
          final recipe = snapshot.data!.data() as Map<String, dynamic>;
          final String description = recipe['description'] ?? 'No description available';
          final String imageUrl = recipe['imageUrl'] ?? '';
          final List ingredients = recipe['ingredients'] ?? [];
          final List instructions = recipe['instructions'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),

                const SizedBox(height: 20),

                // Recipe Title
                Text(
                  widget.recipeName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Description
                Text(description, style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 20),

                // Ingredients
                const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                for (var ingredient in ingredients)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${ingredient['amount']} ${ingredient['unit']} of ${ingredient['name']}'),
                  ),

                const SizedBox(height: 20),

                // Instructions
                const Text('Instructions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                for (var instruction in instructions)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(instruction['instruction']),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
