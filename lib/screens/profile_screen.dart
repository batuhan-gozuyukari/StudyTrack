import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  final List<String> _avatarOptions = [
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140051.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140040.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140039.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
  ];

  // ---------------- AVATAR ----------------
  void _showAvatarSelectionSheet(String uid) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Bir Avatar Seç",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () =>
                          _updateProfilePic(uid, _avatarOptions[index]),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Image.network(_avatarOptions[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfilePic(String uid, String url) async {
    Navigator.pop(context);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePic': url,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil resmi güncellendi!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // ---------------- İSİM ----------------
  void _showEditProfileDialog(String uid, String currentName) {
    _nameController.text = currentName;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Profili Düzenle"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Ad Soyad",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'name': newName});

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- HEDEFLER ----------------
  void _showEditGoalDialog(String uid, int daily, int weekly) {
    final dailyController = TextEditingController(text: daily.toString());
    final weeklyController = TextEditingController(text: weekly.toString());

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Hedef Ayarları"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dailyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Günlük Hedef (dk)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: weeklyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Haftalık Hedef (dk)",
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
                final newDaily = int.tryParse(dailyController.text);
                final newWeekly = int.tryParse(weeklyController.text);

                if (newDaily == null ||
                    newWeekly == null ||
                    newDaily <= 0 ||
                    newWeekly <= 0) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                  'dailyGoalMinutes': newDaily,
                  'weeklyGoalMinutes': newWeekly,
                });

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hedefler güncellendi!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Oturum bulunamadı")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final name = data['name'] ?? 'Öğrenci';
          final email = data['email'] ?? '';
          final daily = data['dailyGoalMinutes'] ?? 60;
          final weekly = data['weeklyGoalMinutes'] ?? 300;
          final avatar = data['profilePic'] ??
              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(avatar),
                    ),
                    InkWell(
                      onTap: () => _showAvatarSelectionSheet(user.uid),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(user.uid, name),
                  icon: const Icon(Icons.edit),
                  label: const Text("İsmi Düzenle"),
                ),
                const Divider(height: 40),
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: Text("Hedefler: Günlük $daily / Haftalık $weekly dk"),
                  onTap: () => _showEditGoalDialog(user.uid, daily, weekly),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Çıkış Yap",
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
