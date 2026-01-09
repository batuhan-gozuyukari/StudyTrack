import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  String? _selectedLesson;

  final List<String> _lessons = [
    'Matematik',
    'Fizik',
    'Yazılım',
    'İngilizce',
    'Tarih',
    'Diğer'
  ];

  String _formatTime(int seconds) {
    final sec = seconds % 60;
    final min = (seconds ~/ 60) % 60;
    final hrs = seconds ~/ 3600;
    return "${hrs.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
      // dersi sıfırlamıyoruz; kullanıcı aynı dersten devam edebilir
    });
  }

  void _finishSession() {
    _stopTimer();

    if (_seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("1 dakikadan az çalışmalar kaydedilmez!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showSaveDialog();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        String? localLesson = _selectedLesson;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Çalışmayı Kaydet"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text("Süre"),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(_seconds),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: localLesson,
                    decoration: const InputDecoration(
                      labelText: "Ders",
                      border: OutlineInputBorder(),
                    ),
                    items: _lessons
                        .map(
                          (lesson) => DropdownMenuItem(
                            value: lesson,
                            child: Text(lesson),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setLocalState(() => localLesson = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (localLesson == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen ders seçiniz."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    _selectedLesson = localLesson;
                    await _saveToFirebase();
                    if (!mounted) return;

                    _resetTimer(); // süreyi sıfırla
                    Navigator.of(context).pop(); // sadece dialogu kapat
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('study_sessions').add({
        'userId': user.uid,
        'lesson': _selectedLesson,
        'durationMinutes': (_seconds / 60).round(),
        'date': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Çalışma başarıyla kaydedildi! 🎉"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showManualEntryDialog() {
    final durationController = TextEditingController();
    String? localSelectedLesson;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Manuel Aktivite Ekle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Sayacı açmayı unuttun mu? Buradan ekleyebilirsin."),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: localSelectedLesson,
                    hint: const Text("Ders Seçiniz"),
                    items: _lessons
                        .map(
                          (lesson) => DropdownMenuItem(
                            value: lesson,
                            child: Text(lesson),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setLocalState(() => localSelectedLesson = val),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Süre (Dakika)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final minutes = int.tryParse(durationController.text) ?? 0;
                    if (localSelectedLesson == null || minutes <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Lütfen ders seçin ve geçerli süre girin."),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    await FirebaseFirestore.instance
                        .collection('study_sessions')
                        .add({
                      'userId': user.uid,
                      'lesson': localSelectedLesson,
                      'durationMinutes': minutes,
                      'date': Timestamp.now(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context); // dialog
                    Navigator.pop(this.context); // TimerScreen'den geri

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text("Aktivite eklendi! 🎉"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(_seconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zamanlayıcı"),
        actions: [
          IconButton(
            tooltip: "Sıfırla",
            onPressed: _seconds == 0 ? null : _resetTimer,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ÜST KART
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Süre",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRunning
                        ? "Çalışılıyor... odak sende 🔥"
                        : "Hazırsan başlat 🚀",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // DERS SEÇİMİ
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ders seç:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _lessons.map((lesson) {
                final selected = _selectedLesson == lesson;
                return ChoiceChip(
                  label: Text(lesson),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedLesson = lesson);
                  },
                  selectedColor: Colors.indigo.shade100,
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // BUTONLAR
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isRunning ? _stopTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? "Durdur" : "Başlat"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _seconds == 0 ? null : _finishSession,
                    icon: const Icon(Icons.stop),
                    label: const Text("Bitir & Kaydet"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // MANUEL EKLE
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text("Manuel Ekle"),
                subtitle: const Text("Sayaç olmadan eklemek için"),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showManualEntryDialog,
              ),
            ),

            const SizedBox(height: 12),

            // İPUCU
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "İpucu: 25 dk odak + 5 dk mola (Pomodoro) deneyebilirsin.",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
