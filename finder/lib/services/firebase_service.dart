import 'dart:convert'; // Base64 işlemleri için
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Sıkıştırma paketi

class FirebaseService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('mekanlar');

  // --- SİHİRLİ FONKSİYON: Resmi Küçült ve Metne Çevir ---
  Future<String> resmiDonustur(File resimDosyasi) async {
    // 1. Resmi sıkıştır (Firestore'un 1MB limitine takılmamak için)
    Uint8List? result = await FlutterImageCompress.compressWithFile(
      resimDosyasi.absolute.path,
      minWidth: 800, // Genişlik en fazla 800px olsun
      minHeight: 600,
      quality: 70, // Kaliteyi %70'e düşür
    );

    if (result == null) return "";

    // 2. Metne (Base64) çevir
    String base64String = base64Encode(result);
    return base64String;
  }

  // Mekan Ekle (Artık resimUrl yerine Base64 string geliyor)
  Future<void> mekanEkle(String isim, String not, String kategori, GeoPoint konum, String resimData) async {
    await _ref.add({
      'isim': isim,
      'not': not,
      'kategori': kategori,
      'konum': konum,
      'resimUrl': resimData, // Uzun yazı olarak kaydediyoruz
      'tarih': FieldValue.serverTimestamp(),
    });
  }

  Future<void> mekanSil(String id) async {
    await _ref.doc(id).delete();
  }

  Stream<QuerySnapshot> getMekanlarStream() {
    return _ref.orderBy('tarih', descending: true).snapshots();
  }

  final CollectionReference _begenilerRef = FirebaseFirestore.instance.collection('begeniler');

  // Beğeni Kaydet ve Match Kontrolü Yap
  Future<bool> mekaniBegenVeMatchKontrol(String mekanId, String kullaniciAdi) async {
    // 1. Önce bu beğeniyi kaydet
    await _begenilerRef.add({
      'mekanId': mekanId,
      'kullaniciId': kullaniciAdi, // Basitlik olsun diye isim kullanıyoruz
      'tarih': FieldValue.serverTimestamp(),
    });

    // 2. Match Kontrolü: Aynı mekanı benden BAŞKA biri beğenmiş mi?
    final snapshot = await _begenilerRef
        .where('mekanId', isEqualTo: mekanId)
        .where('kullaniciId', isNotEqualTo: kullaniciAdi) // Ben olmayanlar
        .get();

    // Eğer sonuç varsa, en az 1 kişi daha beğenmiş demektir -> MATCH!
    return snapshot.docs.isNotEmpty;
  }

  final CollectionReference _eslesmelerRef = FirebaseFirestore.instance.collection('eslesmeler');

  // Match Kaydetme Fonksiyonu
  Future<void> matchKaydet(String mekanId, String mekanIsmi, String resimUrl, String user1, String user2) async {
    // Aynı mekan için daha önce eşleşme kaydı var mı bakalım (Tekrar tekrar kaydetmeyelim)
    final snapshot = await _eslesmelerRef
        .where('mekanId', isEqualTo: mekanId)
        .where('kullanicilar', arrayContains: user1) // Basit kontrol
        .get();

    if (snapshot.docs.isEmpty) {
      await _eslesmelerRef.add({
        'mekanId': mekanId,
        'mekanIsmi': mekanIsmi,
        'resimUrl': resimUrl, // Listede göstermek için resmi de kaydediyoruz
        'kullanicilar': [user1, user2], // Eşleşen kişiler
        'tarih': FieldValue.serverTimestamp(),
      });
    }
  }

  // Benim Eşleşmelerimi Getir
  Stream<QuerySnapshot> getEslesmelerStream(String myName) {
    return _eslesmelerRef
        .where('kullanicilar', arrayContains: myName) // Benim adımın geçtiği kayıtlar
        .orderBy('tarih', descending: true)
        .snapshots();
  }
}