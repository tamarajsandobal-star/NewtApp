import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_dealbreakers.dart';
import 'package:neuro_social/core/widgets/custom_text_field.dart';

class LimitsEditorScreen extends ConsumerStatefulWidget {
  const LimitsEditorScreen({super.key});

  @override
  ConsumerState<LimitsEditorScreen> createState() => _LimitsEditorScreenState();
}

class _LimitsEditorScreenState extends ConsumerState<LimitsEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Dating
  List<String> _datingSoft = [];
  List<String> _datingHard = [];
  
  // Friendship
  List<String> _friendshipSoft = [];
  List<String> _friendshipHard = [];

  bool _isLoading = false;

  // Controllers for adding
  final _datingSoftCtrl = TextEditingController();
  final _datingHardCtrl = TextEditingController();
  final _friendshipSoftCtrl = TextEditingController();
  final _friendshipHardCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
        _populateData(user);
    }
  }

  void _populateData(AppUser user) {
        if (_datingSoft.isEmpty) _datingSoft = List.from(user.dealbreakers.datingSoft);
        if (_datingHard.isEmpty) _datingHard = List.from(user.dealbreakers.datingHard);
        if (_friendshipSoft.isEmpty) _friendshipSoft = List.from(user.dealbreakers.friendshipSoft);
        if (_friendshipHard.isEmpty) _friendshipHard = List.from(user.dealbreakers.friendshipHard);
        setState(() {});
  }

  Future<void> _save() async {
      setState(() => _isLoading = true);
      try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) return;

          final db = UserDealbreakers(
              datingSoft: _datingSoft,
              datingHard: _datingHard,
              friendshipSoft: _friendshipSoft,
              friendshipHard: _friendshipHard,
          );

          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'dealbreakers': db.toMap(),
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(currentUserProfileProvider, (previous, next) {
         if (next.value != null && (previous?.value == null)) {
             _populateData(next.value!);
         }
    });

    return Scaffold(
        appBar: AppBar(
            title: const Text("Límites y Preferencias"),
            bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "Citas"), Tab(text: "Amistad")]),
            actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
                _buildListEditor("Citas - Prefiero Evitar (Soft)", _datingSoft, _datingSoftCtrl, "Citas - No Acepto (Hard)", _datingHard, _datingHardCtrl),
                _buildListEditor("Amistad - Prefiero Evitar (Soft)", _friendshipSoft, _friendshipSoftCtrl, "Amistad - No Acepto (Hard)", _friendshipHard, _friendshipHardCtrl),
            ],
        )
    );
  }

  Widget _buildListEditor(String label1, List<String> list1, TextEditingController ctrl1, String label2, List<String> list2, TextEditingController ctrl2) {
      return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
              child: Column(
                  children: [
                      _buildAddItem(label1, list1, ctrl1, Colors.orange),
                      const Divider(height: 32),
                      _buildAddItem(label2, list2, ctrl2, Colors.red),
                  ],
              ),
          ),
      );
  }

  Widget _buildAddItem(String label, List<String> list, TextEditingController ctrl, Color color) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Row(children: [
                  Expanded(child: CustomTextField(controller: ctrl, label: "Agregar...")),
                  IconButton(icon: const Icon(Icons.add), onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                          setState(() {
                              list.add(ctrl.text.trim());
                              ctrl.clear();
                          });
                      }
                  })
              ]),
              Wrap(spacing: 8, children: list.map((e) => Chip(
                  label: Text(e),
                  onDeleted: () => setState(() => list.remove(e)),
                  backgroundColor: color.withOpacity(0.1),
              )).toList())
          ],
      );
  }
}
