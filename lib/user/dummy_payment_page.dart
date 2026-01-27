import 'package:flutter/material.dart';
import 'package:smartparking/user/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DummyPaymentPage extends StatefulWidget {
  final String parkingId;
  final String slotId;

  const DummyPaymentPage({
    super.key,
    required this.parkingId,
    required this.slotId,
  });

  @override
  State<DummyPaymentPage> createState() => _DummyPaymentPageState();
}

class _DummyPaymentPageState extends State<DummyPaymentPage> {
  bool _processing = false;
  static const double advanceAmount = 20;

  Future<void> _payAdvance() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      /// ALWAYS STORE UTC IN DB
      final nowUtc = DateTime.now().toUtc();
      final qrExpiryUtc = nowUtc.add(const Duration(minutes: 10));

      /// CREATE BOOKING
      final booking = await supabase
          .from('bookings')
          .insert({
            'user_id': userId,
            'parking_id': widget.parkingId,
            'slot_id': widget.slotId,

            /// required column (temporary – worker will overwrite on entry scan)
            'start_time': nowUtc.toIso8601String(),

            'status': 'pending',
            'qr_expires_at': qrExpiryUtc.toIso8601String(),
          })
          .select()
          .single();

      final bookingId = booking['id'];

      /// ENTRY QR = booking.id
      await supabase
          .from('bookings')
          .update({'qr_token': bookingId})
          .eq('id', bookingId);

      /// ADVANCE PAYMENT
      await supabase.from('payments').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'amount': advanceAmount,
        'payment_type': 'advance',
        'payment_method': 'upi',
        'payment_status': 'paid',
        'paid_at': nowUtc.toIso8601String(),
      });

      /// RESERVE SLOT
      await supabase
          .from('parking_slots')
          .update({'status': 'reserved'})
          .eq('id', widget.slotId);

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text(
              'Advance Paid!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('ENTRY QR generated'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboardPage()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Advance'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: _processing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing payment...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 80),
                  const SizedBox(height: 20),
                  const Text('Advance Amount'),
                  const SizedBox(height: 6),
                  const Text(
                    '₹20.00',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _payAdvance,
                      child: const Text('Pay ₹20 via UPI'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
