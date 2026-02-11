import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';

class AboutMeEditorScreen extends ConsumerStatefulWidget {
  const AboutMeEditorScreen({super.key});

  @override
  ConsumerState<AboutMeEditorScreen> createState() => _AboutMeEditorScreenState();
}

class _AboutMeEditorScreenState extends ConsumerState<AboutMeEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Questionnaire Data
  final Map<String, int> _answers = {};
  
  // Free Text
  late TextEditingController _descriptionController;

  // Identity Tags
  List<String> _selectedIdentityTags = [];
  
  // Mock Data definitions
  final Map<String, List<String>> _questionCategories = {
      'Comunicación': [
          'Prefiero mensajes directos y claros',
          'Me tomo mi tiempo para responder',
          'Me gusta hablar por teléfono',
          'Valoro mucho la escucha activa',
      ],
      'Social': [
          'Disfruto de grupos grandes',
          'Necesito tiempo a solas para recargar',
          'Prefiero planes espontáneos',
          'Me gusta planificar con anticipación',
      ],
      'Sensorial': [
          'Soy sensible a los ruidos fuertes',
          'Me molestan las luces brillantes',
          'Necesito texturas suaves',
          'Busco estímulos constantes',
      ],
      // Add more as needed to reach 30 usually
  };

  final Map<String, List<String>> _identityTagOptions = {
     'Estilo': ['Casero', 'Aventurero', 'Nocturno', 'Diurno', 'Chill'],
     'Ritmo': ['Lento', 'Rápido', 'Fluctuante'],
     'Social': ['Introvertido', 'Extrovertido', 'Ambivertido'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _descriptionController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProfileProvider).value;
    print("DEBUG: AboutMe _loadData called. User: ${user?.uid}");
    if (user != null) {
        _populateData(user);
    }
  }

  void _populateData(AppUser user) {
        print("DEBUG: Questionnaire size: ${user.questionnaire.length}, Desc: ${user.profileDescription}");
        if (_answers.isEmpty) _answers.addAll(user.questionnaire);
        if (_descriptionController.text.isEmpty) _descriptionController.text = user.profileDescription ?? '';
        if (_selectedIdentityTags.isEmpty) _selectedIdentityTags = List.from(user.identityTags);
        setState(() {});
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'questionnaire': _answers,
            'profileDescription': _descriptionController.text.trim(),
            'identityTags': _selectedIdentityTags,
            'updatedAt': FieldValue.serverTimestamp(),
        });

        ref.refresh(currentUserProfileProvider);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardado correctmente")));
        }
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
        title: const Text("Detalles sobre mí"),
        bottom: TabBar(
            controller: _tabController,
            tabs: const [
                Tab(text: "Cuestionario"),
                Tab(text: "Cómo soy"),
                Tab(text: "Identidad"),
            ],
        ),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
                _buildQuestionnaireTab(),
                _buildFreeTextTab(),
                _buildIdentityTagsTab(),
            ],
        ),
    );
  }

  Widget _buildQuestionnaireTab() {
      return ListView(
          padding: const EdgeInsets.all(16),
          children: [
              const Text("Completar esto mejora la compatibilidad.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 16),
              ..._questionCategories.entries.map((entry) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(entry.key, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          const SizedBox(height: 8),
                          ...entry.value.map((q) => _buildQuestionRow(q)),
                          const Divider(),
                      ],
                  );
              }).toList()
          ],
      );
  }

  Widget _buildQuestionRow(String question) {
      // Create a stable ID for the question (hash or slug)
      // For simplified demo, user full string as key, but normalized
      final key = question.hashCode.toString(); // Weak key but works for now. 
      // Ideally use a stable slug like 'comm_direct_msg'
      
      int val = _answers[key] ?? 3;

      return Column(
          children: [
              Text(question, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      const Text("No", style: TextStyle(fontSize: 12)),
                      Expanded(
                          child: Slider(
                              value: val.toDouble(),
                              min: 1, max: 5, divisions: 4,
                              label: val.toString(),
                              onChanged: (v) => setState(() => _answers[key] = v.round()),
                          ),
                      ),
                      const Text("Sí", style: TextStyle(fontSize: 12)),
                  ],
              ),
              const SizedBox(height: 12),
          ],
      );
  }

  Widget _buildFreeTextTab() {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              children: [
                  const Text("Describe cómo eres, cómo te gusta vincularte, qué te hace bien o mal...", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _descriptionController,
                      maxLines: 15,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Soy una persona que..."
                      ),
                  )
              ],
          ),
      );
  }

  Widget _buildIdentityTagsTab() {
       return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const Text("Etiquetas que te identifican (no hobbies).", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ..._identityTagOptions.entries.map((entry) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                  spacing: 8,
                                  children: entry.value.map((tag) {
                                      final isSelected = _selectedIdentityTags.contains(tag);
                                      return FilterChip(
                                          label: Text(tag),
                                          selected: isSelected,
                                          onSelected: (s) {
                                              setState(() {
                                                  if (s) _selectedIdentityTags.add(tag);
                                                  else _selectedIdentityTags.remove(tag);
                                              });
                                          },
                                      );
                                  }).toList(),
                              ),
                              const SizedBox(height: 16),
                          ],
                      );
                  }).toList()
              ],
          ),
      );
  }
}
