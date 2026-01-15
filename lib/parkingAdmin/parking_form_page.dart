import 'package:flutter/material.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ParkingFormPage extends StatefulWidget {
  final Map<String, dynamic>? parking; // null = create, not null = edit

  const ParkingFormPage({super.key, this.parking});

  @override
  State<ParkingFormPage> createState() => _ParkingFormPageState();
}

class _ParkingFormPageState extends State<ParkingFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _isActive = true;
  bool _loading = false;

  bool get isEdit => widget.parking != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final p = widget.parking!;
      _nameCtrl.text = p['name'] ?? '';
      _descCtrl.text = p['description'] ?? '';
      _latCtrl.text = p['latitude'].toString();
      _lngCtrl.text = p['longitude'].toString();
      _priceCtrl.text = p['hourly_price'].toString();
      _isActive = p['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveParking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final userId = supabase.auth.currentUser!.id;

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'latitude': double.parse(_latCtrl.text),
      'longitude': double.parse(_lngCtrl.text),
      'hourly_price': double.parse(_priceCtrl.text),
      'is_active': _isActive,
      'owner_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (isEdit) {
        await supabase
            .from('parkings')
            .update(data)
            .eq('id', widget.parking!['id']);
      } else {
        await supabase.from('parkings').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Parking updated successfully' : 'Parking created successfully',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save parking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Parking' : 'Create Parking'),
        backgroundColor: Colors.red,
      ),
      bottomNavigationBar: ParkingAdminAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input('Parking Name', _nameCtrl),
              _input('Description', _descCtrl),
              _input('Latitude', _latCtrl, type: TextInputType.number),
              _input('Longitude', _lngCtrl, type: TextInputType.number),
              _input('Hourly Price', _priceCtrl, type: TextInputType.number),

              SwitchListTile(
                value: _isActive,
                title: const Text('Active'),
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveParking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Parking' : 'Create Parking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => ParkingFormPage(parking: parkingMap),
//   ),
// );