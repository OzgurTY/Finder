import 'dart:convert';
import 'dart:io'; // Platform kontrolü için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finder/models/mekan_model.dart';
import 'package:finder/screens/discovery_screen.dart';
import 'package:finder/services/firebase_service.dart';
import 'package:finder/widgets/add_place_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Link açmak için
import 'package:finder/screens/matches_screen.dart';

class MapScreen extends StatefulWidget {
  final String kullaniciAdi;

  const MapScreen({super.key, required this.kullaniciAdi});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseService _service = FirebaseService();
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _dinlemeyiBaslat();
  }

  void _dinlemeyiBaslat() {
    _service.getMekanlarStream().listen((snapshot) {
      final List<Marker> yeniMarkerlar = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final mekan = Mekan(
          id: doc.id,
          isim: data['isim'] ?? '',
          not: data['not'] ?? '',
          kategori: data['kategori'] ?? 'Diğer',
          resimUrl: data['resimUrl'] ?? '',
          konum: data['konum'] ?? const GeoPoint(0, 0),
        );
        yeniMarkerlar.add(_markerOlustur(mekan));
      }
      if (mounted) setState(() { _markers = yeniMarkerlar; });
    });
  }

  // --- YENİ: Harita Uygulamasını Başlatan Fonksiyon ---
  Future<void> _haritadaAc(double lat, double lng) async {
    // Google Maps link yapısı (Android ve iOS'te çalışır)
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    
    // Apple Maps link yapısı (Sadece iOS için alternatif)
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (Platform.isIOS) {
      // iOS ise önce Apple Maps'i dene, olmazsa Google'ı dene
      if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else {
        await launchUrl(googleMapsUrl);
      }
    } else {
      // Android ise direkt Google Maps
      await launchUrl(googleMapsUrl);
    }
  }

  Marker _markerOlustur(Mekan mekan) {
    return Marker(
      point: LatLng(mekan.konum.latitude, mekan.konum.longitude),
      width: 90, height: 90,
      child: GestureDetector(
        onTap: () => _mekanDetayGoster(mekan),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: mekan.renk, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.3))]),
              child: Icon(mekan.ikon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: [const BoxShadow(blurRadius: 2, color: Colors.black12)]),
              child: Text(mekan.isim, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  void _mekanEkleModalAc(LatLng konum) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => AddPlaceSheet(tiklananKonum: konum),
    );
  }

  void _kesfetModunuAc() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiscoveryScreen(
          currentUserName: widget.kullaniciAdi, // İsim aktarılıyor
          onMekanSecildi: (secilenMekan) {
            // Burası eskisi gibi
            Navigator.pop(context);
            _mapController.move(LatLng(secilenMekan.konum.latitude, secilenMekan.konum.longitude), 15);
            _mekanDetayGoster(secilenMekan);
          },
        ),
      ),
    );
  }

  void _mekanDetayGoster(Mekan mekan) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mekan.resimUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.memory(base64Decode(mekan.resimUrl), width: double.infinity, height: 250, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 250, color: Colors.grey[300])),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [CircleAvatar(backgroundColor: mekan.renk.withOpacity(0.2), child: Icon(mekan.ikon, color: mekan.renk)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(mekan.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(mekan.kategori, style: TextStyle(color: Colors.grey[600], fontSize: 16))]))]),
                        const SizedBox(height: 20),
                        Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: Text(mekan.not.isEmpty ? "Not yok." : mekan.not, style: const TextStyle(fontSize: 16))),
                        
                        const SizedBox(height: 30),
                        
                        // --- YENİ BUTONLAR (Yan Yana) ---
                        Row(
                          children: [
                            // 1. Yol Tarifi Butonu (Büyük ve Renkli)
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _haritadaAc(mekan.konum.latitude, mekan.konum.longitude);
                                },
                                icon: const Icon(Icons.navigation, color: Colors.white),
                                label: const Text("Yol Tarifi Al", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent, 
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 10),

                            // 2. Silme Butonu (Daha küçük ve Kırmızı)
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () {
                                  _service.mekanSil(mekan.id);
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                                child: const Icon(Icons.delete, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                        // --------------------------------
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Finder", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MatchesScreen(currentUserName: widget.kullaniciAdi)),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _kesfetModunuAc,
        label: const Text("Keşfet"),
        icon: const Icon(Icons.style), 
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: const LatLng(41.0082, 28.9784), initialZoom: 13.0, onLongPress: (tapPosition, point) => _mekanEkleModalAc(point)),
        children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ozgur.finder'), MarkerLayer(markers: _markers)],
      ),
    );
  }
}