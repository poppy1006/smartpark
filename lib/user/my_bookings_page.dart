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

  /// Cache start times (IMPORTANT)
  final Map<String, DateTime> _startTimes = {};

  Timer? _uiTimer;
  Timer? _dbTimer;

  static const double advancePaid = 20;

  // -------------------------------
  @override
  void initState() {
    super.initState();
    _fetchBookings();

    /// UI tick every second
    _uiTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );

    /// DB refresh every 5 seconds
    _dbTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLatestBooking(),
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _dbTimer?.cancel();
    super.dispose();
  }

  // -------------------------------
  Future<void> _fetchBookings() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase.from('bookings').select('''
      id,
      start_time,
      status,
      qr_token,
      parkings(name, hourly_price)
    ''').eq('user_id', userId).order('created_at', ascending: false);

    _bookings = List<Map<String, dynamic>>.from(res);

    /// CACHE START TIMES
    for (final b in _bookings) {
      if (b['start_time'] != null) {
        _startTimes[b['id']] =
            DateTime.parse(b['start_time']).toLocal();
      }
    }

    setState(() => _loading = false);
  }

  // -------------------------------
  Future<void> _refreshLatestBooking() async {
    if (_bookings.isEmpty) return;

    final userId = supabase.auth.currentUser!.id;

    final res = await supabase.from('bookings').select('''
      id,
      start_time,
      status,
      qr_token,
      parkings(name, hourly_price)
    ''').eq('user_id', userId).order('created_at', ascending: false).limit(1).maybeSingle();

    if (res == null) return;

    _bookings[0] = res;

    /// Only save start_time once
    if (res['start_time'] != null &&
        !_startTimes.containsKey(res['id'])) {
      _startTimes[res['id']] =
          DateTime.parse(res['start_time']).toLocal();
    }

    setState(() {});
  }

  // -------------------------------
  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;

    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  // -------------------------------
  Map<String, dynamic> _billing(DateTime start, double rate) {
    final seconds =
        DateTime.now().difference(start).inSeconds;

    final hours = (seconds / 3600).ceil();
    final total = hours * rate;
    final balance = (total - advancePaid).clamp(0, double.infinity);

    return {
      "duration": Duration(seconds: seconds),
      "total": total,
      "balance": balance,
    };
  }

  // -------------------------------
  Future<void> _payNow(Map booking, double amount) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Pay ₹$amount to generate Exit QR"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Pay Now"),
            onPressed: () async {
              Navigator.pop(context);

              final id = booking['id'];
              final uid = supabase.auth.currentUser!.id;

              await supabase.from('payments').insert({
                'booking_id': id,
                'user_id': uid,
                'amount': amount,
                'payment_type': 'balance',
                'payment_status': 'paid',
              });

              await supabase.from('bookings').update({
                'status': 'exit_pending',
                'qr_token': id,
              }).eq('id', id);
            },
          )
        ],
      ),
    );
  }

  // -------------------------------
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (_, i) {
                final b = _bookings[i];
                final status = b['status'];
                final qr = b['qr_token'];

                final parking = b['parkings'];
                final name = parking['name'];
                final hourly =
                    (parking['hourly_price'] as num).toDouble();

                final start = _startTimes[b['id']];
                final bill =
                    (status == 'parked' && start != null)
                        ? _billing(start, hourly)
                        : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text("Status: $status"),
                        const SizedBox(height: 12),

                        /// PARKED
                        if (bill != null) ...[
                          Text("⏱ Time Used: ${_format(bill['duration'])}"),
                          Text("💸 Hourly Rate: ₹$hourly"),
                          Text("💰 Total: ₹${bill['total']}"),
                          Text("💳 Balance: ₹${bill['balance']}"),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () =>
                                _payNow(b, bill['balance']),
                            child: const Text("Pay Now"),
                          ),
                        ],

                        /// EXIT QR
                        if (status == 'exit_pending' &&
                            qr != null) ...[
                          const SizedBox(height: 10),
                          Center(
                            child:
                                QrImageView(data: qr, size: 180),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
