import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, String>> _activityIcons = [
    {
      'icon': '📚',
      'label': 'Ders',
      'image': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
    },
    {
      'icon': '☕',
      'label': 'Mola',
      'image': 'https://cdn-icons-png.flaticon.com/512/2935/2935307.png',
    },
    {
      'icon': '🎯',
      'label': 'Hedef',
      'image': 'https://cdn-icons-png.flaticon.com/512/2481/2481079.png',
    },
    {
      'icon': '📝',
      'label': 'Sınav',
      'image': 'https://cdn-icons-png.flaticon.com/512/2641/2641409.png',
    },
    {
      'icon': '💪',
      'label': 'Spor',
      'image': 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
    },
    {
      'icon': '🔥',
      'label': 'Fokus',
      'image': 'https://cdn-icons-png.flaticon.com/512/426/426833.png',
    },
  ];

  int? _selectedIconIndex;

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final d = timestamp.toDate();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return "$day.$month.$year $hour:$minute";
  }

  Future<void> _sharePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_messageController.text.trim().isEmpty && _selectedIconIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bir mesaj yazın veya durum seçin."),
        ),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = (userDoc.data()?['name'] as String?) ?? 'Öğrenci';
      final userAvatar = (userDoc.data()?['profilePic'] as String?) ?? '';

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'message': _messageController.text.trim(),
        'date': Timestamp.now(),
        'likes': 0,
        'likedBy': [],
        'comments': [],
        'activityImage': _selectedIconIndex != null
            ? _activityIcons[_selectedIconIndex!]['image']
            : null,
        'activityLabel': _selectedIconIndex != null
            ? _activityIcons[_selectedIconIndex!]['label']
            : null,
      });

      _messageController.clear();
      setState(() => _selectedIconIndex = null);

      if (!mounted) return;
      Navigator.pop(context); // sheet kapat
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  void _showAddPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ne durumdasın?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          "Bugün hedeflerini tamamladın mı? Arkadaşlarına seslen...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Bir durum ikonu ekle (İsteğe bağlı):",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activityIcons.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              _selectedIconIndex = isSelected ? null : index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigo.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: Colors.indigo, width: 2)
                                  : null,
                            ),
                            child: Image.network(
                              _activityIcons[index]['image']!,
                              width: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sharePost,
                      icon: const Icon(Icons.send),
                      label: const Text("Paylaş"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleLike(String docId, List likedBy) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (likedBy.contains(user.uid)) {
      FirebaseFirestore.instance.collection('posts').doc(docId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      FirebaseFirestore.instance.collection('posts').doc(docId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  void _showCommentDialog(DocumentSnapshot postDoc) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController commentController = TextEditingController();

    List comments;
    try {
      comments = postDoc.get('comments');
    } catch (_) {
      comments = [];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Yorumlar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              Expanded(
                child: comments.isEmpty
                    ? const Center(
                        child: Text("Henüz yorum yok. İlk sen yaz!"),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index] as Map<String, dynamic>;
                          final avatar = (c['avatar'] as String?) ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              radius: 15,
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            title: Text(
                              (c['name'] as String?) ?? 'Anonim',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: Text((c['text'] as String?) ?? ''),
                            trailing: Text(
                              _formatDate(c['date'] as Timestamp?)
                                      .split(' ')
                                      .elementAtOrNull(1) ??
                                  '',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: "Bir yorum yaz...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.indigo),
                      onPressed: () async {
                        final txt = commentController.text.trim();
                        if (txt.isEmpty) return;

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        final newComment = {
                          'userId': user.uid,
                          'name':
                              (userDoc.data()?['name'] as String?) ?? 'Öğrenci',
                          'avatar':
                              (userDoc.data()?['profilePic'] as String?) ?? '',
                          'text': txt,
                          'date': Timestamp.now(),
                        };

                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postDoc.id)
                            .update({
                          'comments': FieldValue.arrayUnion([newComment]),
                        });

                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Oturum bulunamadı. Lütfen tekrar giriş yap.",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk Akışı 🌍")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostSheet,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gönderiler yüklenirken hata: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "Henüz kimse paylaşım yapmamış.\nİlk sen ol!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final postDoc = docs[index];
              final data = postDoc.data();

              final List likedBy = (data['likedBy'] as List?) ?? [];
              final bool isLiked = likedBy.contains(user.uid);

              final List comments = (data['comments'] as List?) ?? [];

              final message = (data['message'] as String?) ?? '';
              final userName = (data['userName'] as String?) ?? 'Anonim';

              final rawAvatar = data['userAvatar'] as String?;
              final avatar = (rawAvatar != null && rawAvatar.isNotEmpty)
                  ? rawAvatar
                  : 'https://ui-avatars.com/api/?name=$userName';

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatar),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDate(data['date'] as Timestamp?),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (data['activityImage'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Image.network(
                                    data['activityImage'] as String,
                                    width: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    (data['activityLabel'] as String?) ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleLike(
                              postDoc.id,
                              likedBy,
                            ),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            label: Text(
                              "${(data['likes'] as num?)?.toInt() ?? 0} Beğeni",
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showCommentDialog(postDoc),
                            icon: const Icon(
                              Icons.comment,
                              color: Colors.grey,
                            ),
                            label: Text(
                              "${comments.length} Yorum",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
