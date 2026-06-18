import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_export_stock_page.dart';
import 'export_listing_detail_page.dart';
import '../l10n/app_localizations.dart';

class ExportHubPage extends StatefulWidget {
  const ExportHubPage({super.key});

  @override
  State<ExportHubPage> createState() => _ExportHubPageState();
}

class _ExportHubPageState extends State<ExportHubPage> {
  String? role;
  bool isLoading = true;

  String searchQuery = '';
  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        role = doc.data()?['role'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == 'admin') {
      return adminView(context);
    } else if (role == 'exporter') {
      return exporterView(context);
    } else {
      return farmerView(context);
    }
  }

  // ================= ADMIN VIEW =================

  Widget adminView(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return Scaffold(
    backgroundColor: const Color(0xfff4f7f5),
    appBar: AppBar(
      elevation: 0,
      title: Text(l.exportHub),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff2e7d32), Color(0xff66bb6a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ),
    body: Column(
      children: [

        const SizedBox(height: 15),

        // 🔍 MODERN SEARCH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.searchByCropFarmer,
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 15),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('export_listings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final listings = snapshot.data!.docs;

              final filtered = listings.where((doc) {
                final data =
                    doc.data() as Map<String, dynamic>;

                final product =
                    (data['productName'] ?? '')
                        .toString()
                        .toLowerCase();
                final farmer =
                    (data['farmerName'] ?? '')
                        .toString()
                        .toLowerCase();
                final location =
                    (data['location'] ?? '')
                        .toString()
                        .toLowerCase();

                return product.contains(searchQuery) ||
                    farmer.contains(searchQuery) ||
                    location.contains(searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                    child: Text(
                        l.noListingsFound,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w500)));
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final product =
                      data['productName']?.toString() ?? '';
                  final farmer =
                      data['farmerName']?.toString() ??
                          'Unknown';
                  final quantity =
                      data['quantity']?.toString() ?? '';
                  final price =
                      data['pricePerKg']?.toString() ?? '';
                  final location =
                      data['location']?.toString() ?? '';
                  final status =
                      data['status']?.toString() ??
                          'open';

                  Color statusColor;
                  if (status == 'approved') {
                    statusColor = Colors.green;
                  } else if (status == 'rejected') {
                    statusColor = Colors.red;
                  } else {
                    statusColor = Colors.orange;
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExportListingDetailPage(
                            docId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.05),
                            blurRadius: 10,
                            offset:
                                const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,

  children: [

    ClipRRect(
      borderRadius:
          BorderRadius.circular(14),

      child: data['imageUrl'] != null &&
              data['imageUrl']
                  .toString()
                  .isNotEmpty
          ? Image.network(
              data['imageUrl']
                  .toString(),

              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,

              errorBuilder:
                  (_, __, ___) {
                return Image.asset(
                  'assets/farmer_logo.png',

                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            )
          : Image.asset(
              'assets/farmer_logo.png',

              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    ),

    const SizedBox(height: 14),

    // PRODUCT NAME
    Text(
      product,
      style: const TextStyle(
        fontSize: 18,
        fontWeight:
            FontWeight.bold,
      ),
    ),

                          // PRODUCT NAME
                          Text(
                            product,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text("👨 Farmer: $farmer"),
                          Text("📦 Quantity: $quantity"),
                          Text("💰 Price/kg: $price"),
                          Text("📍 Location: $location"),

                          const SizedBox(height: 12),

                          // STATUS BADGE
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius
                                      .circular(30),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
  // ================= FARMER VIEW =================

  Widget farmerView(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final user = FirebaseAuth.instance.currentUser;

  return Scaffold(
    appBar: AppBar(
      title: Text(l.exportHub),
    ),
    body: Column(
      children: [

        const SizedBox(height: 20),

        // POST BUTTON
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l.postExportStock),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PostExportStockPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        const Divider(),

        Text(
          l.myListings,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('export_listings')
                .where('farmerId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final listings = snapshot.data!.docs;

              if (listings.isEmpty) {
                return Center(
                    child: Text(l.noListingsYet));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: listings.length,
                itemBuilder: (context, index) {

                  final doc = listings[index];
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final product =
                      data['productName']?.toString() ?? '';
                  final quantity =
                      data['quantity']?.toString() ?? '';
                  final price =
                      data['pricePerKg']?.toString() ?? '';
                  final location =
                      data['location']?.toString() ?? '';
                  final status =
                      data['status']?.toString() ?? 'open';

                  Color statusColor;
                  if (status == 'approved') {
                    statusColor = Colors.green;
                  } else if (status == 'rejected') {
                    statusColor = Colors.red;
                  } else {
                    statusColor = Colors.orange;
                  }

                  return Card(
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),
                      child: Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,

  children: [

    ClipRRect(
      borderRadius:
          BorderRadius.circular(12),

      child:
          data['imageUrl'] != null &&
                  data['imageUrl']
                      .toString()
                      .isNotEmpty
              ? Image.network(
                  data['imageUrl']
                      .toString(),

                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,

                  errorBuilder:
                      (_, __, ___) {
                    return Image.asset(
                      'assets/farmer_logo.png',

                      height: 170,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  'assets/farmer_logo.png',

                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
    ),

    const SizedBox(height: 12),

    Text(
      product,
      style: const TextStyle(
        fontWeight:
            FontWeight.bold,
        fontSize: 16,
      ),
    ),

                          Text(
                            product,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text("Quantity: $quantity"),
                          Text("Price/kg: $price"),
                          Text("Location: $location"),

                          const SizedBox(height: 6),

                          Text(
                            "Status: $status",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color: statusColor,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PostExportStockPage(
                                        isEdit: true,
                                        docId: doc.id,
                                        existingData:
                                            data,
                                      ),
                                    ),
                                  );
                                },
                                child:
                                    Text(l.edit),
                              ),

                              const SizedBox(
                                  width: 10),

                              ElevatedButton(
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'export_listings')
                                      .doc(doc.id)
                                      .delete();
                                },
                                child: Text(
                                    l.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
  // ================= EXPORTER VIEW =================

  Widget exporterView(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(l.exportHub)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('export_listings')
            .where('visibleToExporters',
                arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final listings = snapshot.data!.docs;

          if (listings.isEmpty) {
            return Center(
                child: Text(l.noListingsFound));
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final data =
                  listings[index].data()
                      as Map<String, dynamic>;

              final product =
                  data['productName']?.toString() ?? '';
              final quantity =
                  data['quantity']?.toString() ?? '';
              final price =
                  data['pricePerKg']?.toString() ?? '';

              return Card(
  margin:
      const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),

  shape: RoundedRectangleBorder(
    borderRadius:
        BorderRadius.circular(16),
  ),

  child: Padding(
    padding: const EdgeInsets.all(12),

    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          child:
              data['imageUrl'] !=
                          null &&
                      data['imageUrl']
                          .toString()
                          .isNotEmpty
                  ? Image.network(
                      data['imageUrl']
                          .toString(),

                      height: 180,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,

                      errorBuilder:
                          (_, __, ___) {
                        return Image.asset(
                          'assets/farmer_logo.png',

                          height: 180,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/farmer_logo.png',

                      height: 180,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,
                    ),
        ),

        const SizedBox(height: 14),

        Text(
          product,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text("📦 Qty: $quantity"),

        Text("💰 Price: $price"),
      ],
    ),
  ),
);
            },
          );
        },
      ),
    );
  }
}