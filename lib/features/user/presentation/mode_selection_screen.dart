import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/core/widgets/custom_button.dart';
import 'package:neuro_social/features/user/domain/models/user_preferences.dart';
import 'package:neuro_social/features/user/domain/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen> {
  bool _datingActive = false;
  bool _friendsActive = false;
  bool _isLoading = false;

  // Dating specifics
  RelationalStructure? _relationalStructure;
  DatingIntention? _intention;

  Future<void> _saveModes() async {
    if (!_datingActive && !_friendsActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please activate at least one mode.')),
      );
      return;
    }

    if (_datingActive) {
      if (_relationalStructure == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your preferred relational structure for Dating.')),
        );
        return;
      }
      if (_intention == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your dating intention.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1. Update User Settings
      batch.update(userRef, {
        'settings': {
          'datingActive': _datingActive,
          'friendsActive': _friendsActive,
        },
        'profileStatus': 'complete', // Assuming this step completes the mandatory flow
      });

      // 2. If Dating Active, save initial preferences
      if (_datingActive) {
        final datingRef = userRef.collection('preferences').doc('dating'); // Or subcollection 'datingPreferences' as per my plan? 
        // Plan said: users/{uid}/datingPreferences (subcollection? or doc in subcollection?)
        // Let's use specific doc path: users/{uid}/datingPreferences/main or just fields in a doc?
        // Prompt B: users/{uid}/datingPreferences
        // That implies a collection named `datingPreferences`? Or a document?
        // Usually `users/{uid}/datingPreferences` as a path means `datingPreferences` is a COLLECTION if it has docs inside, or if it IS a doc.
        // Let's assume datingPreferences is a collection and we store a 'default' doc, OR `datingPreferences` is a field?
        // "Campos: genderInterest..." under "users/{uid}/datingPreferences".
        // It's cleaner as a subcollection `preferences` with doc `dating`, or subcollection `datingPreferences` with doc `self`.
        // Let's stick to: `users/{uid}/datingPreferences/self` (so datingPreferences is collection).
        
        // Actually, UserPreferences model I made earlier: `class DatingPreferences ...`
        // I should stick to the plan.
        
        final prefs = DatingPreferences(
          genderInterest: [], // Default empty, will prompt later or set defaults
          ageRange: const AgeRange(min: 18, max: 99),
          distanceMaxKm: 50,
          relationalStructure: _relationalStructure!,
          intention: _intention!,
        );
        
        // I need a toMap for DatingPreferences. I didn't verify if I added it.
        // I'll manually create the map here to be safe and fast.
        batch.set(userRef.collection('datingPreferences').doc('main'), {
          'genderInterest': [],
          'ageRange': {'min': 18, 'max': 99},
          'distanceMaxKm': 50,
          'relationalStructure': _relationalStructure!.name,
          'intention': _intention!.name,
        });
      }

      if (_friendsActive) {
         // Initialize friendship prefs if needed
         batch.set(userRef.collection('friendshipPreferences').doc('main'), {
          'genderInterest': [],
          'ageRange': {'min': 18, 'max': 99},
          'distanceMaxKm': 50,
          'friendshipStyle': [],
          'meetMode': 'flexible', // Default
          'contactFrequency': 'media', // Default
        });
      }

      await batch.commit();

      if (mounted) {
         if (_datingActive) {
            context.go('/dating');
         } else if (_friendsActive) {
            context.go('/friendship');
         } else {
            context.go('/dating'); // Fallback
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatEnum(Enum e) {
     // Helper to format enum to proper Spanish Case
     // e.g. pareja_estable -> Pareja Estable
     final raw = e.name.replaceAll('_', ' ');
     return raw.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar Modos")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Cómo quieres usar Newt?", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text("Puedes activar uno o ambos modos. Podrás cambiarlo después en Ajustes."),
            const SizedBox(height: 24),

            // Dating Switch
            SwitchListTile(
              title: const Text("Modo Citas"),
              subtitle: const Text("Encontrar pareja o vínculos"),
              value: _datingActive,
              onChanged: (val) => setState(() => _datingActive = val),
            ),

            if (_datingActive) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Estructura Relacional (Obligatorio)", style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RelationalStructure>(
                      value: _relationalStructure,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: RelationalStructure.values.map((e) => DropdownMenuItem(
                        value: e, 
                        child: Text(_formatEnum(e)),
                      )).toList(),
                      onChanged: (v) => setState(() => _relationalStructure = v),
                    ),
                    const SizedBox(height: 16),
                    Text("Intención (Obligatorio)", style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DatingIntention>(
                      value: _intention,
                      decoration: InputDecoration(
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      isExpanded: true,
                      items: DatingIntention.values.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_formatEnum(e)),
                      )).toList(),
                      onChanged: (v) => setState(() => _intention = v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 48),
            ],

            // Friendship Switch
            SwitchListTile(
              title: const Text("Modo Amistad"),
              subtitle: const Text("Hacer nuevos amigos"),
              value: _friendsActive,
              onChanged: (val) => setState(() => _friendsActive = val),
            ),
            
            const SizedBox(height: 48),
            CustomButton(
              text: "Comenzar a Explorar",
              onPressed: _saveModes,
              isLoading: _isLoading,
            )
          ],
        ),
      ),
    );
  }
}
