import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';

class BasicInfoEditorScreen extends ConsumerStatefulWidget {
  const BasicInfoEditorScreen({super.key});

  @override
  ConsumerState<BasicInfoEditorScreen> createState() => _BasicInfoEditorScreenState();
}

class _BasicInfoEditorScreenState extends ConsumerState<BasicInfoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _tagsController;
  List<String> _tags = []; // "Intereses visibles"
  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _tagsController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProfileProvider).value;
    print("DEBUG: BasicInfo _loadData called. User is null? ${user == null}");
    if (user != null) {
        _populateParams(user);
    }
  }

  void _populateParams(AppUser user) {
        print("DEBUG: Populating BasicInfo. Name: ${user.displayName}, Bio: ${user.bio}, Tags: ${user.tags}");
        if (_nameController.text.isEmpty) _nameController.text = user.displayName ?? '';
        if (_bioController.text.isEmpty) _bioController.text = user.bio ?? '';
        if (_gender == null) {
            _gender = user.gender;
             // Normalize gender legacy
            if (_gender == 'Feminino') _gender = 'Femenino';
            if (!['Femenino', 'Masculino', 'No binario', 'Prefiero no decirlo', 'Otro'].contains(_gender)) {
               if (_gender != null) _gender = 'Otro'; 
               else _gender = null;
            }
        }
        if (_tags.isEmpty) _tags = List.from(user.tags);
        setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'displayName': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'gender': _gender,
            'tags': _tags,
            'updatedAt': FieldValue.serverTimestamp(),
        });
        
        ref.refresh(currentUserProfileProvider);
        if (mounted) context.pop();
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag() {
      final text = _tagsController.text.trim();
      if (text.isNotEmpty && !_tags.contains(text)) {
          setState(() {
              _tags.add(text);
              _tagsController.clear();
          });
      }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(currentUserProfileProvider, (previous, next) {
        if (next.value != null && (previous?.value == null)) {
             _populateParams(next.value!);
        }
    });

    return Scaffold(
      appBar: AppBar(
          title: const Text("Información Básica"),
          actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    children: [
                        CustomTextField(
                           label: "Nombre Visible",
                           controller: _nameController,
                           validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                         DropdownButtonFormField<String>(
                           value: _gender,
                           decoration: InputDecoration(
                             labelText: 'Género',
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                             filled: true,
                           ),
                           items: ['Femenino', 'Masculino', 'No binario', 'Prefiero no decirlo', 'Otro'].map((String value) {
                             return DropdownMenuItem<String>(
                               value: value,
                               child: Text(value),
                               );
                           }).toList(),
                           onChanged: (newValue) => setState(() => _gender = newValue),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                            label: "Bio / Descripción Corta",
                            controller: _bioController,
                            maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text("Intereses Visibles (Hobbies)", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                         Row(
                           children: [
                             Expanded(
                               child: CustomTextField(
                                 label: "Agregar interés...",
                                 controller: _tagsController,
                               ),
                             ),
                             IconButton(icon: const Icon(Icons.add_circle), onPressed: _addTag),
                           ],
                         ),
                         Wrap(
                           spacing: 8,
                           children: _tags.map((tag) => Chip(
                               label: Text(tag),
                               onDeleted: () => setState(() => _tags.remove(tag)),
                           )).toList(),
                         )
                    ],
                ),
            ),
        ),
    );
  }
}
