import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finder/services/firebase_service.dart';
import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  final String currentUserName;

  const MatchesScreen({super.key, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eşleşmelerim 🔥", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getEslesmelerStream(currentUserName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu: ${snapshot.error}"));
          }

          // 2. YÜKLENİYORSA GÖSTER
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. VERİ GELDİ AMA BOŞ MU?
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Henüz eşleşme yok.\nBiraz daha mekan beğen!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  // Debug için kullanıcı adını yazdıralım
                  SizedBox(height: 20),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final mekanIsmi = data['mekanIsmi'] ?? 'Mekan';
              final resimBase64 = data['resimUrl'] ?? '';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: resimBase64.isNotEmpty
                        ? Image.memory(base64Decode(resimBase64), width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: Colors.grey),
                  ),
                  title: Text(mekanIsmi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Text("Bu mekana gitmek için anlaştınız! 🥂"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // İstersen buradan tekrar detay sayfasına veya haritaya yönlendirebilirsin
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan yapma zamanı!")));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}