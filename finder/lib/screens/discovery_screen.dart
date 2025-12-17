import 'dart:convert';
import 'package:finder/models/mekan_model.dart';
import 'package:finder/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; 

class DiscoveryScreen extends StatefulWidget {
  final Function(Mekan) onMekanSecildi;
  final String currentUserName;

  const DiscoveryScreen({super.key, required this.onMekanSecildi, required this.currentUserName});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final FirebaseService _service = FirebaseService();
  List<Mekan> _mekanlar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriCek();
  }

  void _verileriCek() async {
    final snapshot = await _service.getMekanlarStream().first;
    final tumMekanlar = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Mekan(
        id: doc.id,
        isim: data['isim'] ?? '',
        not: data['not'] ?? '',
        kategori: data['kategori'] ?? 'Diğer',
        resimUrl: data['resimUrl'] ?? '',
        konum: data['konum']
      );
    }).where((m) => m.resimUrl.isNotEmpty).toList(); 

    // --- SİHİRLİ DOKUNUŞ: LİSTEYİ KARIŞTIR ---
    tumMekanlar.shuffle(); 
    // ----------------------------------------

    if (mounted) {
      setState(() {
        _mekanlar = tumMekanlar;
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator());
    
    if (_mekanlar.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(title: const Text("Keşfet"), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text("Henüz resimli bir mekan yok.\nBiraz fotoğraf çekip ekle!", 
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Keşfet"), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: CardSwiper(
                cardsCount: _mekanlar.length,
                numberOfCardsDisplayed: _mekanlar.length < 3 ? _mekanlar.length : 3,
                onSwipe: (previousIndex, currentIndex, direction) {
                  final mekan = _mekanlar[previousIndex];

                  if (direction == CardSwiperDirection.right) {
                    _service.mekaniBegenVeMatchKontrol(mekan.id, widget.currentUserName).then((isMatch) {
                      if (isMatch) {
                         // Match olduysa kaydet
                        _service.matchKaydet(mekan.id, mekan.isim, mekan.resimUrl, widget.currentUserName, "Arkadaşın");

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: const Text("🔥 MATCH! 🔥", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 30, fontWeight: FontWeight.bold)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Bu mekanı arkadaşın da beğendi!"),
                                const SizedBox(height: 20),
                                const Icon(Icons.favorite, color: Colors.red, size: 60),
                                const SizedBox(height: 20),
                                const Text("Hadi plan yapın!"),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.onMekanSecildi(mekan);
                                },
                                child: const Text("Mekana Git"),
                              )
                            ],
                          ),
                        );
                      } else {
                        widget.onMekanSecildi(mekan);
                      }
                    });
                    return false; 
                  }
                  return true;
                },
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final mekan = _mekanlar[index];
                  return _kartTasarimi(mekan);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Gitmek için Sağa 👉, Geçmek için Sola 👈", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  Widget _kartTasarimi(Mekan mekan) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              base64Decode(mekan.resimUrl),
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mekan.isim, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(mekan.ikon, color: mekan.renk, size: 20),
                        const SizedBox(width: 8),
                        Text(mekan.kategori, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(mekan.not, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}