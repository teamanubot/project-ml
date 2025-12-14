class HomeStrings {
  static const homeTitle = 'Beranda';
  static const scanLabel = 'Scan';
  static String welcome(String userName) => 'Selamat datang, ${userName.isNotEmpty ? userName : 'Pasien'}!';
  static const cameraOption = 'Ambil Foto dengan Kamera';
  static const galleryOption = 'Pilih dari Galeri';
  static const noImageTaken = 'Tidak ada gambar diambil';
  static const noImageSelected = 'Tidak ada gambar dipilih';
  static const logoutConfirm = 'Apakah Anda yakin ingin logout?';
  static const noButton = 'Tidak';
  static const yesButton = 'Ya';
  static const historyTitle = 'Riwayat';
  static const analysisTitle = 'Analisis';
  static const profileTitle = 'Profil';
  static const saveButton = 'Simpan';
  static const logoutButton = 'Keluar';
  static const String aboutApp = 'Spine Analyzer membantu Anda memeriksa kemiringan badan dengan teknologi AI. Ambil foto badan dari samping, aplikasi akan membentuk pola garis tubuh dan menghitung derajat kemiringan secara otomatis. Foto dari depan/belakang juga bisa, namun hasil belum seoptimal dari samping.';
  static const String aboutSpineTitle = 'Tentang Kemiringan Badan';
  static const String aboutSpine = 'Kemiringan badan adalah kondisi di mana tubuh condong ke kiri atau ke kanan jika dilihat dari samping. Deteksi dini penting untuk mencegah masalah postur dan kesehatan lebih lanjut.';
  static const String impactTitle = 'Dampak Kemiringan Badan';
  static const String impact = 'Kemiringan badan yang tidak normal dapat menyebabkan nyeri, gangguan pernapasan, keterbatasan gerak, hingga masalah psikologis. Deteksi dan penanganan dini sangat penting untuk mencegah komplikasi lebih lanjut.';
}
