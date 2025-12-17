import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Resim seçici
import 'package:latlong2/latlong.dart';
import '../services/firebase_service.dart';

class AddPlaceSheet extends StatefulWidget {
  final LatLng tiklananKonum;

  const AddPlaceSheet({super.key, required this.tiklananKonum});

  @override
  State<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  final _isimController = TextEditingController();
  final _notController = TextEditingController();
  String _secilenKategori = 'Diğer';
  File? _secilenResim; // Seçilen resim dosyası
  bool _yukleniyor = false; // Loading durumu

  final FirebaseService _service = FirebaseService();
  final List<String> _kategoriler = ['Kafe', 'Yemek', 'Manzara', 'Eğlence', 'Diğer'];

  // Galeriden Resim Seçme
  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _secilenResim = File(pickedFile.path);
      });
    }
  }

  void _kaydet() async {
    if (_isimController.text.isEmpty) return;

    setState(() { _yukleniyor = true; }); // Yükleniyor'u başlat

    String resimVerisi = "";
    
    // Eğer resim seçildiyse metne çevir (Base64)
    if (_secilenResim != null) {
      resimVerisi = await _service.resmiDonustur(_secilenResim!);
    }

    // Mekanı kaydet
    await _service.mekanEkle(
      _isimController.text,
      _notController.text,
      _secilenKategori,
      GeoPoint(widget.tiklananKonum.latitude, widget.tiklananKonum.longitude),
      resimVerisi
    );

    if (mounted) {
      setState(() { _yukleniyor = false; });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Klavye açılınca ekranın yukarı kayması için padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üstteki gri çizgi
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          
          const Text("Yeni Bir Yer Keşfet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // --- RESİM ALANI ---
          Center(
            child: GestureDetector(
              onTap: _resimSec,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                  image: _secilenResim != null 
                    ? DecorationImage(image: FileImage(_secilenResim!), fit: BoxFit.cover)
                    : null
                ),
                child: _secilenResim == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          Text("Resim Ekle", style: TextStyle(color: Colors.grey))
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 15),

          TextField(controller: _isimController, decoration: _inputDecoration("Mekan İsmi", Icons.place_outlined)),
          const SizedBox(height: 15),

          TextField(controller: _notController, decoration: _inputDecoration("Kısa bir not...", Icons.notes)),
          const SizedBox(height: 15),

          // Kategori Seçimi (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kategoriler.map((kategori) {
                final secili = _secilenKategori == kategori;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(kategori),
                    selected: secili,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(color: secili ? Colors.white : Colors.black),
                    onSelected: (val) => setState(() => _secilenKategori = kategori),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 25),

          // Kaydet Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _yukleniyor ? null : _kaydet, // Yüklenirken tıklanmasın
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _yukleniyor 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Konumu Kaydet", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}