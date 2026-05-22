import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../widgets/ticket_card.dart';
import '../widgets/stat_widget.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  int _selectedFilterIndex = 0;
  String _searchQuery = '';

  static const Color kPrimary = Color(0xFF5D5FEF);
  final List<String> _filters = ['Tous', 'Ouverts', 'Résolus'];

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

  List<Ticket> _applyFilter(List<Ticket> tickets) {
    List<Ticket> filtered = tickets;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.id.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_selectedFilterIndex) {
      case 1:
        return filtered
            .where((t) => t.status == 'nouveau' || t.status == 'en_cours')
            .toList();
      case 2:
        return filtered
            .where((t) => t.status == 'resolu' || t.status == 'ferme')
            .toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return StreamBuilder<List<Ticket>>(
      stream: ticketProvider.tickets.getClientTickets(widget.clientId),
      builder: (context, snapshot) {
        final allTickets = snapshot.data ?? [];
        final filtered = _applyFilter(allTickets);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 24),
                _buildStatusCards(allTickets),
                const SizedBox(height: 32),
                _buildSearchAndFiltersBar(),
                const SizedBox(height: 16),
                _buildFilterTabs(),
                const SizedBox(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (filtered.isEmpty)
                  _buildEmptyState()
                else
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
          ),
        );
      },
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes tickets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Suivez et gérez vos demandes de support',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/create-ticket'),
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Nouveau ticket',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards(List<Ticket> tickets) {
    final enCours = tickets
        .where((t) => t.status == 'nouveau' || t.status == 'en_cours')
        .length;

    final resolus = tickets
        .where((t) => t.status == 'resolu' || t.status == 'ferme')
        .length;

    return Row(
      children: [
        Expanded(
          child: ClientStatWidget(
            title: 'Tous',
            count: '${tickets.length}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClientStatWidget(
            title: 'En cours',
            count: '$enCours',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClientStatWidget(
            title: 'Résolus',
            count: '$resolus',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFiltersBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Rechercher un ticket (titre, ID...)',
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withAlpha(51),
          ), // 0.2 * 255 ≈ 51
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withAlpha(51),
          ), // 0.2 * 255 ≈ 51
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isActive = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? kPrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? kPrimary : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimary.withAlpha(20), // 0.08 * 255 ≈ 20
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 48,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun ticket trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre premier ticket de support',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/create-ticket'),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Créer un ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
