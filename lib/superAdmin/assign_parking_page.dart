import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AssignParkingPage extends StatefulWidget {
  final String adminId;

  const AssignParkingPage({super.key, required this.adminId});

  @override
  State<AssignParkingPage> createState() => _AssignParkingPageState();
}

class _AssignParkingPageState extends State<AssignParkingPage> {
  List parkings = [];
  Set selected = {};

  @override
  void initState() {
    super.initState();
    _loadParkings();
  }

  Future<void> _loadParkings() async {
    final res = await supabase.from('parkings').select();
    setState(() => parkings = res);
  }

  Future<void> _save() async {
    for (final pid in selected) {
      await supabase.from('parking_admin_assignments').insert({
        'admin_id': widget.adminId,
        'parking_id': pid,
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Parkings"),
        backgroundColor: Colors.red,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
      body: ListView.builder(
        itemCount: parkings.length,
        itemBuilder: (_, i) {
          final p = parkings[i];
          return CheckboxListTile(
            title: Text(p['name']),
            value: selected.contains(p['id']),
            onChanged: (v) {
              setState(() {
                v! ? selected.add(p['id']) : selected.remove(p['id']);
              });
            },
          );
        },
      ),
    );
  }
}
