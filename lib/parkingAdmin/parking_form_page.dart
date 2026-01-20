import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartparking/parkingAdmin/dashboard_screen.dart';
import 'package:smartparking/parkingAdmin/widget/bottom_app_bar.dart';
// import 'package:smartparking/superAdmin/dashboard_screen.dart';
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
      _latCtrl.text = p['latitude']?.toString() ?? '';
      _lngCtrl.text = p['longitude']?.toString() ?? '';
      _priceCtrl.text = p['hourly_price']?.toString() ?? '';
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

  /// GET CURRENT LOCATION
  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// SAVE PARKING
  Future<void> _saveParking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again')),
      );
      setState(() => _loading = false);
      return;
    }

    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    final price = double.tryParse(_priceCtrl.text);

    if (lat == null || lng == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid numeric values')),
      );
      setState(() => _loading = false);
      return;
    }

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'latitude': lat,
      'longitude': lng,
      'hourly_price': price,
      'is_active': _isActive,
      'owner_id': user.id,
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

      if (mounted && Navigator.canPop(context)) {
        // Navigator.pop(context, true);
        Navigator.push(context, MaterialPageRoute(builder: (_) =>  ParkingAdminDashboard()));
      }
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save parking')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// DELETE PARKING (EDIT ONLY)
  Future<void> _deleteParking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Parking'),
        content: const Text(
          'Are you sure you want to delete this parking?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            // onPressed: () => Navigator.pop(context, true),
            onPressed: () {
              Navigator.push(context,MaterialPageRoute(builder: (_) =>  ParkingAdminDashboard()));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('parkings')
          .delete()
          .eq('id', widget.parking!['id']);

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete parking')),
      );
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
      bottomNavigationBar: const ParkingAdminAppBar(),
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

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
              ),

              _input('Hourly Price', _priceCtrl,
                  type: TextInputType.number),

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
                    backgroundColor: Colors.blue[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Parking' : 'Create Parking',style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900
                      ),),
                ),
              ),

              ///  DELETE BUTTON - Only shown in edit screen only !
              if (isEdit) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _deleteParking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Delete Parking',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
