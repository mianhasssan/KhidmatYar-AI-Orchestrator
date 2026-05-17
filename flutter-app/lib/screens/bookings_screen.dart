import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _activeTab = 0; // 0 = Upcoming, 1 = Completed, 2 = Cancelled

  // Manage bookings dynamically so Cancel works!
  List<Map<String, dynamic>> _upcomingBookings = [
    {
      "name": "Ali AC Services",
      "service": "AC Technician",
      "date": "Tomorrow",
      "time": "10:00 AM",
      "location": "G-13, Islamabad",
      "status": "PENDING ARRIVAL",
      "statusColor": Colors.orange,
      "isTracking": true,
    },
    {
      "name": "Ibrahim Electrician",
      "service": "Electrician",
      "date": "29 Jan, 2024",
      "time": "04:00 PM",
      "location": "F-10/2, Islamabad",
      "status": "SCHEDULED",
      "statusColor": Colors.blue,
      "isTracking": false,
    }
  ];

  final List<Map<String, dynamic>> _completedBookings = [
    {
      "name": "Zubair Cool Services",
      "service": "AC Repair",
      "date": "15 Jan, 2024",
      "time": "11:00 AM",
      "location": "G-11, Islamabad",
      "status": "COMPLETED",
      "statusColor": Colors.green,
    },
    {
      "name": "Khan Plumber Store",
      "service": "Plumbing",
      "date": "10 Jan, 2024",
      "time": "02:00 PM",
      "location": "I-8, Islamabad",
      "status": "COMPLETED",
      "statusColor": Colors.green,
    },
    {
      "name": "Imtiaz Super Cleaners",
      "service": "Cleaning",
      "date": "05 Jan, 2024",
      "time": "09:00 AM",
      "location": "E-11, Islamabad",
      "status": "COMPLETED",
      "statusColor": Colors.green,
    }
  ];

  final List<Map<String, dynamic>> _cancelledBookings = [
    {
      "name": "Asif Carpenter",
      "service": "Carpentry",
      "date": "02 Jan, 2024",
      "time": "03:30 PM",
      "location": "F-8, Islamabad",
      "status": "CANCELLED",
      "statusColor": Colors.red,
    },
    {
      "name": "Saeed Electrician",
      "service": "Electrician",
      "date": "28 Dec, 2023",
      "time": "10:00 AM",
      "location": "H-13, Islamabad",
      "status": "CANCELLED",
      "statusColor": Colors.red,
    }
  ];

  void _cancelBooking(int index) {
    setState(() {
      final cancelled = _upcomingBookings.removeAt(index);
      cancelled['status'] = 'CANCELLED';
      cancelled['statusColor'] = Colors.red;
      cancelled['isTracking'] = false;
      _cancelledBookings.add(cancelled);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking cancelled successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList = [];
    if (_activeTab == 0) currentList = _upcomingBookings;
    if (_activeTab == 1) currentList = _completedBookings;
    if (_activeTab == 2) currentList = _cancelledBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Bookings", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTab("Upcoming", 0),
                  _buildTab("Completed", 1),
                  _buildTab("Cancelled", 2),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: currentList.isEmpty
                  ? Center(child: Text("No bookings here", style: GoogleFonts.inter(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final booking = currentList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildBookingCard(
                            index: index,
                            status: booking['status'],
                            statusColor: booking['statusColor'],
                            name: booking['name'],
                            service: booking['service'],
                            date: booking['date'],
                            time: booking['time'],
                            location: booking['location'],
                            isTracking: booking['isTracking'] ?? false,
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, int tabIndex) {
    bool isActive = _activeTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required int index,
    required String status,
    required Color statusColor,
    required String name,
    required String service,
    required String date,
    required String time,
    required String location,
    required bool isTracking,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              CircleAvatar(backgroundColor: Colors.lime[100], radius: 18, child: Image.network("https://api.dicebear.com/7.x/avataaars/png?seed=$name", width: 30)),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black)),
          Text(service, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
            child: Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(location, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))]),
          ),
          if (_activeTab == 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(index),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency flag sent to technician!")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Urgent Alert", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
