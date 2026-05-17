import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ServicesAllScreen extends StatefulWidget {
  final Function(String serviceName)? onBookService;
  const ServicesAllScreen({super.key, this.onBookService});

  @override
  State<ServicesAllScreen> createState() => _ServicesAllScreenState();
}

class _ServicesAllScreenState extends State<ServicesAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  String _searchQuery = "";

  final List<String> _categories = [
    "All",
    "Climate",
    "Electrical",
    "Plumbing",
    "Cleaning",
    "Carpentry",
    "Appliance"
  ];

  final List<Map<String, dynamic>> _allServices = [
    {"name": "AC Gas Refill & Top Up", "cat": "Climate", "icon": Icons.ac_unit, "color": Colors.blue, "price": "PKR 4,500"},
    {"name": "AC Cleaning & Service", "cat": "Climate", "icon": Icons.waves, "color": Colors.blue, "price": "PKR 2,500"},
    {"name": "AC Compressor Repair", "cat": "Climate", "icon": Icons.build, "color": Colors.blue, "price": "PKR 8,500"},
    {"name": "Ceiling Fan Installation", "cat": "Electrical", "icon": Icons.wind_power, "color": Colors.orange, "price": "PKR 1,500"},
    {"name": "UPS Battery Replacement", "cat": "Electrical", "icon": Icons.battery_charging_full, "color": Colors.orange, "price": "PKR 2,000"},
    {"name": "Short Circuit Repairing", "cat": "Electrical", "icon": Icons.flash_on, "color": Colors.orange, "price": "PKR 3,000"},
    {"name": "Water Tank Leakage Fix", "cat": "Plumbing", "icon": Icons.water_drop, "color": Colors.teal, "price": "PKR 3,500"},
    {"name": "Tap & Mixer Replacement", "cat": "Plumbing", "icon": Icons.plumbing, "color": Colors.teal, "price": "PKR 1,800"},
    {"name": "Drainage Unblocking", "cat": "Plumbing", "icon": Icons.clean_hands, "color": Colors.teal, "price": "PKR 2,500"},
    {"name": "Sofa & Carpet Wash", "cat": "Cleaning", "icon": Icons.dry_cleaning, "color": Colors.green, "price": "PKR 4,000"},
    {"name": "Kitchen Deep Cleaning", "cat": "Cleaning", "icon": Icons.kitchen, "color": Colors.green, "price": "PKR 6,500"},
    {"name": "Full House Cleaning", "cat": "Cleaning", "icon": Icons.home, "color": Colors.green, "price": "PKR 12,000"},
    {"name": "Wooden Door Repairing", "cat": "Carpentry", "icon": Icons.door_sliding, "color": Colors.amber, "price": "PKR 2,800"},
    {"name": "Wardrobe Polish", "cat": "Carpentry", "icon": Icons.brush, "color": Colors.amber, "price": "PKR 5,000"},
    {"name": "Washing Machine Fix", "cat": "Appliance", "icon": Icons.local_laundry_service, "color": Colors.purple, "price": "PKR 3,500"},
    {"name": "Refrigerator Gas Charge", "cat": "Appliance", "icon": Icons.kitchen_outlined, "color": Colors.purple, "price": "PKR 7,500"},
  ];

  @override
  Widget build(BuildContext context) {
    // Filter services based on category and search query
    final filtered = _allServices.where((srv) {
      final matchesCat = _selectedCategory == "All" || srv['cat'] == _selectedCategory;
      final matchesSearch = srv['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          srv['cat'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("All Home Services", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search categories, services...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Categories list slider
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey[200]!),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),

          // Grid View
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text("No matching services found", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final Color themeColor = item['color'];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[100]!),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(item['icon'], color: themeColor, size: 24),
                            ),
                            const Spacer(),
                            Text(
                              item['name'],
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['cat'],
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['price'],
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (widget.onBookService != null) {
                                      widget.onBookService!(item['name']);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: AppTheme.accentLime, shape: BoxShape.circle),
                                    child: const Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.primaryGreen),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
