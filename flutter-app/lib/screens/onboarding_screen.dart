import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfileAndGetLocation() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      
      // Perform dynamic reverse geocoding via Google Geocoding API
      String userCity = "G-13, Islamabad, Pakistan";
      try {
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
            if (parts.isNotEmpty) {
              userCity = parts.join(", ");
            } else {
              userCity = data['results'][0]['formatted_address'].toString().split(",")[0];
            }
          }
        }
      } catch (e) {
        print("Dynamic geocoding error during onboarding: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_email', _emailController.text);
      await prefs.setString('user_phone', _phoneController.text);
      await prefs.setDouble('user_lat', position.latitude);
      await prefs.setDouble('user_lng', position.longitude);
      await prefs.setString('user_city', userCity);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.accentLime.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.person, size: 40, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text("Create Profile", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
              const SizedBox(height: 8),
              Text("Enter your details and enable location to discover AI-matched services nearby.", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfileAndGetLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppTheme.accentLime)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location, color: AppTheme.accentLime),
                          const SizedBox(width: 8),
                          Text("Enable GPS & Start", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentLime)),
                        ],
                      ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
