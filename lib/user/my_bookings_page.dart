import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

final supabase = Supabase.instance.client;

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _bookings = [];

  Timer? _billingTimer;
  Timer? _liveTimer;

  static const double advancePaid = 20;

  @override
  void initState() {
    super.initState();
    _fetchBookings();

    /// Billing refresh
    _billingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );

    /// QR & status refresh
    _liveTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshLatestBooking(),
    );
  }

  @override
  void dispose() {
    _billingTimer?.cancel();
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('bookings')
        .select('''
          id,
          created_at,
          start_time,
          qr_expires_at,
          status,
          qr_token,
          slot_id,
          parkings (
            name,
            hourly_price
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    setState(() {
      _bookings = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  Future<void> _refreshLatestBooking() async {
    if (_bookings.isEmpty) return;

    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('bookings')
        .select('''
          id,
          created_at,
          start_time,
          qr_expires_at,
          status,
          qr_token,
          slot_id,
          parkings (
            name,
            hourly_price
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res != null && mounted) {
      setState(() {
        _bookings[0] = res;
      });
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> _calculateBilling(
    DateTime startTime,
    double hourlyPrice,
  ) {
    final minutes = DateTime.now()
        .difference(startTime)
        .inMinutes
        .clamp(1, 999999);

    final hoursUsed = (minutes / 60).ceil();
    final total = hoursUsed * hourlyPrice;
    final balance = (total - advancePaid).clamp(0, double.infinity);

    return {
      "duration": Duration(minutes: minutes),
      "hoursUsed": hoursUsed,
      "total": total,
      "balance": balance,
    };
  }

  Future<void> _showPayNowPopup(Map booking, double balance) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Pay ₹$balance to generate Exit QR"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Pay Now"),
            onPressed: () async {
              Navigator.pop(context);

              final bookingId = booking['id'];
              final userId = supabase.auth.currentUser!.id;
              final now = DateTime.now().toIso8601String();

              /// Save balance payment
              await supabase.from('payments').insert({
                'booking_id': bookingId,
                'user_id': userId,
                'amount': balance,
                'payment_type': 'balance',
                'payment_method': 'upi',
                'payment_status': 'paid',
                'paid_at': now,
              });

              /// Generate EXIT QR
              await supabase
                  .from('bookings')
                  .update({'status': 'exit_pending', 'qr_token': bookingId})
                  .eq('id', bookingId);

              _refreshLatestBooking();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: const UserBottomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const Center(child: Text("No bookings found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final b = _bookings[index];

                final status = b['status'];
                final qr = b['qr_token'];

                final createdAt = DateTime.parse(b['created_at']).toLocal();

                final startTime = b['start_time'] != null
                    ? DateTime.parse(b['start_time']).toLocal()
                    : null;

                final expiresAt = b['qr_expires_at'] != null
                    ? DateTime.parse(b['qr_expires_at']).toLocal()
                    : null;

                final parking = b['parkings'];
                final name = parking['name'];
                final hourly = (parking['hourly_price'] as num).toDouble();

                final billing = (status == 'parked' && startTime != null)
                    ? _calculateBilling(startTime, hourly)
                    : null;

                final isExpired =
                    expiresAt != null && DateTime.now().isAfter(expiresAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Text("Status: $status"),

                        const SizedBox(height: 12),

                        /// ENTRY QR
                        if (status == 'pending' &&
                            qr != null &&
                            !isExpired &&
                            expiresAt != null) ...[
                          Text(
                            "Entry QR expires in: "
                            "${_formatDuration(expiresAt.difference(DateTime.now()))}",
                          ),
                          const SizedBox(height: 10),
                          Center(child: QrImageView(data: qr, size: 180)),
                        ],

                        /// PARKED
                        if (status == 'parked' && billing != null) ...[
                          Text(
                            "Time Used: ${_formatDuration(billing['duration'])}",
                          ),
                          Text("Hourly Rate: ₹$hourly"),
                          Text(
                            "Total: ₹${billing['total']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Balance: ₹${billing['balance']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showPayNowPopup(b, billing['balance']),
                              child: const Text("Pay Now"),
                            ),
                          ),
                        ],

                        /// EXIT QR
                        if (status == 'exit_pending' && qr != null) ...[
                          const Text(
                            "Exit QR",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Center(child: QrImageView(data: qr, size: 180)),
                        ],

                        /// COMPLETED
                        if (status == 'completed')
                          const Text(
                            "Parking Completed",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
