import 'package:flutter/material.dart';

enum SnackbarType { info, success, error, warning }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final color = _getColor(type);
    final icon = _getIcon(type);
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                fontSize: 16,
                letterSpacing: 0.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      duration: duration,
      elevation: 6,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return const Color(0xFF4CAF50); // Green
      case SnackbarType.error:
        return const Color(0xFFD32F2F); // Red
      case SnackbarType.warning:
        return const Color(0xFFFFA000); // Amber
      case SnackbarType.info:
      default:
        return const Color(0xFF1976D2); // Blue (hospital style)
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.warning:
        return Icons.warning_amber_rounded;
      case SnackbarType.info:
      default:
        return Icons.info_outline;
    }
  }
}
