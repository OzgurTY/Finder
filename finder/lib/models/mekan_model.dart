import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Mekan {
  final String id;
  final String isim;
  final String not;
  final String kategori;
  final String resimUrl;
  final GeoPoint konum;

  Mekan({
    required this.id,
    required this.isim,
    required this.not,
    required this.kategori,
    required this.resimUrl,
    required this.konum,
  });

  // Kategorilere göre renk veren yardımcı fonksiyon
  Color get renk {
    switch (kategori) {
      case 'Kafe': return Colors.orange;
      case 'Yemek': return Colors.redAccent;
      case 'Manzara': return Colors.green;
      case 'Eğlence': return Colors.purple;
      default: return Colors.indigo;
    }
  }

  // Kategorilere göre ikon veren yardımcı fonksiyon
  IconData get ikon {
    switch (kategori) {
      case 'Kafe': return Icons.coffee;
      case 'Yemek': return Icons.restaurant;
      case 'Manzara': return Icons.landscape;
      case 'Eğlence': return Icons.theater_comedy;
      default: return Icons.place;
    }
  }
}