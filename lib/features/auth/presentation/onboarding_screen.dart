import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/custom_button.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';
import '../../user/domain/user_model.dart';
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
  final _genderController = TextEditingController(); // We'll use this to store the dropdown value or just use a variable
  String? _selectedGender;
  final _bioController = TextEditingController();
  
  final List<String> _selectedTags = [];
  String _goal = 'both'; // dating, friends, both
  bool _isLoading = false;

  final List<String> _tags = [
    'Gaming', 'Reading', 'Nature', 'Art', 'Music', 'Tech', 
    'Cooking', 'Quiet Spaces', 'Anime', 'Movies', 'Coding', 
    'Pets', 'Writing', 'History', 'Science'
  ];

  final List<String> _genderOptions = [
    'Feminino',
    'Masculino',
    'No binario',
    'Prefiero no decirlo',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _genderController.dispose();
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
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    if (_selectedGender == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('No authenticated user found');

      final age = _calculateAge(_dob!);
      if (age < 13) { // Minimal check
         throw Exception('You must be at least 13 years old.');
      }

      final username = _usernameController.text.trim().toLowerCase();
      
      // Check Uniqueness
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameCheck.docs.isNotEmpty) {
         // Check if it's NOT the current user (e.g. if editing) - but this is onboarding so user shouldn't exist fully yet or updating
         if (usernameCheck.docs.first.id != user.uid) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Username already taken. Please choose another.')),
             );
             setState(() => _isLoading = false);
             return;
         }
      }

      final appUser = AppUser(
        uid: user.uid,
        username: username,
        displayName: _nameController.text.trim(),
        age: age,
        gender: _selectedGender,
        city: null, // Will be updated via Geolocation later
        bio: _bioController.text.trim(),
        tags: _selectedTags,
        goal: _goal,
        photoUrl: user.photoURL, 
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap());

      if (mounted) context.go('/discovery');
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
      appBar: AppBar(title: const Text("Setup Your Profile")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                     Text("Tell us about yourself", style: Theme.of(context).textTheme.titleLarge),
                     const SizedBox(height: 16),
                     
                     CustomTextField(
                       label: 'Display Name (e.g. Alex)',
                       controller: _nameController,
                       validator: (v) => v!.isEmpty ? 'Required' : null,
                     ),
                     const SizedBox(height: 12),
                     
                     CustomTextField(
                       label: 'Unique Username (@username)',
                       controller: _usernameController,
                       validator: (v) {
                         if (v == null || v.isEmpty) return 'Required';
                         if (v.length < 3) return 'At least 3 characters';
                         if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Only letters, numbers, _';
                         return null;
                       },
                     ),
                     const SizedBox(height: 12),
                     
                     // Date of Birth Picker
                     InkWell(
                       onTap: () => _selectDate(context),
                       child: InputDecorator(
                         decoration: InputDecoration(
                           labelText: 'Date of Birth',
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                           filled: true,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                         ),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               _dob == null 
                                 ? 'Select Date' 
                                 : '${_dob!.day}/${_dob!.month}/${_dob!.year} (${_calculateAge(_dob!)} yo)',
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
                         labelText: 'Gender',
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
                       validator: (v) => v == null ? 'Required' : null,
                     ),

                     const SizedBox(height: 12),
                     
                     CustomTextField(
                        label: 'Bio (Short description)',
                        controller: _bioController,
                        maxLines: 3,
                     ),
                     const SizedBox(height: 24),
        
                     Text("What are you looking for?", style: Theme.of(context).textTheme.titleMedium),
                     const SizedBox(height: 8),
                     SegmentedButton<String>(
                       segments: const [
                         ButtonSegment(value: 'dating', label: Text('Dating')),
                         ButtonSegment(value: 'friends', label: Text('Friends')),
                         ButtonSegment(value: 'both', label: Text('Both')),
                       ], 
                       selected: {_goal},
                       onSelectionChanged: (Set<String> newSelection) {
                         setState(() {
                           _goal = newSelection.first;
                         });
                       },
                     ),
                     const SizedBox(height: 24),
                     
                     Text("Your Interests", style: Theme.of(context).textTheme.titleMedium),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: _tags.map((tag) {
                         final isSelected = _selectedTags.contains(tag);
                         return FilterChip(
                           label: Text(tag),
                           selected: isSelected,
                           onSelected: (bool selected) {
                             setState(() {
                               if (selected) {
                                 _selectedTags.add(tag);
                               } else {
                                 _selectedTags.remove(tag);
                               }
                             });
                           },
                         );
                       }).toList(),
                     ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: CustomButton(
                  text: "Complete Profile",
                  onPressed: _completeOnboarding,
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
