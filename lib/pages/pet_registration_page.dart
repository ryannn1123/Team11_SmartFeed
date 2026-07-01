import 'package:flutter/material.dart';
import '../main.dart';

class PetRegistrationPage extends StatefulWidget {
  const PetRegistrationPage({super.key});

  @override
  State<PetRegistrationPage> createState() => _PetRegistrationPageState();
}

class _PetRegistrationPageState extends State<PetRegistrationPage> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();

  String _petType = 'Dog';
  bool _loading = false;
  bool _fetching = true;
  int? _editingPetId;

  List<Map<String, dynamic>> _pets = [];

  static const Color coral = Color(0xFFFF9E89);
  static const Color peach = Color(0xFFFFBFA3);
  static const Color cream = Color(0xFFFFEFC4);
  static const Color dark = Color(0xFF172033);
  static const Color muted = Color(0xFF7A8292);

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPets() async {
    setState(() => _fetching = true);

    try {
      final userId = supabase.auth.currentUser?.id;

      final res = await supabase
          .from('pets')
          .select()
          .eq('owner_id', userId as Object)
          .order('id', ascending: false);

      setState(() {
        _pets = List<Map<String, dynamic>>.from(res);
        _fetching = false;
      });
    } catch (e) {
      setState(() => _fetching = false);
      _showMessage('Error loading pets: $e');
    }
  }

  Future<void> _showRegisterDialog() async {
    _clearForm();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PetFormDialog(
        title: 'Register New Pet',
        buttonText: 'Register Pet',
        nameController: _nameController,
        breedController: _breedController,
        ageController: _ageController,
        petType: _petType,
        loading: _loading,
        onPetTypeChanged: (value) {
          _petType = value;
        },
        onSubmit: () async {
          final success = await _savePet();
          if (success && mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> pet) async {
    setState(() {
      _editingPetId = pet['id'] as int;
      _nameController.text = pet['pet_name']?.toString() ?? '';
      _petType = pet['pet_type']?.toString() ?? 'Dog';
      _breedController.text = pet['breed']?.toString() ?? '';
      _ageController.text = pet['age']?.toString() ?? '';
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PetFormDialog(
        title: 'Edit Pet',
        buttonText: 'Save Changes',
        nameController: _nameController,
        breedController: _breedController,
        ageController: _ageController,
        petType: _petType,
        loading: _loading,
        onPetTypeChanged: (value) {
          _petType = value;
        },
        onSubmit: () async {
          final success = await _savePet();
          if (success && mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<bool> _savePet() async {
    if (_nameController.text.trim().isEmpty ||
        _breedController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty) {
      _showMessage('Please complete all fields.');
      return false;
    }

    setState(() => _loading = true);

    try {
      final data = {
        'owner_id': supabase.auth.currentUser?.id,
        'pet_name': _nameController.text.trim(),
        'pet_type': _petType,
        'breed': _breedController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
      };

      if (_editingPetId == null) {
        await supabase.from('pets').insert(data);
        _showMessage('Pet registered successfully 🐾');
      } else {
        await supabase.from('pets').update(data).eq('id', _editingPetId as int);
        _showMessage('Pet updated successfully 🐾');
      }

      _clearForm();
      await _fetchPets();
      return true;
    } catch (e) {
      _showMessage('Error: $e');
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePet(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete pet?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('This pet profile will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('pets').delete().eq('id', id);
      await _fetchPets();
      _showMessage('Pet deleted.');
    } catch (e) {
      _showMessage('Error deleting pet: $e');
    }
  }

  void _clearForm() {
    setState(() {
      _editingPetId = null;
      _nameController.clear();
      _breedController.clear();
      _ageController.clear();
      _petType = 'Dog';
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [coral, peach, cream],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: coral,
            onRefresh: _fetchPets,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
              children: [
                const Center(
                  child: Text(
                    'My Pets',
                    style: TextStyle(
                      color: dark,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showRegisterDialog,
                    icon: const Icon(Icons.pets_rounded),
                    label: const Text(
                      'Register a Pet',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: coral,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pets_rounded, color: coral),
                      const SizedBox(width: 10),
                      Text(
                        '${_pets.length} Registered Pets',
                        style: const TextStyle(
                          color: dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (_fetching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: coral),
                    ),
                  )
                else if (_pets.isEmpty)
                  _emptyState()
                else
                  ..._pets.map((pet) => _petCard(pet)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.pets_rounded, size: 56, color: coral),
          SizedBox(height: 12),
          Text(
            'No pets yet',
            style: TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap “Register a Pet” to add your first pet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _petCard(Map<String, dynamic> pet) {
    final id = pet['id'] as int;
    final name = pet['pet_name']?.toString() ?? 'Pet';
    final type = pet['pet_type']?.toString() ?? 'Pet';
    final breed = pet['breed']?.toString() ?? '';
    final age = pet['age']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: peach.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.pets_rounded, color: coral, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $breed • $age yrs',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'edit') _showEditDialog(pet);
              if (value == 'delete') _deletePet(id);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18, color: coral),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _PetFormDialog extends StatefulWidget {
  final String title;
  final String buttonText;
  final TextEditingController nameController;
  final TextEditingController breedController;
  final TextEditingController ageController;
  final String petType;
  final bool loading;
  final ValueChanged<String> onPetTypeChanged;
  final Future<void> Function() onSubmit;

  const _PetFormDialog({
    required this.title,
    required this.buttonText,
    required this.nameController,
    required this.breedController,
    required this.ageController,
    required this.petType,
    required this.loading,
    required this.onPetTypeChanged,
    required this.onSubmit,
  });

  @override
  State<_PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<_PetFormDialog> {
  late String _selectedPetType;

  static const Color coral = Color(0xFFFF9E89);
  static const Color peach = Color(0xFFFFBFA3);
  static const Color cream = Color(0xFFFFEFC4);
  static const Color dark = Color(0xFF172033);
  static const Color muted = Color(0xFF7A8292);

  @override
  void initState() {
    super.initState();
    _selectedPetType = widget.petType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFDF9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: dark,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(
              controller: widget.nameController,
              label: 'Pet Name',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedPetType,
              decoration: _inputDecoration(
                label: 'Pet Type',
                icon: Icons.pets_rounded,
              ),
              items: const [
                DropdownMenuItem(value: 'Dog', child: Text('🐶 Dog')),
                DropdownMenuItem(value: 'Cat', child: Text('🐱 Cat')),
                DropdownMenuItem(value: 'Bird', child: Text('🐦 Bird')),
                DropdownMenuItem(value: 'Rabbit', child: Text('🐰 Rabbit')),
                DropdownMenuItem(value: 'Other', child: Text('🐾 Other')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() => _selectedPetType = value);
                widget.onPetTypeChanged(value);
              },
            ),
            const SizedBox(height: 14),
            _input(
              controller: widget.breedController,
              label: 'Breed',
              icon: Icons.category_rounded,
            ),
            const SizedBox(height: 14),
            _input(
              controller: widget.ageController,
              label: 'Age',
              icon: Icons.cake_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        TextButton(
          onPressed: widget.loading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: muted),
          ),
        ),
        FilledButton.icon(
          onPressed: widget.loading ? null : widget.onSubmit,
          icon: widget.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.pets_rounded),
          label: Text(widget.buttonText),
          style: FilledButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: coral),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: muted),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: coral.withOpacity(0.18)),
      ),
    );
  }
}