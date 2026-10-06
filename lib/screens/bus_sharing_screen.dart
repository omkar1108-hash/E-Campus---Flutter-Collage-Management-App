import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Staff device inside the bus: streams GPS fixes to Firestore.
/// Works while the app is in the foreground.
class BusSharingScreen extends StatefulWidget {
  const BusSharingScreen({super.key});

  @override
  State<BusSharingScreen> createState() => _BusSharingScreenState();
}

class _BusSharingScreenState extends State<BusSharingScreen> {
  final _busId = TextEditingController(text: 'BUS-01');
  StreamSubscription<Position>? _sub;
  late final FirestoreService _store;
  Position? _last;
  String? _activeId;
  String? _error;

  bool get _sharing => _sub != null;

  @override
  void initState() {
    super.initState();
    _store = context.read<FirestoreService>();
  }

  @override
  void dispose() {
    _stopInternal();
    _busId.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Turn on location services (GPS).');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => _error = 'Location permission is required to broadcast.');
      return false;
    }
    return true;
  }

  Future<void> _start() async {
    final id = _busId.text.trim().toUpperCase();
    if (id.isEmpty) {
      showSnack(context, 'Enter a bus id.');
      return;
    }
    setState(() => _error = null);
    if (!await _ensurePermission() || !mounted) return;
    final driver = context.read<SessionProvider>().user!.name;
    _activeId = id;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // metres between updates; saves battery & writes
      ),
    ).listen(
      (p) {
        setState(() => _last = p);
        _store
            .updateBus(
              busId: id,
              lat: p.latitude,
              lng: p.longitude,
              speedKmh: (p.speed < 0 ? 0 : p.speed) * 3.6,
              driverName: driver,
            )
            .catchError((Object e) {
          if (mounted) setState(() => _error = 'Could not upload position: $e');
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = 'GPS error: $e');
      },
    );
    setState(() {});
  }

  void _stopInternal() {
    _sub?.cancel();
    _sub = null;
    final id = _activeId;
    _activeId = null;
    if (id != null) _store.removeBus(id).catchError((Object _) {});
  }

  void _stop() => setState(() {
        _stopInternal();
        _last = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Bus Location')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _busId,
              enabled: !_sharing,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Bus id', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sharing ? _stop : _start,
              icon: Icon(_sharing ? Icons.stop : Icons.play_arrow),
              label: Text(_sharing ? 'Stop sharing' : 'Start sharing'),
            ),
            const SizedBox(height: 24),
            if (_sharing)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.gps_fixed, color: Colors.green),
                  title: Text('Sharing as $_activeId'),
                  subtitle: Text(_last == null
                      ? 'Waiting for a GPS fix…'
                      : '${_last!.latitude.toStringAsFixed(5)}, '
                          '${_last!.longitude.toStringAsFixed(5)}'),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const Spacer(),
            const Text(
              'Keep this screen open while the bus is moving. Students see the '
              'bus on the Bus Tracking map.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
