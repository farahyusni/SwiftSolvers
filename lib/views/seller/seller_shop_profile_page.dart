import 'package:flutter/material.dart';
import 'edit_seller_shop_profile_page.dart';


class SellerShopProfilePage extends StatelessWidget {
  const SellerShopProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEECEE), // Light pink background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIcon(Icons.chevron_left, () {
                      Navigator.pop(context);
                    }),
                    Image.asset(
                      'images/logo.png',
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 40),
                    ),
                    _circleIcon(Icons.person_outline, () {
                      // Maybe profile or settings
                    }),
                  ],
                ),
              ),

              // Store Logo
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green,
                child: Text(
                  'Logo',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 10),

              // Shop Name
              const Text(
                'Segi Fresh Bagan Serai',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // Address
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Text(
                  'No. 40-G, 42-G & 44-G, Jalan Syed Thaupy 2,\nPusat Bandar Baru, 34300 Bagan Serai, Perak',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ),

              // Phone and Email
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 16),
                    SizedBox(width: 5),
                    Text('012-438 8744'),
                    SizedBox(width: 10),
                    Icon(Icons.email, size: 16),
                    SizedBox(width: 5),
                    Text('segifreshbs@gmail.com'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Store Category
              _infoSection(
                title: 'Store Category',
                content: [
                  'Grocery Store',
                  'Fresh Produce',
                  'Household Essentials',
                  'Local Market',
                  'Food Retailer',
                ],
               trailing: TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditSellerShopProfilePage()),
    );
  },child: const Text("Edit Profile", style: TextStyle(color: Colors.black54)),
),
              ),

              // Business Hours
              _infoSection(
                title: 'Business Hours',
                content: [
                  'Monday      : 8 am – 8:30 pm',
                  'Tuesday     : 8 am – 8:30 pm',
                  'Wednesday   : 8 am – 8:30 pm',
                  'Thursday    : 8 am – 8:30 pm',
                  'Friday      : 8 am – 8:30 pm',
                  'Saturday    : 8 am – 8:30 pm',
                  'Sunday      : 8 am – 8:30 pm',
                ],
              ),

              // Payment Method
              _infoSection(
                title: 'Payment Method',
                content: [
                  'Cash on Delivery & Self Pickup',
                  'Delivery Coverage: Bagan Serai, Parit Buntar, Selama',
                  'Pickup Address: Same as shop address',
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }

  Widget _infoSection({
    required String title,
    required List<String> content,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 5),
          for (var line in content)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line),
            ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
