import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart' as ap;
import 'ticket_list_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _selectedIndex = 0;

  static const Color kPrimary = Color(0xFF5D5FEF);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<ap.AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SupportDesk',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Espace Client',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton(
              icon: const Icon(Icons.account_circle_rounded, color: kPrimary),
              itemBuilder: (context) => <PopupMenuEntry<int>>[
                PopupMenuItem<int>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Client',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Text(
                        'Client',
                        style: TextStyle(
                          fontSize: 11,
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  value: 1,
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                  onTap: () async {
                    final router = GoRouter.of(context);
                    await authProvider.signOut();
                    
                    if (!mounted) return;
                    router.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: user != null
            ? TicketListScreen(clientId: user.id)
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8,
        backgroundColor: Colors.white,
        selectedItemColor: kPrimary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            context.go('/create-ticket');
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Mes tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Créer',
          ),
        ],
      ),
    );
  }

}
