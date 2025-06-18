import 'package:flutter/material.dart';

class QuickStats extends StatelessWidget {
  final int numberOfRecipes;
  final String totalSales;
  final int pendingOrders;

  const QuickStats({
    Key? key,
    required this.numberOfRecipes,
    this.totalSales = '-',
    this.pendingOrders = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B8B8B),
            ),
          ),
          const SizedBox(height: 30),

          // Total Sales
          _buildStatCard(
            icon: Icons.attach_money,
            iconColor: const Color(0xFFFF5B9E),
            value: totalSales,
            label: 'Total Sales',
          ),

          // Number of Recipes
          _buildStatCard(
            icon: Icons.receipt_long,
            iconColor: const Color(0xFFFF8C42),
            value: numberOfRecipes.toString(),
            label: 'Number of Recipes',
          ),

          // Pending Orders
          _buildStatCard(
            icon: Icons.pending_actions,
            iconColor: const Color(0xFF4CAF50),
            value: pendingOrders.toString(),
            label: 'Pending Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8B8B8B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
