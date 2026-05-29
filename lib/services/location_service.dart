import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // 1. Ambil Koordinat GPS Perangkat
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('GPS Perangkat tidak aktif.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Izin GPS ditolak.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Izin GPS ditolak secara permanen.');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 2. Ubah Koordinat Angka Menjadi Teks Nama Jalan
  Future<String> getAddressFromCoords(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Mengembalikan format: Nama Jalan, Kecamatan
        return "${place.street}, ${place.locality}";
      }
      return "Lokasi tidak diketahui";
    } catch (e) {
      print("Gagal konversi koordinat: $e");
      return "Gagal memuat nama jalan";
    }
  }
}