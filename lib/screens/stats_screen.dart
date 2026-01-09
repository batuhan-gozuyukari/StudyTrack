import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Son 7 günün başlangıcı (bugün dahil) - YEREL TARİH
  DateTime getSevenDaysAgo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // gün başı
    return today.subtract(const Duration(days: 6));
  }

  // Haftanın gün isimleri
  String getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Oturum bulunamadı. Lütfen tekrar giriş yap."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler & Analiz")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // Kullanıcı hedefini çekiyoruz
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(
                child: Text("Kullanıcı verisi okunurken hata oluştu."));
          }
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() ?? {};
          final weeklyGoal =
              (userData['weeklyGoalMinutes'] as num?)?.toInt() ?? 300;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // Tüm study_sessions kayıtlarını date'e göre alıyoruz.
            // userId ve son 7 gün filtresi Dart tarafında yapılacak.
            stream: FirebaseFirestore.instance
                .collection('study_sessions')
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, sessionSnapshot) {
              if (sessionSnapshot.hasError) {
                return Center(
                  child: Text(
                    "Çalışma kayıtları okunurken hata: ${sessionSnapshot.error}",
                  ),
                );
              }

              if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = sessionSnapshot.data?.docs ?? [];
              // debug için istersen:
              // print("STATS docs length = ${docs.length}");

              // VERİ ANALİZİ
              final Map<int, int> dailyTotals = {}; // günKey -> toplam dk
              final Map<String, int> lessonTotals = {}; // Ders -> toplam dk
              int totalWeeklyMinutes = 0;

              // Tarih aralığı
              final startDate = getSevenDaysAgo(); // en eski gün
              final now = DateTime.now();
              final today =
                  DateTime(now.year, now.month, now.day); // en yeni gün

              // Son 7 gün için 0'lı base map oluştur
              for (int i = 0; i < 7; i++) {
                final d = startDate.add(Duration(days: i));
                final key = d.year * 10000 + d.month * 100 + d.day;
                dailyTotals[key] = 0;
              }

              // Firestore kayıtlarını işle
              for (final doc in docs) {
                final data = doc.data();

                // 1) Bu kayıt başka kullanıcıya aitse atla
                if (data['userId'] != user!.uid) {
                  continue;
                }

                // 2) Tarih
                final ts = data['date'] as Timestamp?;
                if (ts == null) continue;

                final rawDate = ts.toDate();
                final date = DateTime(rawDate.year, rawDate.month, rawDate.day);

                // 3) Son 7 gün filtresi
                if (date.isBefore(startDate) || date.isAfter(today)) {
                  continue;
                }

                final minutes = (data['durationMinutes'] as num?)?.toInt() ?? 0;
                final lesson = (data['lesson'] as String?) ?? 'Diğer';

                final key = date.year * 10000 + date.month * 100 + date.day;

                dailyTotals[key] = (dailyTotals[key] ?? 0) + minutes;
                lessonTotals[lesson] = (lessonTotals[lesson] ?? 0) + minutes;
                totalWeeklyMinutes += minutes;
              }

              // Grafikte kullanmak için sırayı garanti edelim
              final List<MapEntry<DateTime, int>> last7Days = [];
              for (int i = 0; i < 7; i++) {
                final d = startDate.add(Duration(days: i));
                final key = d.year * 10000 + d.month * 100 + d.day;
                final value = dailyTotals[key] ?? 0;
                last7Days.add(MapEntry(d, value));
              }

              // Maks günlük değer (grafikte oran için)
              int maxDaily = 0;
              for (final v in last7Days.map((e) => e.value)) {
                if (v > maxDaily) maxDaily = v;
              }
              if (maxDaily == 0) maxDaily = 60; // boşsa referans 60 dk

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Haftalık hedef kartı
                    _buildWeeklyGoalCard(totalWeeklyMinutes, weeklyGoal),
                    const SizedBox(height: 20),

                    const Text(
                      "Son 7 Gün Performansı",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Bar grafiği
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: last7Days.map((entry) {
                          final date = entry.key;
                          final value = entry.value;
                          final barHeight = (value / maxDaily) * 120;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "$value",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 20,
                                height: barHeight == 0 ? 5 : barHeight,
                                decoration: BoxDecoration(
                                  color: value > 0
                                      ? Colors.indigo
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                getDayName(date.weekday),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Ders Bazlı Dağılım",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    if (lessonTotals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "Henüz bu hafta çalışma kaydı yok. 📉",
                          ),
                        ),
                      )
                    else
                      ...lessonTotals.entries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child:
                                  const Icon(Icons.book, color: Colors.orange),
                            ),
                            title: Text(
                              entry.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              "${entry.value} dk",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Haftalık hedef kartı
  Widget _buildWeeklyGoalCard(int current, int goal) {
    double percent =
        (goal == 0 ? 0.0 : current / goal).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Haftalık Hedef",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                "$current / $goal dk",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(
            percent >= 1.0
                ? "Tebrikler! Hedefine ulaştın! 🎉"
                : "%${(percent * 100).toInt()} tamamlandı, devam et! 🔥",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
