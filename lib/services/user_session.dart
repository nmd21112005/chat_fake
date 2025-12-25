class UserSession {
  // Biến tĩnh để lưu số điện thoại người dùng hiện tại
  static String? currentPhone;

  // Hàm xóa session khi đăng xuất
  static void clear() {
    currentPhone = null;
  }
}