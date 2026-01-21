import 'package:flutter/material.dart';
import 'package:smartparking/user/widgets/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartparking/user/booking_details_page.dart';

final supabase = Supabase.instance.client;

class AvailableSlotsPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;
  final double hourlyPrice;

  const AvailableSlotsPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.hourlyPrice,
  });

  @override
  State<AvailableSlotsPage> createState() => _AvailableSlotsPageState();
}

class _AvailableSlotsPageState extends State<AvailableSlotsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final res = await supabase
        .from('parking_slots')
        .select('id, slot_code')
        .eq('parking_id', widget.parkingId)
        .eq('status', 'free');

    setState(() {
      _slots = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Slots'),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: UserBottomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _slots.isEmpty
              ? const Center(child: Text('No slots available'))
              : ListView.builder(
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    final slot = _slots[index];

                    return ListTile(
                      leading: const Icon(Icons.local_parking),
                      title: Text('Slot ${slot['slot_code']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsPage(
                              parkingId: widget.parkingId,
                              parkingName: widget.parkingName,
                              slotId: slot['id'],
                              slotCode: slot['slot_code'],
                              hourlyPrice: widget.hourlyPrice,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
