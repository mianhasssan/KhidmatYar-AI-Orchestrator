import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const TrackingScreen({super.key, this.bookingData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  LatLng _userLocation = const LatLng(33.6844, 73.0479); // Default Islamabad
  LatLng _providerLocation = const LatLng(33.6934, 73.0589);
  bool _isLoading = true;
  bool _hasActiveBooking = false;
  Map<String, dynamic>? _activeBooking;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_lat');
    final lng = prefs.getDouble('user_lng');

    setState(() {
      if (lat != null && lng != null) {
        _userLocation = LatLng(lat, lng);
        _providerLocation = LatLng(lat + 0.005, lng + 0.005); // Offset provider slightly for realistic marker mapping
      }
      _isLoading = false;

      // Check if we received booking data from the AI Orchestrator
      if (widget.bookingData != null) {
        _activeBooking = widget.bookingData;
        _hasActiveBooking = true;

        final pLat = widget.bookingData?['provider_lat'];
        final pLng = widget.bookingData?['provider_lng'];
        if (pLat != null && pLng != null) {
          _providerLocation = LatLng(pLat, pLng);
        }

        final uLat = widget.bookingData?['user_lat'];
        final uLng = widget.bookingData?['user_lng'];
        if (uLat != null && uLng != null) {
          _userLocation = LatLng(uLat, uLng);
        }
      }
    });

    // Move camera to user location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation, zoom: 14.5),
        ),
      );
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _cancelActiveBooking() {
    setState(() {
      _hasActiveBooking = false;
      _activeBooking = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking cancelled successfully by Agent.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    final providerName = _activeBooking?['providerSelection']?['name'] ?? "Provider";
    final distance = _activeBooking?['providerSelection']?['distance'] ?? "1.8 km";
    final rating = _activeBooking?['providerSelection']?['rating']?.toString() ?? "4.8";
    final service = _activeBooking?['intent']?['serviceType'] ?? "AC Technician";
    final today = DateTime.now();
    final formattedDate = "${today.day} ${_getMonth(today.month)}, ${today.year}";
    
    // Dynamic booking display time
    final rawTime = _activeBooking?['intent']?['time'] ?? "As soon as possible";
    String displayTime = rawTime;
    if (rawTime.toLowerCase() == "now" || rawTime.toLowerCase() == "as soon as possible") {
      displayTime = "Tomorrow ($formattedDate) at 10:00 AM";
    } else {
      displayTime = rawTime;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map (occupies full screen but with adjusted padding so bottom card doesn't cover controls)
          Positioned.fill(
            bottom: _hasActiveBooking ? 340 : 120, // Add bottom margin to map viewport so zoom/controls aren't covered!
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation,
                zoom: 14.5,
              ),
              zoomControlsEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('user_location'),
                  position: _userLocation,
                  infoWindow: const InfoWindow(title: "Your Live Location"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
                if (_hasActiveBooking)
                  Marker(
                    markerId: const MarkerId('provider_location'),
                    position: _providerLocation,
                    infoWindow: InfoWindow(title: providerName, snippet: service),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
              },
            ),
          ),

          // Header Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate back to Tab 0 (Home) in main navigation
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _hasActiveBooking ? "Live Provider Tracking" : "Discovery Map Center",
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        _hasActiveBooking ? "Order #AC-8849" : "Pick locations via GPS",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const Icon(Icons.my_location, color: AppTheme.primaryGreen, size: 20),
                ],
              ),
            ),
          ),

          // Bottom Sheet Information (Conditional Rendering)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 110), // Safe spacing for Floating Nav Bar
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: Offset(0, -10))],
              ),
              child: _hasActiveBooking
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 16),
                        
                        // Status Card
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Booking Confirmed by Agent",
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  Text(
                                    "Scheduled for $displayTime",
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Provider Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    "https://api.dicebear.com/7.x/avataaars/png?seed=$providerName",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(providerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _activeBooking?['providerSelection']?['address'] ?? "Nearest Location",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Text("★ $rating", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[700])),
                                        ),
                                        const SizedBox(width: 6),
                                        Text("• $service • $distance", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showChatModal(context, providerName);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Call placed to worker...")),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: Color(0xFF0F3E2E), shape: BoxShape.circle),
                                  child: const Icon(Icons.phone, size: 18, color: AppTheme.accentLime),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showUrgentAlert(context, service),
                                child: _buildActionButton(Icons.shield_outlined, "Urgent", Colors.red[50]!, Colors.red[600]!, Colors.red[100]!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showRescheduleSheet(context),
                                child: _buildActionButton(Icons.calendar_month, "Reschedule", Colors.orange[50]!, Colors.orange[600]!, Colors.orange[100]!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _cancelActiveBooking,
                                child: _buildActionButton(Icons.cancel_outlined, "Cancel Booking", Colors.grey[100]!, Colors.grey[700]!, Colors.grey[300]!),
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
                              child: const Icon(Icons.info_outline, color: Colors.amber),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "No Active Bookings",
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Use the Floating AI Orchestrator button below to search and confirm a provider!",
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  void _showUrgentAlert(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                  child: Icon(Icons.emergency_share, color: Colors.red[600], size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  "URGENT REQUEST DETECTED",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red[600], letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to upgrade your booking for $serviceName to URGENT priority?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Estimated Dispatch", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("Arriving in 12 - 15 Mins", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✓ Emergency alert dispatched! Worker is enroute.")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text("Dispatch Now", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRescheduleSheet(BuildContext context) {
    int selectedDayIndex = 0;
    int selectedSlotIndex = 1;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final nextDays = List.generate(5, (index) => DateTime.now().add(Duration(days: index)));
            final slots = [
              {"time": "10:00 AM", "status": "Available"},
              {"time": "12:00 PM", "status": "Available"},
              {"time": "02:00 PM", "status": "Unavailable"},
              {"time": "04:00 PM", "status": "Available"},
            ];

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 16),
                  Text("Reschedule Service", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Text("Select Date", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: nextDays.length,
                      itemBuilder: (context, index) {
                        final date = nextDays[index];
                        final isSelected = selectedDayIndex == index;
                        final dayName = _getMonth(date.month);
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedDayIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryGreen : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey[200]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${date.day}",
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black),
                                ),
                                Text(
                                  dayName,
                                  style: GoogleFonts.inter(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text("Select Available Time Slot", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(slots.length, (index) {
                      final slot = slots[index];
                      final isUnavailable = slot['status'] == "Unavailable";
                      final isSelected = selectedSlotIndex == index && !isUnavailable;

                      return GestureDetector(
                        onTap: isUnavailable
                            ? null
                            : () {
                                setSheetState(() {
                                  selectedSlotIndex = index;
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentLime
                                : (isUnavailable ? Colors.grey[100] : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentLime
                                  : (isUnavailable ? Colors.grey[200]! : Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            slot['time']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnavailable
                                  ? Colors.grey[400]
                                  : (isSelected ? AppTheme.primaryGreen : Colors.black),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final targetDate = nextDays[selectedDayIndex];
                        final targetSlot = slots[selectedSlotIndex]['time'];
                        Navigator.pop(context);
                        
                        setState(() {
                          if (_activeBooking != null) {
                            _activeBooking!['intent']['time'] = "${targetDate.day} ${_getMonth(targetDate.month)} at $targetSlot";
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primaryGreen,
                            content: Text(
                              "✓ Service successfully rescheduled for ${targetDate.day} ${_getMonth(targetDate.month)} ${targetDate.year} at $targetSlot!",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.accentLime),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Confirm Rescheduling", style: GoogleFonts.inter(color: AppTheme.accentLime, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChatModal(BuildContext context, String providerName) {
    List<Map<String, String>> chatMessages = [
      {"sender": "worker", "time": "10:02 AM", "text": "Assalam-o-Alaikum! I have accepted your service request and will reach your location on time."},
      {"sender": "user", "time": "10:03 AM", "text": "Walaikum Assalam. Great, thank you. Please make sure to bring your standard service kit."},
      {"sender": "worker", "time": "10:04 AM", "text": "Ji bilkul, I have all professional tools prepared. See you tomorrow!"},
    ];
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setChatState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // Handle
                    Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(providerName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                              Text("Active Chat Session • Online", style: GoogleFonts.inter(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(height: 24),
                    // Messages list
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];
                          final isUser = msg["sender"] == "user";
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? AppTheme.primaryGreen : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                                  bottomRight: Radius.circular(isUser ? 0 : 20),
                                ),
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              child: Column(
                                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg["text"]!,
                                    style: GoogleFonts.inter(fontSize: 13, color: isUser ? Colors.white : Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg["time"]!,
                                    style: GoogleFonts.inter(fontSize: 8, color: isUser ? Colors.white70 : Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Input bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: textController,
                                decoration: InputDecoration(
                                  hintText: "Type message in Roman Urdu or English...",
                                  hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (textController.text.trim().isNotEmpty) {
                                final now = DateTime.now();
                                final timeStr = "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
                                setChatState(() {
                                  chatMessages.add({
                                    "sender": "user",
                                    "time": timeStr,
                                    "text": textController.text.trim(),
                                  });
                                });
                                final userMsg = textController.text.trim();
                                textController.clear();
                                
                                // Auto-simulate a friendly reply from the worker after 1.5 seconds!
                                Future.delayed(const Duration(milliseconds: 1500), () {
                                  if (context.mounted) {
                                    setChatState(() {
                                      chatMessages.add({
                                        "sender": "worker",
                                        "time": timeStr,
                                        "text": "Ji bilkul, perfect ho gya! Shukurya.",
                                      });
                                    });
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send, color: AppTheme.accentLime, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color bgColor, Color fgColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Icon(icon, color: fgColor, size: 20),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: fgColor)),
        ],
      ),
    );
  }
}
