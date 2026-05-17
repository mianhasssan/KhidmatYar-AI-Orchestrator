import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services_all_screen.dart';
import '../theme/app_theme.dart';
import '../config/keys.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final Function(String serviceName)? onBookService;
  const HomeScreen({super.key, this.onSearchTap, this.onBookService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = "Ahmed Khan";
  String _location = "G-13, Islamabad";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? "Guest User";
      _location = prefs.getString('user_city') ?? "G-13, Islamabad";
    });

    // Dynamic background geocoding on launch to ensure accuracy
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        await prefs.setDouble('user_lat', position.latitude);
        await prefs.setDouble('user_lng', position.longitude);
        final geoUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${APIKeys.googleMapsKey}";
        final response = await http.get(Uri.parse(geoUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == "OK" && data['results'] != null && data['results'].isNotEmpty) {
            final components = data['results'][0]['address_components'] as List;
            String city = "";
            String region = "";
            String country = "";
            for (var comp in components) {
              final List types = comp['types'];
              if (types.contains('locality') || types.contains('sublocality') || types.contains('neighborhood')) {
                city = comp['long_name'];
              } else if (types.contains('administrative_area_level_1')) {
                region = comp['long_name'];
              } else if (types.contains('country')) {
                country = comp['long_name'];
              }
            }
            final parts = [city, region, country].where((p) => p.isNotEmpty).toList();
            String resolved = parts.isNotEmpty ? parts.join(", ") : data['results'][0]['formatted_address'].toString().split(",")[0];
            
            await prefs.setString('user_city', resolved);
            if (mounted) {
              setState(() {
                _location = resolved;
              });
            }
          }
        }
      }
    } catch (e) {
      print("Home screen geocoding error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAiSearchBanner(context),
              const SizedBox(height: 32),
              _buildPopularServices(),
              const SizedBox(height: 32),
              _buildRecentBookings(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good morning,", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
            Text(_name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900])),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryGreen,
                    content: Text("Requesting GPS live location coordinates...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
                LocationPermission permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryGreen,
                      content: Text("✓ Location successfully updated to: $_location", style: GoogleFonts.inter(color: AppTheme.accentLime, fontWeight: FontWeight.bold)),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Permission denied! Please enable location in system settings."),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(_location, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
            image: DecorationImage(image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=$_name")),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSearchBanner(BuildContext context) {
    return GestureDetector(
      // The tap is handled by the MainNavigation floating button in React, 
      // but we can make this open the same modal if we pass a callback, or keep it visual.
      onTap: widget.onSearchTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0B281F), Color(0xFF144333)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF144333).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20, right: -20,
              child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentLime.withOpacity(0.1))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.accentLime, size: 18),
                    const SizedBox(width: 8),
                    Text("Just tell us what you need", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Urdu, Roman Urdu, or English.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.accentLime, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('"Mujhe kal subah AC technician chahiye..."', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularServices() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Popular Services", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900])),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServicesAllScreen(
                      onBookService: widget.onBookService,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text("See All", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lime[700])),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildServiceIconItem("AC Repair", Icons.build, Colors.blue[500]!, Colors.blue[50]!)),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceIconItem("Plumbing", Icons.water_drop, Colors.teal[500]!, Colors.teal[50]!)),
            const SizedBox(width: 12),
            Expanded(child: _buildServiceIconItem("Electrician", Icons.flash_on, Colors.orange[500]!, Colors.orange[50]!)),
          ],
        )
      ],
    );
  }

  Widget _buildServiceIconItem(String title, IconData icon, Color iconColor, Color bgColor) {
    return GestureDetector(
      onTap: () {
        if (widget.onBookService != null) {
          widget.onBookService!(title);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Bookings", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900])),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
          child: Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, decoration: const BoxDecoration(color: AppTheme.accentLime, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))))),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!), image: const DecorationImage(image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Ali AC Services"))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ali AC Services", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.build, size: 10, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text("AC Technician", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.lime[50], border: Border.all(color: Colors.lime[100]!), borderRadius: BorderRadius.circular(12)),
                          child: Text("Confirmed", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lime[700])),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Text("Tomorrow, 10:00 AM", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                            ],
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
