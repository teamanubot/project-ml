
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'history_screen.dart';


class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;
  const HomeScreen({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  String? currentPhotoPath;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _selectedIndex == 2
              ? 'Riwayat Analisis'
              : 'Spine Analyzer',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2), fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1976D2)),
            onPressed: _showLogoutDialog,
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 1) {
            await _handleCameraBar();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan', // Camera/Scan bar
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 2:
        return HistoryScreen(userId: widget.userId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF5F7FA),
            Color(0xFFE3F0FF),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 40, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selamat datang, ${widget.userName.isNotEmpty ? widget.userName : 'Pasien'}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Spine Analyzer adalah aplikasi untuk membantu Anda memeriksa kemiringan tulang punggung (skoliosis) secara mudah dan cepat menggunakan teknologi AI. Cukup foto punggung Anda, aplikasi akan mengidentifikasi tingkat kemiringan secara otomatis.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 22),
                Text(
                  'Apa itu Tulang Punggung?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tulang punggung (spine) adalah struktur utama penopang tubuh manusia yang terdiri dari rangkaian tulang kecil (vertebrae) dan berfungsi melindungi saraf pusat serta menjaga postur dan pergerakan tubuh.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 22),
                Text(
                  'Dampak Kemiringan Berlebihan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 6),
                Text(
                  'Kemiringan tulang punggung yang tidak normal (skoliosis) dapat menyebabkan nyeri punggung, gangguan pernapasan, keterbatasan gerak, hingga masalah psikologis. Deteksi dan penanganan dini sangat penting untuk mencegah komplikasi lebih lanjut.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // CAMERA BAR: Open camera, with option to pick from gallery
  Future<void> _handleCameraBar() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(Duration.zero);
                  await _handleCameraClick();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF43A047)),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(Duration.zero);
                  await _openGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCameraClick() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => currentPhotoPath = photo.path);
        _openAnalysisScreen(imagePath: photo.path);
      } else {
        _showToast('Tidak ada gambar diambil');
      }
    } catch (e) {
      _showToast('Gagal membuka kamera: $e');
    }
  }

  Future<void> _openGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _openAnalysisScreen(imageUri: image.path);
      } else {
        _showToast('Tidak ada gambar dipilih');
      }
    } catch (e) {
      _showToast('Gagal membuka galeri: $e');
    }
  }


  void _openAnalysisScreen({String? imagePath, String? imageUri}) {
    Navigator.pushNamed(
      context,
      '/analysis',
      arguments: {
        'userId': widget.userId,
        if (imagePath != null) 'imagePath': imagePath,
        if (imageUri != null) 'imageUri': imageUri,
      },
    );
  }


  // void _openHistory() {
  //   Navigator.pushNamed(context, '/history', arguments: {'userId': widget.userId});
  // }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement logout logic (clear session, navigate to login)
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }


  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
