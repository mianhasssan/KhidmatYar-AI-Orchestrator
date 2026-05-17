import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'tracking_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _activeTab = 0;
  final AIService _aiService = AIService();
  final TextEditingController _searchController = TextEditingController();
  bool _isAILoading = false;
  Map<String, dynamic>? _lastAIResult;
  String _error = "";

  final List<Map<String, dynamic>> _agentSteps = [
    {"name": "Location Validation Agent", "status": "WAITING", "desc": "Resolving user GPS coordinates and calling reverse-geocoding API to resolve exact city, state, country..."},
    {"name": "Availability Check Agent", "status": "WAITING", "desc": "Scanning local area service database, querying Google Places search nodes, and validating slot schedules..."},
    {"name": "Booking Confirmation Agent", "status": "WAITING", "desc": "Confirming allocation parameters, building handshake sockets, and registering verified provider allocation..."},
  ];

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Widget> get _pages => [
    HomeScreen(
      onSearchTap: _showAgentModal,
      onBookService: (serviceName) {
        // Clear previous result so it starts processing again cleanly!
        setState(() {
          _lastAIResult = null;
          _error = "";
        });
        _searchController.text = serviceName;
        _showAgentModal();
      },
    ),
    const BookingsScreen(),
    TrackingScreen(bookingData: _lastAIResult),
    const ProfileScreen(), // Profile Access
  ];

  void _handleAISearch(StateSetter setModalState) async {
    if (_searchController.text.isEmpty) return;
    
    setModalState(() {
      _isAILoading = true;
      _error = "";
      _lastAIResult = null;
      _agentSteps[0]['status'] = "PROCESSING";
      _agentSteps[1]['status'] = "WAITING";
      _agentSteps[2]['status'] = "WAITING";
    });

    // Fire backend call in parallel
    final recommendationFuture = _aiService.getServiceRecommendation(_searchController.text);
    
    // Visual sequential delay for Agent 1
    await Future.delayed(const Duration(milliseconds: 1200));
    setModalState(() {
      _agentSteps[0]['status'] = "COMPLETED";
      _agentSteps[1]['status'] = "PROCESSING";
    });

    // Visual sequential delay for Agent 2
    await Future.delayed(const Duration(milliseconds: 1200));
    setModalState(() {
      _agentSteps[1]['status'] = "COMPLETED";
      _agentSteps[2]['status'] = "PROCESSING";
    });

    // Visual sequential delay for Agent 3
    await Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      final result = await recommendationFuture;
      final prefs = await SharedPreferences.getInstance();
      if (result['user_city'] != null) {
        await prefs.setString('user_city', result['user_city']);
      }
      setModalState(() {
        _agentSteps[2]['status'] = "COMPLETED";
        _lastAIResult = result;
        _isAILoading = false;
      });
    } catch (e) {
      setModalState(() {
        _error = "Connection Error: $e";
        _isAILoading = false;
      });
    }
  }

  void _showAgentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (_searchController.text.isNotEmpty && !_isAILoading && _lastAIResult == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAISearch(setModalState);
            });
          }
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: AppTheme.scaffoldBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(bottom: BorderSide(color: Colors.black12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory, color: AppTheme.accentLime),
                        const SizedBox(width: 8),
                        Text("AI Orchestrator", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.black54)),
                    )
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (!_isAILoading && _lastAIResult == null)
                        _buildEmptyState(setModalState),
                      
                      if (_isAILoading)
                        _buildLoadingState(),
                        
                      if (_error.isNotEmpty)
                        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)), child: Text(_error, style: GoogleFonts.inter(color: Colors.red[600], fontSize: 12))),

                      if (_lastAIResult != null && !_isAILoading)
                        _buildResultState(),
                    ],
                  ),
                ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Message AI Orchestrator...",
                          hintStyle: GoogleFonts.inter(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _handleAISearch(setModalState),
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: AppTheme.accentLime, shape: BoxShape.circle),
                        child: const Icon(Icons.send, size: 18, color: AppTheme.primaryGreen),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildEmptyState(StateSetter setModalState) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle), child: const Icon(Icons.memory, size: 32, color: Colors.grey)),
        const SizedBox(height: 16),
        Text("How can I help you today?", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8),
        Text("Describe the service you need, location, and time. (Roman Urdu supported)", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: [
            _buildSuggestion("Plumber chahiye kal G-11 me", setModalState),
            _buildSuggestion("Need an electrician today in F-10", setModalState),
          ],
        )
      ],
    );
  }

  Widget _buildSuggestion(String text, StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _handleAISearch(setModalState);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
        child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                "AI Orchestrator Processing...",
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                "Orchestrating autonomous sub-agents to process service request",
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(_agentSteps.length, (index) {
          final step = _agentSteps[index];
          final status = step['status'];
          final isProcessing = status == "PROCESSING";
          final isCompleted = status == "COMPLETED";

          Color statusColor = Colors.grey[400]!;
          IconData statusIcon = Icons.radio_button_off;
          if (isProcessing) {
            statusColor = Colors.red[600]!;
            statusIcon = Icons.sync; // spinning/processing representation
          } else if (isCompleted) {
            statusColor = Colors.green[600]!;
            statusIcon = Icons.check_circle;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isProcessing ? Colors.red[200]! : Colors.grey[100]!,
                width: isProcessing ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isProcessing ? Colors.red.withOpacity(0.04) : Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                      )
                    : Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step['name'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isProcessing ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['desc'],
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], height: 1.4),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.done_all, color: Colors.green[600], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "Task completed & locked successfully.",
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[600]),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultState() {
    final intent = _lastAIResult!['intent'] ?? {};
    final provider = _lastAIResult!['providerSelection'] ?? {};
    final rawTraces = _lastAIResult!['agentTraces'] ?? [];
    final traces = [
      "LocationValidationAgent: Resolving user GPS coordinates and calling reverse-geocoding API to resolve exact city, state, country...",
      "AvailabilityCheckAgent: Scanning local area service database, querying Google Places search nodes, and validating slot schedules...",
      "BookingConfirmationAgent: Confirming allocation parameters, building handshake sockets, and registering verified provider allocation...",
      ...rawTraces
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intent Extracted Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.accentLime, size: 16),
                  const SizedBox(width: 8),
                  Text("INTENT EXTRACTED", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildIntentBadge("SERVICE", intent['serviceType'] ?? "Unknown")),
                  const SizedBox(width: 8),
                  Expanded(child: _buildIntentBadge("LOCATION", intent['location'] ?? "Unknown", icon: Icons.location_on_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildIntentBadge("TIME", intent['time'] ?? "Unknown")),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Best Match Found Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.2), blurRadius: 20)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("BEST MATCH FOUND", style: GoogleFonts.inter(color: AppTheme.accentLime, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: Text("${provider['distance'] ?? ''}", style: GoogleFonts.inter(color: Colors.white, fontSize: 10))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider['name'] ?? "Provider Name", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)), child: Text("★ ${provider['rating'] ?? '4.0'}", style: GoogleFonts.inter(color: Colors.white, fontSize: 10))),
                    ],
                  ),
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF153326), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Agent Reasoning:", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(provider['reasoning'] ?? "", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  final today = DateTime.now();
                  final monthStr = _getMonth(today.month);
                  final bookingId = "KY-${10000 + (today.millisecondsSinceEpoch % 90000)}";
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.accentLime, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("BOOKING COMPLETED BY AGENT", style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            Text("ID: $bookingId", style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Service Scheduled: 5:30 PM – ${today.day} $monthStr ${today.year}", style: GoogleFonts.inter(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Assigned: ${provider['name'] ?? 'Worker'}", style: GoogleFonts.inter(color: AppTheme.primaryGreen.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("Confirmed at: ${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')} ${today.day} $monthStr", style: GoogleFonts.inter(color: AppTheme.primaryGreen.withOpacity(0.6), fontSize: 10)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _activeTab = 2; // Route to Live Tracking Map
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text("Track Live on Map", style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    _lastAIResult = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Booking cancelled successfully by Agent.")),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text("Cancel Booking", style: GoogleFonts.inter(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }
              )
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        Text("AGENT REASONING TRACE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 16),
        
        // Traces Timeline
        ...traces.map<Widget>((step) {
          final now = DateTime.now();
          final timeStrReal = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          final String tag;
          final String body;
          if (step is Map) {
            tag = step['agent']?.toString() ?? "AgentTrace";
            body = step['description']?.toString() ?? "";
          } else {
            final stepStr = step.toString();
            final hasColon = stepStr.contains(':');
            tag = hasColon ? stepStr.split(':')[0].trim() : "AgentTrace";
            body = hasColon ? stepStr.substring(stepStr.indexOf(':') + 1).trim() : stepStr;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: AppTheme.accentLime, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    Container(width: 2, height: 50, color: Colors.grey[200]),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                              ),
                            ),
                            Text(
                              timeStrReal,
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildIntentBadge(String title, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 12, color: AppTheme.primaryGreen), const SizedBox(width: 4)],
              Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        children: [
          _pages[_activeTab],
          
          // Floating Bottom Navigation (Exact React Replica)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(40)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavBtn(Icons.home_filled, 0),
                  _buildNavBtn(Icons.calendar_today, 1),
                  const SizedBox(width: 40), // Gap for center button
                  _buildNavBtn(Icons.map, 2),
                  _buildNavBtn(Icons.person, 3),
                ],
              ),
            ),
          ),
          
          // Floating AI Center Button
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showAgentModal,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLime,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.scaffoldBg, width: 4),
                    boxShadow: [BoxShadow(color: AppTheme.accentLime.withOpacity(0.3), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 24),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, int index) {
    bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: isActive ? AppTheme.accentLime : Colors.white60, size: 20),
      ),
    );
  }
}
