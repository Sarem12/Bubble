import 'package:flutter/material.dart';
import 'profile_screen.dart';

/// PublicProfileScreen displays a user profile by delegating to
/// the unified [ProfileScreen]. This reuses the profile screen, header,
/// tabs, and repository while maintaining full backwards compatibility.
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileScreen(userId: widget.userId);
  }
}
