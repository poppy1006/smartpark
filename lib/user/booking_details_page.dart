import 'package:flutter/material.dart';
import 'package:smartparking/user/dummy_payment_page.dart';

class BookingDetailsPage extends StatelessWidget {
  final String parkingId;
  final String parkingName;
  final String slotId;
  final String slotCode;
  final double hourlyPrice;

  const BookingDetailsPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.slotId,
    required this.slotCode,
    required this.hourlyPrice,
  });

  static const double advanceAmount = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parkingName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Slot: $slotCode'),
            const SizedBox(height: 8),
            Text('Hourly Price: ₹$hourlyPrice'),
            const Divider(height: 30),
            const Text(
              'Advance Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('₹20 (slot lock fee)'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                child: const Text('Pay ₹20 & Confirm Slot'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DummyPaymentPage(
                        parkingId: parkingId,
                        slotId: slotId,
                        // amount: advanceAmount,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
