import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/ticket_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedPriority = 'moyenne';
  String _selectedCategory = 'Technique';
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];

  static const Color kPrimary = Color(0xFF5D5FEF);

  final List<Map<String, dynamic>> _priorities = [
    {
      'value': 'basse',
      'label': 'Basse',
      'color': Color(0xFF10B981),
      'icon': Icons.arrow_downward_rounded,
    },
    {
      'value': 'moyenne',
      'label': 'Normale',
      'color': Color(0xFFF59E0B),
      'icon': Icons.remove_rounded,
    },
    {
      'value': 'haute',
      'label': 'Haute',
      'color': Color(0xFFEF4444),
      'icon': Icons.arrow_upward_rounded,
    },
  ];

  final List<String> _categories = [
    'Technique',
    'Facturation',
    'Compte',
    'Documents',
    'Autre',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<ap.AuthProvider>().currentUser!;
    final service = context.read<TicketProvider>().tickets;

    final ticketId = await service.createTicket(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory,
      clientId: user.id,
      clientName: user.name,
      attachmentFiles: _selectedFiles,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (ticketId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ticket $ticketId créé avec succès !'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la création du ticket.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Nouveau ticket',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Informations du ticket',
                          Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Titre *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDeco(
                            hint: 'Ex: Problème de connexion',
                            icon: Icons.title_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Veuillez entrer un titre'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Description *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLines: 5,
                          decoration: _inputDeco(
                            hint: 'Décrivez votre problème en détail...',
                            icon: Icons.description_outlined,
                          ).copyWith(alignLabelWithHint: true),
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? 'Minimum 10 caractères'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Classification',
                          Icons.label_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Catégorie'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v!),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Priorité'),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: _priorities.map((p) {
                            final isSelected = _selectedPriority == p['value'];
                            final color = p['color'] as Color;

                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedPriority = p['value'],
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 100,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withAlpha(26)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      p['icon'] as IconData,
                                      color: color,
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p['label'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? color
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Pièces jointes',
                          Icons.attach_file_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildFilePicker(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Envoi en cours...'
                            : 'Soumettre le ticket',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/dashboard'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Sélectionner des fichiers'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: const Color(0xFF374151),
            ),
          ),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withAlpha(13), // 0.05 * 255 ≈ 13
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kPrimary.withAlpha(51),
                  ), // 0.2 * 255 ≈ 51
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 14,
                      color: kPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      file.name.length > 20
                          ? '${file.name.substring(0, 20)}...'
                          : file.name,
                      style: const TextStyle(fontSize: 12, color: kPrimary),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _removeFile(idx),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }
}
