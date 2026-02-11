import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:neuro_social/features/user/presentation/user_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/user_photo.dart';
import '../../domain/models/app_user.dart';

class PhotosEditorScreen extends ConsumerStatefulWidget {
  const PhotosEditorScreen({super.key});

  @override
  ConsumerState<PhotosEditorScreen> createState() => _PhotosEditorScreenState();
}

class _PhotosEditorScreenState extends ConsumerState<PhotosEditorScreen> {
  List<UserPhoto> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProfileProvider).value;
    print("DEBUG: Photos _loadData called. User is: ${user?.uid}");
    if (user != null) {
      _populatePhotos(user);
    }
  }

  void _populatePhotos(AppUser user) {
      setState(() {
        _photos = List.from(user.photos);
        print("DEBUG: Loaded ${_photos.length} photos from user object.");
        // If empty but has legacy photoUrl, migrate it visually (not saved yet)
        if (_photos.isEmpty && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
           print("DEBUG: Migrating legacy photoUrl: ${user.photoUrl}");
           _photos.add(UserPhoto(url: user.photoUrl!, isPrimary: true, uploadedAt: DateTime.now()));
        }
        _sortPhotos();
      });
  }

  void _sortPhotos() {
    _photos.sort((a, b) {
      if (a.isPrimary) return -1;
      if (b.isPrimary) return 1;
      return a.orderIndex.compareTo(b.orderIndex);
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      // Update Order Indices
      for (int i = 0; i < _photos.length; i++) {
        _photos[i] = UserPhoto(
          url: _photos[i].url,
          isPrimary: i == 0, // First is always primary in this UI logic? Or user explicitly sets it?
          // Proposal: User drags to first slot to make primary.
          orderIndex: i,
          uploadedAt: _photos[i].uploadedAt
        );
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('users').doc(user.uid), {
         'photos': _photos.map((e) => e.toMap()).toList(),
         'photoUrl': _photos.isNotEmpty ? _photos.first.url : null, // Sync legacy
      });

      await batch.commit();
      ref.refresh(currentUserProfileProvider);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    print("DEBUG: _pickAndUploadPhoto called");
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Cámara"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galería"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    print("DEBUG: Selected source: $source");
    if (source == null) return;

    try {
        print("DEBUG: Calling picker.pickImage with source $source");
        final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
        print("DEBUG: Image picked: ${image?.path}");
        
        if (image == null) return;

        setState(() => _isLoading = true);
      
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user == null) {
            print("DEBUG: User is null");
            return;
        }

        final refStorage = FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        print("DEBUG: Ready to putFile/putData");
        
        // On Web, use putData. On Mobile, putFile.
        final bytes = await image.readAsBytes(); 
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        final uploadTask = refStorage.putData(bytes, metadata);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('DEBUG: Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
        }, onError: (e) {
            print("DEBUG: Upload task error: $e");
        });

        // Wait for completion with timeout
        await uploadTask.whenComplete(() => print("DEBUG: Upload completed")).timeout(const Duration(seconds: 15));
        
        final url = await refStorage.getDownloadURL();
        print("DEBUG: Upload success. URL: $url");

        setState(() {
           _photos.add(UserPhoto(
             url: url,
             isPrimary: _photos.isEmpty,
             orderIndex: _photos.length,
             uploadedAt: DateTime.now()
           ));
           _sortPhotos();
        });
      
    } catch (e) {
      print("DEBUG: Error in _pickAndUploadPhoto: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al subir: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(currentUserProfileProvider, (previous, next) {
         if (next.value != null && (previous?.value == null || _photos.isEmpty)) {
             _populatePhotos(next.value!);
         }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Fotos"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Arrastra para reordenar. La primera foto será tu foto principal.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _photos.length,
                onReorder: (oldIndex, newIndex) {
                   setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _photos.removeAt(oldIndex);
                      _photos.insert(newIndex, item);
                   });
                },
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return ListTile(
                    key: ValueKey(photo.url),
                    leading: Image.network(photo.url, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error)),
                    title: Text(index == 0 ? "Foto Principal" : "Foto ${index + 1}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePhoto(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadPhoto,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
