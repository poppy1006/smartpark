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
  Timer? _timer;

  static const double advancePaid = 20;

  @override
  void initState() {
    super.initState();
    _fetchBookings();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
  }

  Map<String, dynamic> _calculateBilling(
    DateTime startTime,
    double hourlyPrice,
  ) {
    final now = DateTime.now();
    final minutesUsed = now.difference(startTime).inMinutes.clamp(1, 100000);
    final hoursUsed = (minutesUsed / 60).ceil();

    final total = hoursUsed * hourlyPrice;
    final balance = (total - advancePaid).clamp(0, double.infinity);

    return {
      'duration': Duration(minutes: minutesUsed),
      'hoursUsed': hoursUsed,
      'total': total,
      'balance': balance,
    };
  }

  Future<void> _refundAdvance(Map booking) async {
    final bookingId = booking['id'];

    await supabase
        .from('payments')
        .update({'payment_status': 'failed'})
        .eq('booking_id', bookingId)
        .eq('payment_type', 'advance');

    await supabase
        .from('parking_slots')
        .update({'status': 'free'})
        .eq('id', booking['slot_id']);

    await supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);

    _fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: const UserBottomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];

                final String status = booking['status'] ?? 'unknown';
                final String? qrToken = booking['qr_token'];

                final DateTime createdAt =
                    DateTime.parse(booking['created_at']).toLocal();

                final DateTime? startTime = booking['start_time'] != null
                    ? DateTime.parse(booking['start_time']).toLocal()
                    : null;

                final DateTime? expiresAt = booking['qr_expires_at'] != null
                    ? DateTime.parse(booking['qr_expires_at']).toLocal()
                    : null;

                final bool isExpired =
                    expiresAt != null && DateTime.now().isAfter(expiresAt);

                final parking = booking['parkings'] ?? {};
                final String parkingName =
                    parking['name'] ?? 'Unknown Parking';

                final double hourlyPrice =
                    parking['hourly_price'] != null
                        ? (parking['hourly_price'] as num).toDouble()
                        : 0;

                final Map<String, dynamic>? billing =
                    (status == 'parked' && startTime != null)
                        ? _calculateBilling(startTime, hourlyPrice)
                        : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parkingName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),
                        Text('Status: $status',
                            style:
                                const TextStyle(color: Colors.grey)),

                        const SizedBox(height: 12),

                        /// ENTRY QR
                        if (status == 'pending' &&
                            qrToken != null &&
                            !isExpired &&
                            expiresAt != null) ...[
                          Text(
                            '⏳ Entry QR expires in ${_formatDuration(expiresAt.difference(DateTime.now()))}',
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: QrImageView(
                              data: qrToken,
                              size: 180,
                            ),
                          ),
                        ],

                        /// ENTRY EXPIRED
                        if (status == 'pending' && isExpired) ...[
                          const Text(
                            '⛔ Entry QR expired',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _refundAdvance(booking),
                            child: const Text('Refund ₹20'),
                          ),
                        ],

                        /// PARKED
                        if (status == 'parked' && billing != null) ...[
                          Text(
                              '⏱ Time Used: ${_formatDuration(billing['duration'])}'),
                          Text('💸 Hourly Rate: ₹$hourlyPrice'),
                          Text(
                            '💰 Total: ₹${billing['total']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '💳 Balance: ₹${billing['balance']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],

                        /// EXIT QR
                        if (status == 'exit_pending' &&
                            qrToken != null) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: QrImageView(
                              data: qrToken,
                              size: 180,
                            ),
                          ),
                        ],

                        /// COMPLETED
                        if (status == 'completed')
                          const Text(
                            '✅ Parking completed',
                            style:
                                TextStyle(fontWeight: FontWeight.bold),
                          ),

                        /// CANCELLED
                        if (status == 'cancelled')
                          const Text(
                            '❌ Booking cancelled & refunded',
                            style: TextStyle(color: Colors.red),
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
