import 'package:flutter/material.dart';
import 'comment_screen.dart';

class DetailPostScreen extends StatefulWidget {
  // Menerima lemparan data dari Home Screen
  final String postId;
  final String name;
  final String username;
  final String location;
  final String caption;
  final String imageUrl;
  final int likesCount;

  const DetailPostScreen({
    super.key,
    required this.postId,
    required this.name,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageUrl,
    required this.likesCount,
  });

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  bool _isLiked = false;
  late int _currentLikeCount;

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.likesCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    Text(widget.location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Gambar Dinamis
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            
            // Baris Aksi
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _isLiked ? _currentLikeCount++ : _currentLikeCount--;
                    });
                  },
                  child: Column(
                    children: [
                      Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.black87, size: 28),
                      const SizedBox(height: 4),
                      Text('$_currentLikeCount', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CommentScreen(postId: widget.postId)),
                    );
                  },
                  child: _buildActionIcon(Icons.chat_bubble_outline, Colors.black87, 'Balas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Caption Dinamis
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.5),
                children: [
                  TextSpan(text: '${widget.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: widget.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}