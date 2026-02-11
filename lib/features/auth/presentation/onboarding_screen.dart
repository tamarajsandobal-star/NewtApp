import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/custom_button.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';
import '../../user/domain/models/app_user.dart';
import '../data/auth_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  DateTime? _dob;
  String? _selectedGender;
  final _bioController = TextEditingController();
  bool _isLoading = false;

  final List<String> _genderOptions = [
    'Femenino', // Fixed typo
    'Masculino',
    'No binario',
    'Prefiero no decirlo',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'), // Attempt to set locale if supported, else defaults
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dob == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu fecha de nacimiento')),
      );
      return;
    }

    final age = _calculateAge(_dob!);
    if (age < 18) {
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           title: const Text("Restricción de Edad"),
           content: const Text("Debes tener al menos 18 años para usar Newt."),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(ctx).pop(),
               child: const Text("OK"),
             )
           ],
         ),
       );
       return;
    }

    if (_selectedGender == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu género')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final username = _usernameController.text.trim().toLowerCase();
      
      // Check Uniqueness
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameCheck.docs.isNotEmpty) {
         if (usernameCheck.docs.first.id != user.uid) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El nombre de usuario ya existe. Por favor elige otro.')),
             );
             setState(() => _isLoading = false);
             return;
         }
      }

      // Create base user
      final appUser = AppUser(
        uid: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        username: username,
        displayName: _nameController.text.trim(),
        birthDate: _dob, // Fix: Use birthDate, not age
        gender: _selectedGender,
        bio: _bioController.text.trim(),
        tags: [], 
        photoUrl: user.photoURL, 
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap());

      if (mounted) context.go('/mode-selection'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración de Perfil")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                     Text("Detalles Básicos", style: Theme.of(context).textTheme.titleLarge),
                     const SizedBox(height: 8),
                     Text("Estos detalles son obligatorios para usar Newt.", style: Theme.of(context).textTheme.bodyMedium),
                     const SizedBox(height: 24),
                     
                     CustomTextField(
                       label: 'Nombre (ej. Alex)',
                       controller: _nameController,
                       validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                     ),
                     const SizedBox(height: 12),
                     
                     CustomTextField(
                       label: 'Usuario Único (@usuario)',
                       controller: _usernameController,
                       validator: (v) {
                         if (v == null || v.isEmpty) return 'Obligatorio';
                         if (v.length < 3) return 'Al menos 3 caracteres';
                         if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Solo letras, números y guión bajo';
                         return null;
                       },
                     ),
                     const SizedBox(height: 12),
                     
                     // Date of Birth Picker
                     InkWell(
                       onTap: () => _selectDate(context),
                       child: InputDecorator(
                         decoration: InputDecoration(
                           labelText: 'Fecha de Nacimiento (+18)',
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                           filled: true,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                         ),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               _dob == null 
                                 ? 'Seleccionar Fecha' 
                                 : '${_dob!.day}/${_dob!.month}/${_dob!.year} (${_calculateAge(_dob!)} años)',
                               style: _dob == null ? TextStyle(color: Theme.of(context).hintColor) : null,
                             ),
                             const Icon(Icons.calendar_today),
                           ],
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     
                     // Gender Dropdown
                     DropdownButtonFormField<String>(
                       value: _selectedGender,
                       decoration: InputDecoration(
                         labelText: 'Género',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         filled: true,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                       ),
                       items: _genderOptions.map((String value) {
                         return DropdownMenuItem<String>(
                           value: value,
                           child: Text(value),
                           );
                       }).toList(),
                       onChanged: (newValue) {
                         setState(() {
                           _selectedGender = newValue;
                         });
                       },
                       validator: (v) => v == null ? 'Obligatorio' : null,
                     ),

                     const SizedBox(height: 12),
                     
                     CustomTextField(
                        label: 'Biografía',
                        controller: _bioController,
                        maxLines: 3,
                     ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CustomButton(
                  text: "Siguiente: Selección de Modo",
                  onPressed: _completeSetup,
                  isLoading: _isLoading,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
