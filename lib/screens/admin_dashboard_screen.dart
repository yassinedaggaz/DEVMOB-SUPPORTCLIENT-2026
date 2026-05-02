import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/ticket_provider.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import '../widgets/stat_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _filterStatus = 'tous';

  static const Color kPrimary = Color(0xFF5D5FEF);

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.confirmation_number_outlined,
      label: 'Gestion tickets',
    ),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Statistiques'),
    _NavItem(icon: Icons.people_outline_rounded, label: 'Utilisateurs'),
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return const Color(0xFFF59E0B);
      case 'resolu':
        return const Color(0xFF10B981);
      case 'ferme':
        return const Color(0xFF6B7280);
      default:
        return kPrimary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'en_cours':
        return 'En cours';
      case 'resolu':
        return 'Résolu';
      case 'ferme':
        return 'Fermé';
      default:
        return 'Nouveau';
    }
  }

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
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SupportDesk',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<int>(
              itemBuilder: (context) => <PopupMenuEntry<int>>[
                PopupMenuItem<int>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
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
                      Text(
                        user?.role == 'admin'
                            ? 'Administrateur'
                            : 'Agent Support',
                        style: const TextStyle(
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
              // onSelected: (value) {
              // },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ticket>>(
          stream: context.watch<TicketProvider>().tickets.getAllTickets(),
          builder: (context, snapshot) {
            final tickets = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                _buildMobileTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildTicketsTab(tickets),
                      _buildStatsTab(tickets),
                      _buildUsersTab(tickets),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8,
        backgroundColor: Colors.white,
        selectedItemColor: kPrimary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.confirmation_number_outlined),
            label: _navItems[0].label,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_rounded),
            label: _navItems[1].label,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline_rounded),
            label: _navItems[2].label,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un ticket...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsTab(List<Ticket> tickets) {
    var filtered = tickets.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();

        final matches =
            t.title.toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q) ||
            t.clientName.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            (t.assignedToName ?? '').toLowerCase().contains(q);

        if (!matches) return false;
      }

      if (_filterStatus != 'tous' && t.status != _filterStatus) {
        return false;
      }

      return true;
    }).toList();

    final ouverts = tickets
        .where((t) => t.status == 'nouveau' || t.status == 'en_cours')
        .length;
    final enCours = tickets.where((t) => t.status == 'en_cours').length;
    final resolus = tickets.where((t) => t.status == 'resolu').length;
    final haute = tickets.where((t) => t.priority == 'haute').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: StatWidget(
                  label: 'Tickets ouverts',
                  value: '$ouverts',
                  icon: Icons.folder_open_rounded,
                  color: kPrimary,
                ),
              ),
              SizedBox(
                width: 170,
                child: StatWidget(
                  label: 'En cours',
                  value: '$enCours',
                  icon: Icons.timelapse_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(
                width: 170,
                child: StatWidget(
                  label: 'Résolus',
                  value: '$resolus',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              SizedBox(
                width: 170,
                child: StatWidget(
                  label: 'Priorité haute',
                  value: '$haute',
                  icon: Icons.priority_high_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChipBtn('Tous', 'tous'),
                const SizedBox(width: 8),
                _filterChipBtn('Nouveaux', 'nouveau'),
                const SizedBox(width: 8),
                _filterChipBtn('En cours', 'en_cours'),
                const SizedBox(width: 8),
                _filterChipBtn('Résolus', 'resolu'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            SizedBox(
              width: double.infinity, 
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 21),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: Color(0xFFD1D5DB),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun ticket',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                Text(
                  '${filtered.length} ticket(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...filtered.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TicketCard(
                      ticket: t,
                      statusColor: _statusColor(t.status),
                      statusLabel: _statusLabel(t.status),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _filterChipBtn(String label, String value) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(List<Ticket> tickets) {
    final total = tickets.length;
    final nouveau = tickets.where((t) => t.status == 'nouveau').length;
    final enCours = tickets.where((t) => t.status == 'en_cours').length;
    final resolu = tickets.where((t) => t.status == 'resolu').length;
    final ferme = tickets.where((t) => t.status == 'ferme').length;
    final resolvedTickets = tickets
        .where((t) => t.status == 'resolu' || t.status == 'ferme')
        .toList();
    final haute = tickets.where((t) => t.priority == 'haute').length;
    final moyenne = tickets.where((t) => t.priority == 'moyenne').length;
    final basse = tickets.where((t) => t.priority == 'basse').length;

    final Map<String, int> byCategory = {};
    for (final t in tickets) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                child: StatWidget(
                  label: 'Total tickets',
                  value: '$total',
                  icon: Icons.confirmation_number_outlined,
                  color: kPrimary,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatWidget(
                  label: 'Taux de résolution',
                  value: () {
                    if (total == 0) return '0% · Moy. -';
                    final resolutionRatePct = ((resolu + ferme) * 100 ~/ total);
                    if (resolvedTickets.isEmpty) {
                      return '$resolutionRatePct% · Moy. -';
                    }
                    final totalMinutes = resolvedTickets
                        .map(
                          (t) => t.updatedAt.difference(t.createdAt).inMinutes,
                        )
                        .where((m) => m >= 0)
                        .fold<int>(0, (acc, v) => acc + v);
                    final avgMinutes =
                        totalMinutes / resolvedTickets.length.toDouble();
                    if (avgMinutes >= 60 * 24) {
                      final days = avgMinutes / (60 * 24);
                      return '$resolutionRatePct% · Moy. ${days.toStringAsFixed(1)}j';
                    }
                    final hours = avgMinutes / 60;
                    return '$resolutionRatePct% · Moy. ${hours.toStringAsFixed(1)}h';
                  }(),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildBarChart('Par statut', [
            _BarData('Nouveau', nouveau, kPrimary),
            _BarData('En cours', enCours, const Color(0xFFF59E0B)),
            _BarData('Résolu', resolu, const Color(0xFF10B981)),
            _BarData('Fermé', ferme, const Color(0xFF6B7280)),
          ], total),
          const SizedBox(height: 12),
          _buildBarChart('Par priorité', [
            _BarData('Haute', haute, const Color(0xFFEF4444)),
            _BarData('Normale', moyenne, const Color(0xFFF59E0B)),
            _BarData('Basse', basse, const Color(0xFF10B981)),
          ], total),
          const SizedBox(height: 12),
          _buildBarChart(
            'Par catégorie',
            byCategory.entries
                .map(
                  (e) => _BarData(
                    e.key,
                    e.value,
                    [
                      kPrimary,
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      const Color(0xFFEF4444),
                      const Color(0xFF8B5CF6),
                    ][byCategory.keys.toList().indexOf(e.key) % 5],
                  ),
                )
                .toList(),
            total,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, List<_BarData> data, int total) {
    if (data.isEmpty || total == 0) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: data.map((d) {
                          final pct = (d.value / total) * 100;
                          return PieChartSectionData(
                            color: d.color,
                            value: d.value.toDouble(),
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 25,
                            titleStyle: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: d.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${d.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(List<Ticket> tickets) {
    final Map<String, Map<String, dynamic>> clients = {};
    for (final t in tickets) {
      if (!clients.containsKey(t.clientId)) {
        clients[t.clientId] = {'name': t.clientName, 'total': 0, 'ouverts': 0};
      }
      clients[t.clientId]!['total'] =
          (clients[t.clientId]!['total'] as int) + 1;
      if (t.status == 'nouveau' || t.status == 'en_cours') {
        clients[t.clientId]!['ouverts'] =
            (clients[t.clientId]!['ouverts'] as int) + 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Clients actifs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${clients.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (clients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 48,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Aucun client pour le moment.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...clients.entries.map((e) {
                final name = e.value['name'] as String;
                final total = e.value['total'] as int;
                final ouverts = e.value['ouverts'] as int;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: kPrimary.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$total ticket(s) · $ouverts actif(s)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildBadge(
                            '$ouverts',
                            ouverts > 0 ? kPrimary : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                    if (e != clients.entries.last)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  _BarData(this.label, this.value, this.color);
}
