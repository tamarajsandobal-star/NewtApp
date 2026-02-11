import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';

class NeuroEditorScreen extends ConsumerStatefulWidget {
  const NeuroEditorScreen({super.key});

  @override
  ConsumerState<NeuroEditorScreen> createState() => _NeuroEditorScreenState();
}

class _NeuroEditorScreenState extends ConsumerState<NeuroEditorScreen> {
  final List<String> _neuroTypes = ['TDAH', 'Autismo', 'Dislexia', 'PAS', 'Altas Capacidades', 'Otro'];
  final List<String> _selected = [];
  String? _otherText;
  NeurodivergenceVisibility _visibility = NeurodivergenceVisibility.public;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
        _populateData(user);
    }
  }

  void _populateData(AppUser user) {
      if (_selected.isEmpty) _selected.addAll(user.neurodivergence.selected);
      if (_otherText == null) _otherText = user.neurodivergence.otherText;
      _visibility = user.neurodivergence.visibility;
      setState(() {});
  }

  Future<void> _save() async {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user == null) return;
        
        final nd = UserNeurodivergence(
            selected: _selected,
            otherText: _otherText,
            visibility: _visibility
        );

        // Map it manually since AppUser.fromMap handles it but user object inside AppUser is immutableish
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'neurodivergence': { // Save as map
                'selected': nd.selected,
                'otherText': nd.otherText,
                'visibility': nd.visibility.name,
            }
        });
        
        ref.refresh(currentUserProfileProvider);
        if (mounted) context.pop();
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(currentUserProfileProvider, (previous, next) {
         if (next.value != null && (previous?.value == null)) {
             _populateData(next.value!);
         }
    });

    return Scaffold(
        appBar: AppBar(
            title: const Text("Neurodivergencia"),
            actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
                const Text("Selecciona lo que aplique (Opcional)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 8,
                    children: _neuroTypes.map((type) {
                        final isSelected = _selected.contains(type);
                        return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (s) {
                                setState(() {
                                    if (s) _selected.add(type);
                                    else _selected.remove(type);
                                });
                            },
                        );
                    }).toList(),
                ),
                if (_selected.contains('Otro')) ...[
                    const SizedBox(height: 16),
                    TextField(
                        decoration: const InputDecoration(labelText: "Especificar otro"),
                        onChanged: (v) => _otherText = v,
                        controller: TextEditingController(text: _otherText),
                    )
                ],
                const Divider(height: 32),
                const Text("Visibilidad", style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<NeurodivergenceVisibility>(
                    title: const Text("Público"),
                    value: NeurodivergenceVisibility.public,
                    groupValue: _visibility,
                    onChanged: (v) => setState(() => _visibility = v!),
                ),
                RadioListTile<NeurodivergenceVisibility>(
                    title: const Text("Solo Algoritmo"),
                    subtitle: const Text("No se muestra en el perfil, pero se usa para matching."),
                    value: NeurodivergenceVisibility.algorithm_only,
                    groupValue: _visibility,
                    onChanged: (v) => setState(() => _visibility = v!),
                ),
                RadioListTile<NeurodivergenceVisibility>(
                    title: const Text("Oculto"),
                    value: NeurodivergenceVisibility.hidden,
                    groupValue: _visibility,
                    onChanged: (v) => setState(() => _visibility = v!),
                ),
            ],
        )
    );
  }
}
