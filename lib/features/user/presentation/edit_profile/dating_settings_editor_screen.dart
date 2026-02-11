import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_preferences.dart';

class DatingSettingsEditorScreen extends ConsumerStatefulWidget {
  const DatingSettingsEditorScreen({super.key});

  @override
  ConsumerState<DatingSettingsEditorScreen> createState() => _DatingSettingsEditorScreenState();
}

class _DatingSettingsEditorScreenState extends ConsumerState<DatingSettingsEditorScreen> {
  // Dating Prefs state
  List<GenderInterest> _genderInterest = [];
  RangeValues _ageRange = const RangeValues(18, 99);
  double _distance = 50;
  RelationalStructure _structure = RelationalStructure.monogamia;
  DatingIntention _intention = DatingIntention.ver_que_sale;
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
       if (user.datingPreferences != null) {
           final p = user.datingPreferences!;
           if (_genderInterest.isEmpty) _genderInterest = List.from(p.genderInterest);
           _ageRange = RangeValues(p.ageRange.min.toDouble(), p.ageRange.max.toDouble());
           _distance = p.distanceMaxKm.toDouble();
           _structure = p.relationalStructure;
           _intention = p.intention;
           setState(() {});
       }
  }

  Future<void> _save() async {
      setState(() => _isLoading = true);
      try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) return;

          final prefs = DatingPreferences(
              genderInterest: _genderInterest,
              ageRange: AgeRange(min: _ageRange.start.round(), max: _ageRange.end.round()),
              distanceMaxKm: _distance.round(),
              relationalStructure: _structure,
              intention: _intention
          );

          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('datingPreferences').doc('main').set(prefs.toMap());
          // Update user settings to ensure datingActive is true if they are saving this? 
          // Or just leave it as is. User might want to configure without activating.
          
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
            title: const Text("Ajustes de Citas"),
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
                _buildStructureSelector(),
                const Divider(),
                _buildIntentionSelector(),
            ],
        )
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

  Widget _buildStructureSelector() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text("Estructura Relacional", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<RelationalStructure>(
                  value: _structure,
                  isExpanded: true,
                  items: RelationalStructure.values.map((e) => DropdownMenuItem(
                      value: e, child: Text(e.name.replaceAll('_', ' '))
                  )).toList(),
                  onChanged: (v) => setState(() => _structure = v!),
              ),
              if (_structure == RelationalStructure.monogamia)
                  const Text("Nota: Solo verás a otros usuarios Monógamos.", style: TextStyle(color: Colors.orange, fontSize: 12))
          ],
      );
  }

  Widget _buildIntentionSelector() {
     return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text("Intención", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<DatingIntention>(
                  value: _intention,
                  isExpanded: true,
                  items: DatingIntention.values.map((e) => DropdownMenuItem(
                      value: e, child: Text(e.name.replaceAll('_', ' '))
                  )).toList(),
                  onChanged: (v) => setState(() => _intention = v!),
              ),
          ],
      );
  }
}
