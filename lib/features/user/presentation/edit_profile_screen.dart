import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/custom_button.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/neuro_profile.dart';
import '../domain/models/user_interests.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Basic
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _tagsController;
  List<String> _tags = [];
  String? _gender;

  // Neuro
  int _noiseTolerance = 3;
  int _crowdTolerance = 3;
  int _lightSensitivity = 3;
  int _socialBattery = 3;
  int _structureNeed = 3;
  
  // Preferences
  bool _datingActive = false;
  bool _friendsActive = false;
  
  List<String> _datingGenderInterest = [];
  RangeValues _datingAgeRange = const RangeValues(18, 99);
  double _datingDistance = 50;

  List<String> _friendshipGenderInterest = []; 
  RangeValues _friendshipAgeRange = const RangeValues(18, 99);
  double _friendshipDistance = 50;

  // Interests
  late TextEditingController _interestsController;
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Increased to 4
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _tagsController = TextEditingController();
    _interestsController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _tagsController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _addInterest() {
    final text = _interestsController.text.trim();
    if (text.isNotEmpty && !_interests.contains(text)) {
      setState(() {
        _interests.add(text);
        _interestsController.clear();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    try {
      // 1. AppUser
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _nameController.text = data['displayName'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _gender = data['gender'];
        // Normalize gender
        if (_gender == 'Feminino') _gender = 'Femenino';
        if (!['Femenino', 'Masculino', 'No binario', 'Prefiero no decirlo', 'Otro'].contains(_gender)) {
          _gender = null; 
        }
        _tags = List<String>.from(data['tags'] ?? []);
        
        // Settings
        final settings = data['settings'] ?? {};
        _datingActive = settings['datingActive'] ?? false;
        _friendsActive = settings['friendsActive'] ?? false;
      }

      // 2. NeuroProfile
      final neuroDoc = await FirebaseFirestore.instance.doc('users/${user.uid}/neuroProfile/main').get();
      if (neuroDoc.exists) {
        final neuro = NeuroProfile.fromMap(neuroDoc.data()!);
        _noiseTolerance = neuro.sensory.noiseTolerance;
        _crowdTolerance = neuro.sensory.crowdTolerance;
        _lightSensitivity = neuro.sensory.lightensitivity;
        _socialBattery = neuro.social.socialBattery;
        _structureNeed = neuro.social.needForStructure;
      }

      // 3. Interests
      final interestsDoc = await FirebaseFirestore.instance.doc('users/${user.uid}/interests/main').get();
      if (interestsDoc.exists) {
        final userInterests = UserInterests.fromMap(interestsDoc.data()!);
        _interests = userInterests.tagsDisplay;
      }
      
      // 4. Dating Prefs
      if (_datingActive) {
          final doc = await FirebaseFirestore.instance.doc('users/${user.uid}/datingPreferences/main').get();
          if (doc.exists) {
              final data = doc.data()!;
              _datingGenderInterest = List<String>.from(data['genderInterest'] ?? []);
              _datingDistance = (data['distanceMaxKm'] ?? 50).toDouble();
              final min = data['ageRange']?['min'] ?? 18;
              final max = data['ageRange']?['max'] ?? 99;
              _datingAgeRange = RangeValues(min.toDouble(), max.toDouble());
          }
      }

      // 5. Friendship Prefs
      if (_friendsActive) {
          final doc = await FirebaseFirestore.instance.doc('users/${user.uid}/friendshipPreferences/main').get();
          if (doc.exists) {
              final data = doc.data()!;
              _friendshipGenderInterest = List<String>.from(data['genderInterest'] ?? []); // Reuse field name?
              _friendshipDistance = (data['distanceMaxKm'] ?? 50).toDouble();
              final min = data['ageRange']?['min'] ?? 18;
              final max = data['ageRange']?['max'] ?? 99;
              _friendshipAgeRange = RangeValues(min.toDouble(), max.toDouble());
          }
      }
      
      setState(() {});
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update AppUser
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _gender,
        'tags': _tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. NeuroProfile
      // ... (Same logic as before) ...
      final neuroRef = FirebaseFirestore.instance.doc('users/${user.uid}/neuroProfile/main');
      final neuroDoc = await neuroRef.get();
      CommunicationPreferences comms = const CommunicationPreferences();
      if (neuroDoc.exists) {
          final existing = NeuroProfile.fromMap(neuroDoc.data()!);
          comms = existing.communication;
      }
      final newNeuro = NeuroProfile(
        sensory: SensoryPreferences(
          noiseTolerance: _noiseTolerance,
          crowdTolerance: _crowdTolerance,
          lightensitivity: _lightSensitivity,
        ),
        social: SocialEnergy(
          socialBattery: _socialBattery,
          needForStructure: _structureNeed,
        ),
        communication: comms, 
      );
      batch.set(neuroRef, newNeuro.toMap(), SetOptions(merge: true));

      // 3. Update Interests
       final interestsRef = FirebaseFirestore.instance.doc('users/${user.uid}/interests/main');
      final newInterests = UserInterests(
        tagsDisplay: _interests,
        tagsNormalized: _interests.map((e) => e.toLowerCase()).toList(),
      );
      batch.set(interestsRef, newInterests.toMap(), SetOptions(merge: true));
      
      // 4. Update Preferences
      if (_datingActive) {
          batch.set(FirebaseFirestore.instance.doc('users/${user.uid}/datingPreferences/main'), {
              'genderInterest': _datingGenderInterest,
              'distanceMaxKm': _datingDistance.toInt(),
              'ageRange': {'min': _datingAgeRange.start.toInt(), 'max': _datingAgeRange.end.toInt()},
          }, SetOptions(merge: true));
      }
      if (_friendsActive) {
          batch.set(FirebaseFirestore.instance.doc('users/${user.uid}/friendshipPreferences/main'), {
              'genderInterest': _friendshipGenderInterest,
              'distanceMaxKm': _friendshipDistance.toInt(),
              'ageRange': {'min': _friendshipAgeRange.start.toInt(), 'max': _friendshipAgeRange.end.toInt()},
          }, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        ref.refresh(currentUserProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        context.pop();
      }
    } catch (e) {
// ...
      if (mounted) {
        showDialog(
          context: context, 
          builder: (c) => AlertDialog(
            title: const Text("Error Guardando"),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => context.pop(), child: const Text("OK"))],
          )
        );
      }
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
  


  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("$value/5", style: TextStyle(color: Theme.of(context).primaryColor)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toString(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildChipEditor(String label, TextEditingController controller, List<String> items, VoidCallback onAdd, ValueChanged<String> onDelete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
         const SizedBox(height: 8),
         Row(
           children: [
             Expanded(
               child: CustomTextField(
                 label: "Agregar nuevo...",
                 controller: controller,
               ),
             ),
             IconButton(icon: const Icon(Icons.add_circle), onPressed: onAdd),
           ],
         ),
         const SizedBox(height: 8),
         Wrap(
           spacing: 8,
           children: items.map((item) => Chip(
             label: Text(item),
             onDeleted: () => onDelete(item),
           )).toList(),
         )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Básico"),
            Tab(text: "Neuro"),
            Tab(text: "Intereses"),
            Tab(text: "Ajustes"),
          ],
        ),
         actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Basic
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      label: "Nombre para mostrar",
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
                        label: "Biografía",
                        controller: _bioController,
                        maxLines: 4,
                    ),
                     const SizedBox(height: 16),
                     _buildChipEditor(
                       "Tags / Etiquetas", 
                       _tagsController, 
                       _tags, 
                       _addTag, 
                       (item) => setState(() => _tags.remove(item))
                     ),
                  ],
                ),
              ),

              // 2. Neuro
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Preferencias Sensoriales", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildSlider("Tolerancia al Ruido", _noiseTolerance, (v) => setState(() => _noiseTolerance = v)),
                    _buildSlider("Tolerancia a Multitudes", _crowdTolerance, (v) => setState(() => _crowdTolerance = v)),
                    _buildSlider("Sensibilidad a la Luz", _lightSensitivity, (v) => setState(() => _lightSensitivity = v)),
                    const Divider(height: 32),
                     Text("Energía Social", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildSlider("Batería Social", _socialBattery, (v) => setState(() => _socialBattery = v)),
                    _buildSlider("Necesidad de Estructura", _structureNeed, (v) => setState(() => _structureNeed = v)),
                  ],
                ),
              ),

              // 3. Interests
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                     _buildChipEditor(
                       "Intereses y Hobbies", 
                       _interestsController, 
                       _interests, 
                       _addInterest, 
                       (item) => setState(() => _interests.remove(item))
                     ),
                     const SizedBox(height: 16),
                     const Text("Nota: Los límites (Dealbreakers) se gestionarán en una pantalla avanzada.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              // 4. Ajustes (Preferencias)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (_datingActive) ...[
                            Text("Preferencias de Citas", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                            const SizedBox(height: 16),
                            const Text("Me interesan:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(spacing: 8, children: [
                                _buildFilterChip("Mujeres", "mujeres", _datingGenderInterest, (l) => setState(() => _datingGenderInterest = l)),
                                _buildFilterChip("Hombres", "hombres", _datingGenderInterest, (l) => setState(() => _datingGenderInterest = l)),
                                _buildFilterChip("No binario", "no_binario_otres", _datingGenderInterest, (l) => setState(() => _datingGenderInterest = l)),
                                _buildFilterChip("Todos", "sin_preferencia", _datingGenderInterest, (l) => setState(() => _datingGenderInterest = l)),
                            ]),
                            const SizedBox(height: 16),
                            Text("Rango de Edad: ${_datingAgeRange.start.round()} - ${_datingAgeRange.end.round()} años"),
                            RangeSlider(
                                values: _datingAgeRange,
                                min: 18, max: 99,
                                divisions: 81,
                                labels: RangeLabels(_datingAgeRange.start.round().toString(), _datingAgeRange.end.round().toString()),
                                onChanged: (v) => setState(() => _datingAgeRange = v),
                            ),
                            const SizedBox(height: 16),
                            Text("Distancia Máxima: ${_datingDistance.round()} km"),
                            Slider(value: _datingDistance, min: 5, max: 200, divisions: 39, onChanged: (v) => setState(() => _datingDistance = v)),
                            const Divider(height: 32),
                        ],
                        if (_friendsActive) ...[
                             Text("Preferencias de Amistad", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
                            const SizedBox(height: 16),
                            const Text("Me interesan (Amistad):", style: TextStyle(fontWeight: FontWeight.bold)),
                             Wrap(spacing: 8, children: [
                                _buildFilterChip("Mujeres", "mujeres", _friendshipGenderInterest, (l) => setState(() => _friendshipGenderInterest = l)),
                                _buildFilterChip("Hombres", "hombres", _friendshipGenderInterest, (l) => setState(() => _friendshipGenderInterest = l)),
                                _buildFilterChip("No binario", "no_binario_otres", _friendshipGenderInterest, (l) => setState(() => _friendshipGenderInterest = l)),
                                _buildFilterChip("Todos", "sin_preferencia", _friendshipGenderInterest, (l) => setState(() => _friendshipGenderInterest = l)),
                            ]),
                            const SizedBox(height: 16),
                            Text("Rango de Edad: ${_friendshipAgeRange.start.round()} - ${_friendshipAgeRange.end.round()} años"),
                            RangeSlider(
                                values: _friendshipAgeRange,
                                min: 18, max: 99,
                                divisions: 81,
                                labels: RangeLabels(_friendshipAgeRange.start.round().toString(), _friendshipAgeRange.end.round().toString()),
                                onChanged: (v) => setState(() => _friendshipAgeRange = v),
                            ),
                            const SizedBox(height: 16),
                            Text("Distancia Máxima: ${_friendshipDistance.round()} km"),
                            Slider(value: _friendshipDistance, min: 5, max: 200, divisions: 39, onChanged: (v) => setState(() => _friendshipDistance = v)),
                        ]
                    ],
                ),
              )
            ],
          ),
        ),
    );
  }
  Widget _buildFilterChip(String label, String value, List<String> currentList, Function(List<String>) onUpdate) {
      final selected = currentList.contains(value);
      return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (bool s) {
              final newList = List<String>.from(currentList);
              if (s) {
                 newList.add(value);
              } else {
                 newList.remove(value);
              }
              onUpdate(newList);
          }
      );
  }
}
