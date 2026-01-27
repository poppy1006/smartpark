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

  // --------------------------------------------------
  // FETCH SLOTS
  // --------------------------------------------------
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

  // --------------------------------------------------
  // STATUS COLOR
  // --------------------------------------------------
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

  // --------------------------------------------------
  // CREATE / EDIT SLOT
  // --------------------------------------------------
  void openSlotEditor({Map<String, dynamic>? slot}) {
    final codeCtrl = TextEditingController(text: slot?['slot_code'] ?? '');
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Slot Code (A1)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'free', child: Text("FREE")),
                  DropdownMenuItem(value: 'occupied', child: Text("OCCUPIED")),
                  DropdownMenuItem(value: 'reserved', child: Text("RESERVED")),
                ],
                onChanged: (v) => status = v!,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text(slot == null ? "Create" : "Update"),
                      onPressed: () async {
                        if (codeCtrl.text.trim().isEmpty) return;

                        try {
                          if (slot == null) {
                            await supabase.from('parking_slots').insert({
                              'parking_id': widget.parkingId,
                              'slot_code': codeCtrl.text.trim().toUpperCase(),
                              'status': status,
                            });
                          } else {
                            await supabase
                                .from('parking_slots')
                                .update({
                                  'slot_code': codeCtrl.text
                                      .trim()
                                      .toUpperCase(),
                                  'status': status,
                                })
                                .eq('id', slot['id']);
                          }

                          Navigator.pop(context);
                          fetchSlots();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Slot already exists"),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  if (slot != null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        confirmDelete(slot);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // BULK CREATION
  // --------------------------------------------------
  void openBulkCreator() {
    final countCtrl = TextEditingController();
    final prefixCtrl = TextEditingController(text: "A");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bulk Slot Creation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prefixCtrl,
              maxLength: 1,
              decoration: const InputDecoration(labelText: "Alphabet"),
            ),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Slots"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Create"),
            onPressed: () async {
              try {
                final count = int.parse(countCtrl.text);
                final prefix = prefixCtrl.text.toUpperCase();

                if (count < 10) {
                  throw "Minimum 10 slots required";
                }

                final existing = await supabase
                    .from('parking_slots')
                    .select('slot_code')
                    .eq('parking_id', widget.parkingId);

                final existingCodes = existing
                    .map((e) => e['slot_code'])
                    .toSet();

                List<Map<String, dynamic>> bulk = [];

                for (int i = 1; i <= count; i++) {
                  final code = "$prefix$i";
                  if (!existingCodes.contains(code)) {
                    bulk.add({
                      'parking_id': widget.parkingId,
                      'slot_code': code,
                      'status': 'free',
                    });
                  }
                }

                if (bulk.isEmpty) {
                  throw "All slots already exist";
                }

                await supabase.from('parking_slots').insert(bulk);

                Navigator.pop(context);
                fetchSlots();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${bulk.length} slots created")),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DELETE
  // --------------------------------------------------
  void confirmDelete(Map slot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Slot"),
        content: Text("Delete slot ${slot['slot_code']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase
                  .from('parking_slots')
                  .delete()
                  .eq('id', slot['id']);

              Navigator.pop(context);
              fetchSlots();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.parkingName} Slots"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openSlotEditor,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: slots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) {
                final slot = slots[i];

                return GestureDetector(
                  onTap: editMode ? () => openSlotEditor(slot: slot) : null,
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
                              const Icon(Icons.local_parking),
                              const SizedBox(height: 6),
                              Text(
                                slot['slot_code'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          top: 6,
                          right: 6,
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
                            child: Icon(Icons.edit, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                child: Text(editMode ? "Done" : "Edit Slots"),
                onPressed: () => setState(() => editMode = !editMode),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                child: const Text("Create Slot"),
                onPressed: () => openBulkCreator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
