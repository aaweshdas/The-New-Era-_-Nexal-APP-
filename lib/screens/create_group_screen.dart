import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final Set<String> _selectedUsers = {};

  final List<Map<String, String>> _contacts = [
    {
      'id': 'u1',
      'name': 'Aria Storm',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'
    },
    {
      'id': 'u2',
      'name': 'Kai Cyber',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'
    },
    {
      'id': 'u3',
      'name': 'Luna Ray',
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100'
    },
    {
      'id': 'u4',
      'name': 'Nova Chen',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _createGroup() {
    final title = _nameCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a group name', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF135BEC),
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least 1 member', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF135BEC),
        ),
      );
      return;
    }

    Provider.of<MessagesProvider>(context, listen: false).addGroupConversation(
      title,
      'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
      _selectedUsers.toList(),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group "$title" created! 🚀', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00E5FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'NEW GROUP',
                        style: GoogleFonts.rye(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _createGroup,
                        child: Text(
                          'CREATE',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _nameCtrl,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.users, color: Color(0xFF135BEC)),
                  hintText: 'Group Name (e.g. Quantum Syndicate)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT MEMBERS (${_selectedUsers.length})',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  final isSelected = _selectedUsers.contains(contact['id']);

                  return CheckboxListTile(
                    activeColor: const Color(0xFF00E5FF),
                    checkColor: Colors.black,
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedUsers.add(contact['id']!);
                        } else {
                          _selectedUsers.remove(contact['id']);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundImage: NetworkImage(contact['avatar']!),
                    ),
                    title: Text(
                      contact['name']!,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
