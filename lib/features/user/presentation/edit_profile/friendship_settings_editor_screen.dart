import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_preferences.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';

class FriendshipSettingsEditorScreen extends ConsumerStatefulWidget {
  const FriendshipSettingsEditorScreen({super.key});

  @override
  ConsumerState<FriendshipSettingsEditorScreen> createState() => _FriendshipSettingsEditorScreenState();
}

class _FriendshipSettingsEditorScreenState extends ConsumerState<FriendshipSettingsEditorScreen> {
  // Friendship Prefs state
  List<GenderInterest> _genderInterest = [];
  RangeValues _ageRange = const RangeValues(18, 99);
  double _distance = 50;
  FriendshipMeetMode _meetMode = FriendshipMeetMode.flexible;
  ContactFrequency _frequency = ContactFrequency.flexible;
  final TextEditingController _styleController = TextEditingController();
  List<String> _styles = [];

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
     if (user.friendshipPreferences != null) {
        final p = user.friendshipPreferences!;
        if (_genderInterest.isEmpty) _genderInterest = List.from(p.genderInterest);
        _ageRange = RangeValues(p.ageRange.min.toDouble(), p.ageRange.max.toDouble());
        _distance = p.distanceMaxKm.toDouble();
        _meetMode = p.meetMode;
        _frequency = p.contactFrequency;
        if (_styles.isEmpty) _styles = List.from(p.friendshipStyle);
        setState(() {});
     }
  }

  Future<void> _save() async {
      setState(() => _isLoading = true);
      try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) return;

          final prefs = FriendshipPreferences(
              genderInterest: _genderInterest,
              ageRange: AgeRange(min: _ageRange.start.round(), max: _ageRange.end.round()),
              distanceMaxKm: _distance.round(),
              meetMode: _meetMode,
              contactFrequency: _frequency,
              friendshipStyle: _styles,
          );

          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('friendshipPreferences').doc('main').set(prefs.toMap());
          
          ref.refresh(currentUserProfileProvider);
          if (mounted) context.pop();
      } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  void _addStyle() {
      final t = _styleController.text.trim();
      if (t.isNotEmpty && !_styles.contains(t)) {
          setState(() {
              _styles.add(t);
              _styleController.clear();
          });
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
            title: const Text("Ajustes de Amistad"),
            actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
                _buildGenderSelector(),
                const Divider(),
                _buildAgeSlider(),
                const Divider(),
                _buildDistanceSlider(),
                const Divider(),
                _buildDropdown("Modalidad de Encuentro", FriendshipMeetMode.values, _meetMode, (v) => setState(() => _meetMode = v)),
                const SizedBox(height: 16),
                _buildDropdown("Frecuencia de Contacto", ContactFrequency.values, _frequency, (v) => setState(() => _frequency = v)),
                const Divider(),
                Text("Estilo de Amistad (Tags)", style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                    Expanded(child: CustomTextField(controller: _styleController, label: "Jugar, Charlar, Deporte...")),
                    IconButton(icon: const Icon(Icons.add_circle), onPressed: _addStyle),
                ]),
                Wrap(spacing: 8, children: _styles.map((e) => Chip(label: Text(e), onDeleted: () => setState(() => _styles.remove(e)))).toList())
            ],
        )
    );
  }

  Widget _buildDropdown<T extends Enum>(String label, List<T> values, T current, Function(T) onChanged) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<T>(
                  value: current,
                  isExpanded: true,
                  items: values.map((e) => DropdownMenuItem(
                      value: e, child: Text(e.name.replaceAll('_', ' '))
                  )).toList(),
                  onChanged: (v) => onChanged(v!),
              ),
          ],
      );
  }

  Widget _buildGenderSelector() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text("Me interesan", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: GenderInterest.values.map((g) {
                  final selected = _genderInterest.contains(g);
                  return FilterChip(
                      label: Text(g.name.replaceAll('_', ' ')),
                      selected: selected,
                      onSelected: (s) {
                          setState(() {
                              if (g == GenderInterest.sin_preferencia) {
                                  if (s) _genderInterest = [GenderInterest.sin_preferencia];
                                  else _genderInterest = [];
                              } else {
                                  _genderInterest.remove(GenderInterest.sin_preferencia);
                                  if (s) _genderInterest.add(g);
                                  else _genderInterest.remove(g);
                              }
                          });
                      },
                  );
              }).toList())
          ],
      );
  }

  Widget _buildAgeSlider() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text("Rango de Edad: ${_ageRange.start.round()} - ${_ageRange.end.round()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                  values: _ageRange, min: 18, max: 99, divisions: 81,
                  labels: RangeLabels(_ageRange.start.round().toString(), _ageRange.end.round().toString()),
                  onChanged: (v) => setState(() => _ageRange = v),
              )
          ],
      );
  }

  Widget _buildDistanceSlider() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
               Text("Distancia Máxima: ${_distance.round()} km", style: const TextStyle(fontWeight: FontWeight.bold)),
               Slider(value: _distance, min: 5, max: 200, divisions: 39, onChanged: (v) => setState(() => _distance = v)),
          ],
      );
  }
}
