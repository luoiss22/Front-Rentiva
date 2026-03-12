import 'package:flutter/material.dart';
import 'user_profile_modal.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final String userInitials;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.userInitials = 'JS',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF225378),
      elevation: 4,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 24),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (!showBack) ...[

          // Botón Notificaciones con punto naranja
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/notificaciones'),
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 20),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB7F00),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF225378), width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          // Avatar → abre UserProfileModal como Dialog
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showUserProfile(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1695A3),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFACF0F2), width: 2),
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showUserProfile(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const UserProfileModal(),
    );
  }
}