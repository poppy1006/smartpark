import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ParkingSlotsPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;

  const ParkingSlotsPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
  });

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  List<Map<String, dynamic>> slots = [];
  bool loading = true;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    fetchSlots();
  }

  // ---------------- FETCH SLOTS ----------------
  Future<void> fetchSlots() async {
    final res = await supabase
        .from('parking_slots')
        .select()
        .eq('parking_id', widget.parkingId)
        .order('slot_code');

    setState(() {
      slots = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  // ---------------- STATUS COLOR ----------------
  Color statusColor(String status) {
    switch (status) {
      case 'free':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ---------------- ADD / EDIT SLOT ----------------
  void openSlotEditor({Map<String, dynamic>? slot}) {
    final codeController =
        TextEditingController(text: slot?['slot_code'] ?? '');
    String status = slot?['status'] ?? 'free';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot == null ? 'Create Slot' : 'Edit Slot',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Slot Code (A1, B2)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('FREE')),
                  DropdownMenuItem(value: 'occupied', child: Text('OCCUPIED')),
                  DropdownMenuItem(value: 'reserved', child: Text('RESERVED')),
                ],
                onChanged: (v) => status = v!,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (codeController.text.trim().isEmpty) return;

                    if (slot == null) {
                      await supabase
                          .from('parking_slots')
                          .insert({
                            'parking_id': widget.parkingId,
                            'slot_code': codeController.text.trim(),
                            'status': status,
                          })
                          .select(); // REQUIRED
                    } else {
                      await supabase.from('parking_slots').update({
                        'slot_code': codeController.text.trim(),
                        'status': status,
                      }).eq('id', slot['id']);
                    }

                    Navigator.pop(context);
                    fetchSlots();
                  },
                  child: Text(slot == null ? 'Create Slot' : 'Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- DELETE SLOT ----------------
  Future<void> deleteSlot(String id) async {
    await supabase.from('parking_slots').delete().eq('id', id);
    fetchSlots();
  }

  void confirmDelete(Map<String, dynamic> slot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text('Delete slot ${slot['slot_code']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteSlot(slot['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.parkingName} Slots'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : slots.isEmpty
              ? _emptyState()
              : _slotsGrid(),
      bottomNavigationBar: _bottomActions(),
    );
  }

  Widget _bottomActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(editMode ? Icons.check : Icons.edit),
              label: Text(editMode ? 'Done Editing' : 'Edit Slots'),
              onPressed: () => setState(() => editMode = !editMode),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Slot'),
              onPressed: () => openSlotEditor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_parking, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No slots created'),
        ],
      ),
    );
  }

  Widget _slotsGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: slots.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final slot = slots[index];

          return GestureDetector(
            onTap: editMode ? () => openSlotEditor(slot: slot) : null,
            onLongPress: editMode ? () => confirmDelete(slot) : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor(slot['status']),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_parking, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          slot['slot_code'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor(slot['status']),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (editMode)
                    const Positioned(
                      bottom: 6,
                      right: 6,
                      child: Icon(Icons.delete, size: 16),
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
