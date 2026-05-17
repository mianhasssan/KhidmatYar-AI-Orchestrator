import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

// --- PERSONAL INFO SCREEN ---
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String _name = "Loading...";
  String _phone = "Loading...";
  String _location = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? "Guest User";
      _phone = prefs.getString('user_phone') ?? "Not Provided";
      final lat = prefs.getDouble('user_lat');
      final lng = prefs.getDouble('user_lng');
      if (lat != null && lng != null) {
        _location = "GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
      } else {
        _location = "Location Not Enabled";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("Personal Info", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildTextField("Full Name", _name),
          const SizedBox(height: 16),
          _buildTextField("Phone Number", _phone),
          const SizedBox(height: 16),
          _buildTextField("Live GPS Location", _location),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("Save Changes", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentLime)),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        )
      ],
    );
  }
}

// --- PAYMENT METHODS SCREEN ---
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: Text("Payment Methods", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Linked Cards", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2B5876), Color(0xFF4E4376)]),
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.credit_card, color: Colors.white), Text("VISA", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
                  const SizedBox(height: 24),
                  Text("**** **** **** 1234", style: GoogleFonts.inter(color: Colors.white, fontSize: 22, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Card Holder", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)), Text("Expires", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("GUEST USER", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)), Text("12/26", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("Add New Method", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Card Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card Verified and Added successfully!")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Save Payment Method", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- APP SETTINGS SCREEN ---
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: Text("App Settings", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSwitchTile("Push Notifications", true),
          _buildSwitchTile("SMS Alerts", true),
          _buildSwitchTile("Location Services", true),
          _buildSwitchTile("Dark Mode", false),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          Switch(value: value, onChanged: (v){}, activeColor: AppTheme.accentLime, activeTrackColor: AppTheme.primaryGreen),
        ],
      ),
    );
  }
}

// --- HELP & SUPPORT SCREEN ---
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: Text("Help & Support", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text("How can we help you?", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
          const SizedBox(height: 24),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe your issue here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support Ticket #8849 Submitted! We will contact you soon.")));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text("Submit Ticket", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          Text("Frequently Asked Questions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFAQ("How do I cancel a booking?", "You can cancel a booking from the Bookings tab up to 2 hours before the scheduled time."),
          const SizedBox(height: 8),
          _buildFAQ("Is my payment secure?", "Yes, we use bank-level encryption for all transactions."),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(answer, style: GoogleFonts.inter(color: Colors.grey[600])))],
    );
  }
}

// --- SPENDING ANALYTICS SCREEN ---
class SpendingAnalyticsScreen extends StatelessWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Spending Analytics",
          style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Total Spent Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TOTAL AMOUNT SPENT", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text("PKR 128,450", style: GoogleFonts.inter(color: AppTheme.accentLime, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Monthly Spending", style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text("PKR 24,500", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                      child: Text("+12% vs last month", style: GoogleFonts.inter(color: AppTheme.accentLime, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Service-wise spending progress bars
          Text("Service Breakdown", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
            child: Column(
              children: [
                _buildBreakdownItem("AC Maintenance", 0.35, "PKR 45,000", Colors.blue),
                const SizedBox(height: 16),
                _buildBreakdownItem("Electrical Works", 0.25, "PKR 32,000", Colors.orange),
                const SizedBox(height: 16),
                _buildBreakdownItem("Plumbing Systems", 0.20, "PKR 25,000", Colors.green),
                const SizedBox(height: 16),
                _buildBreakdownItem("General Home Care", 0.20, "PKR 26,450", Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions List
          Text("Recent Payments", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
            child: Column(
              children: [
                _buildTxItem("Ali AC Repairing", "PKR 8,500", "15 May 2026", Icons.ac_unit, Colors.blue),
                Divider(height: 1, color: Colors.grey[100]),
                _buildTxItem("Ibrahim Electrician", "PKR 4,200", "12 May 2026", Icons.electrical_services, Colors.orange),
                Divider(height: 1, color: Colors.grey[100]),
                _buildTxItem("Zubair Plumbers", "PKR 3,500", "08 May 2026", Icons.plumbing, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String title, double pct, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[100],
            color: color,
            minHeight: 6,
          ),
        )
      ],
    );
  }

  Widget _buildTxItem(String name, String amount, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(date, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700])),
        ],
      ),
    );
  }
}

// --- BOOKINGS HISTORY SCREEN ---
class BookingsHistoryDummyScreen extends StatelessWidget {
  const BookingsHistoryDummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text("Booking History", style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHistoryCard("AC Deep Cleaning", "Ali AC Repairing", "PKR 4,500", "Completed on 15 May 2026", Colors.green),
          _buildHistoryCard("Ceiling Fan Repairing", "Ibrahim Electrician", "PKR 1,800", "Completed on 12 May 2026", Colors.green),
          _buildHistoryCard("Kitchen Pipe Leakage", "Zubair Plumber", "PKR 2,400", "Completed on 08 May 2026", Colors.green),
          _buildHistoryCard("Urgent AC Gas Refilling", "Khan Cool Air", "PKR 8,500", "Cancelled on 05 May 2026", Colors.red),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(String service, String provider, String price, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.history_toggle_off, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(provider, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          ),
          Text(price, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }
}
