import 'package:flutter/material.dart';
import 'package:smartparking/user/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DummyPaymentPage extends StatefulWidget {
  final String parkingId;
  final String slotId;
  final double amount; // advance = 20

  const DummyPaymentPage({
    super.key,
    required this.parkingId,
    required this.slotId,
    required this.amount,
  });

  @override
  State<DummyPaymentPage> createState() => _DummyPaymentPageState();
}

class _DummyPaymentPageState extends State<DummyPaymentPage> {
  bool _processing = false;

  Future<void> _pay() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now();
      final qrExpiry = now.add(const Duration(minutes: 10));

      /// 1️⃣ CREATE BOOKING (CONFIRMED)
      final booking = await supabase.from('bookings').insert({
        'user_id': userId,
        'parking_id': widget.parkingId,
        'slot_id': widget.slotId,
        'start_time': now.toIso8601String(),
        'status': 'confirmed',
        'qr_expires_at': qrExpiry.toIso8601String(),
      }).select('id').single();

      final bookingId = booking['id'];

      /// 2️⃣ SET QR TOKEN = booking.id
      await supabase.from('bookings').update({
        'qr_token': bookingId,
      }).eq('id', bookingId);

      /// 3️⃣ INSERT ADVANCE PAYMENT (₹20)
      await supabase.from('payments').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'amount': widget.amount,
        'payment_type': 'advance',
        'payment_method': 'upi',
        'payment_status': 'paid',
        'paid_at': now.toIso8601String(),
      });

      /// 4️⃣ RESERVE SLOT
      await supabase
          .from('parking_slots')
          .update({'status': 'reserved'})
          .eq('id', widget.slotId);

      if (!mounted) return;

      setState(() => _processing = false);
      _showSuccessPopup();
    } catch (e) {
      if (!mounted) return;

      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  /// ✅ SUCCESS POPUP + AUTO NAVIGATE HOME
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      /// Close dialog
      Navigator.of(context, rootNavigator: true).pop();

      /// Navigate to HOME and clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserDashboardPage(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: _processing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
                  Text(
                    'Pay ₹${widget.amount}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _pay,
                      child: const Text('Pay ₹20 via UPI'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
