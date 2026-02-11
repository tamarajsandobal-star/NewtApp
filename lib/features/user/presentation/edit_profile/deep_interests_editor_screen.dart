import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';

class DeepInterestsEditorScreen extends ConsumerStatefulWidget {
  const DeepInterestsEditorScreen({super.key});

  @override
  ConsumerState<DeepInterestsEditorScreen> createState() => _DeepInterestsEditorScreenState();
}

class _DeepInterestsEditorScreenState extends ConsumerState<DeepInterestsEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _interests = [];
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
        if (_interests.isEmpty) {
            setState(() {
                _interests = List.from(user.deepInterests);
            });
        }
  }

  Future<void> _save() async {
      setState(() => _isLoading = true);
      try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) return;

          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'deepInterests': _interests,
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

  void _add() {
      final t = _controller.text.trim();
      if (t.isNotEmpty && !_interests.contains(t)) {
          setState(() {
              _interests.add(t);
              _controller.clear();
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
            title: const Text("Intereses Profundos"),
            actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                    const Text("Temas de conversación intensos, pasiones, o 'Special Interests'.\nEstos se combinan con lo que Newt aprende de ti.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(children: [
                        Expanded(child: CustomTextField(controller: _controller, label: "Agregar interés...")),
                        IconButton(icon: const Icon(Icons.add_circle), onPressed: _add),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(
                        spacing: 8,
                        children: _interests.map((e) => Chip(
                            label: Text(e),
                            onDeleted: () => setState(() => _interests.remove(e)),
                        )).toList(),
                    )
                ],
            ),
        )
    );
  }
}
