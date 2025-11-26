import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response as List);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchQuery.isEmpty ||
            (user['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (user['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final matchesRole = _roleFilter == 'all' || user['role'] == _roleFilter;
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role berhasil diubah menjadi $newRole'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Manajemen Pengguna',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Search Bar
                GlassTextField(
                  hint: 'Cari nama atau email...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 16),
                
                // Role Filter
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _RoleFilterTab(
                        label: 'Semua',
                        isSelected: _roleFilter == 'all',
                        onTap: () {
                          setState(() => _roleFilter = 'all');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoleFilterTab(
                        label: 'Admin',
                        isSelected: _roleFilter == 'admin',
                        onTap: () {
                          setState(() => _roleFilter = 'admin');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoleFilterTab(
                        label: 'Artist',
                        isSelected: _roleFilter == 'artist',
                        onTap: () {
                          setState(() => _roleFilter = 'artist');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoleFilterTab(
                        label: 'Organizer',
                        isSelected: _roleFilter == 'organizer',
                        onTap: () {
                          setState(() => _roleFilter = 'organizer');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoleFilterTab(
                        label: 'Viewer',
                        isSelected: _roleFilter == 'viewer',
                        onTap: () {
                          setState(() => _roleFilter = 'viewer');
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} pengguna ditemukan',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Users Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pengguna ditemukan',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 1400
                              ? 4
                              : constraints.maxWidth > 1000
                                  ? 3
                                  : constraints.maxWidth > 600
                                      ? 2
                                      : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _UserCard(
                                user: user,
                                onRoleChange: (newRole) => _updateUserRole(
                                  user['id'].toString(),
                                  newRole,
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleFilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(String) onRoleChange;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _isHovered = false;

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'artist':
        return const Color(0xFF8B5CF6);
      case 'organizer':
        return const Color(0xFF3B82F6);
      case 'viewer':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'artist':
        return Icons.palette;
      case 'organizer':
        return Icons.event;
      case 'viewer':
      default:
        return Icons.person;
    }
  }

  void _showRoleChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ubah Role',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user['name'] ?? 'Unknown User',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ...[
                {'role': 'admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings},
                {'role': 'artist', 'label': 'Artist', 'icon': Icons.palette},
                {'role': 'organizer', 'label': 'Organizer', 'icon': Icons.event},
                {'role': 'viewer', 'label': 'Viewer', 'icon': Icons.person},
              ].map((roleData) {
                final isCurrentRole = widget.user['role'] == roleData['role'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      text: roleData['label'] as String,
                      icon: roleData['icon'] as IconData,
                      onPressed: isCurrentRole
                          ? () {}
                          : () {
                              Navigator.pop(context);
                              widget.onRoleChange(roleData['role'] as String);
                            },
                      type: isCurrentRole
                          ? GlassButtonType.outline
                          : GlassButtonType.primary,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] ?? 'viewer';
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRoleColor(role),
                          _getRoleColor(role).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: widget.user['profile_image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              widget.user['profile_image_url'],
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            _getRoleIcon(role),
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRoleColor(role),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: _getRoleColor(role),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                widget.user['name'] ?? 'Unknown User',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Email
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    color: Colors.white54,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.user['email'] ?? 'No email',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (widget.user['specialization'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.user['specialization'],
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const Spacer(),
              
              // Change Role Button
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: 'Ubah Role',
                  onPressed: _showRoleChangeDialog,
                  type: GlassButtonType.outline,
                  icon: Icons.swap_horiz,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
