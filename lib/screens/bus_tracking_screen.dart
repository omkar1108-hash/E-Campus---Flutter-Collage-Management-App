import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/content.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Real-time bus positions on Google Maps, fed by the Firestore stream that
/// the broadcasting device updates.
class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _map;
  bool _centred = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Re-evaluate "live / offline" labels even when no new data arrives.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _map?.dispose();
    super.dispose();
  }

  void _focus(BusLocation b) =>
      _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(b.lat, b.lng), 16));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<List<BusLocation>>(
      stream: context.read<FirestoreService>().watchBuses(),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        final buses = snap.data ?? const <BusLocation>[];
        if (!_centred && buses.isNotEmpty) {
          _centred = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _focus(buses.first));
        }
        final markers = {
          for (final b in buses)
            Marker(
              markerId: MarkerId(b.id),
              position: LatLng(b.lat, b.lng),
              infoWindow: InfoWindow(
                title: b.id,
                snippet: '${b.speedKmh.toStringAsFixed(0)} km/h',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                b.isLive(now, AppConfig.busStaleAfter)
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
            ),
        };
        return Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(AppConfig.defaultMapLat, AppConfig.defaultMapLng),
                  zoom: 12,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                onMapCreated: (c) => _map = c,
              ),
            ),
            SizedBox(
              height: 130,
              child: !snap.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : buses.isEmpty
                      ? const EmptyState(
                          icon: Icons.directions_bus_outlined,
                          message: 'No bus is broadcasting right now.')
                      : ListView(
                          children: [
                            for (final b in buses)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.directions_bus,
                                  color: b.isLive(now, AppConfig.busStaleAfter)
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                title: Text(b.id),
                                subtitle: Text(
                                  b.updatedAt == null
                                      ? 'Updating…'
                                      : '${b.isLive(now, AppConfig.busStaleAfter) ? 'Live' : 'Last seen'} '
                                          '${DateFormat.jm().format(b.updatedAt!)} • '
                                          '${b.speedKmh.toStringAsFixed(0)} km/h'
                                          '${b.driverName.isEmpty ? '' : ' • ${b.driverName}'}',
                                ),
                                onTap: () => _focus(b),
                              ),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}
