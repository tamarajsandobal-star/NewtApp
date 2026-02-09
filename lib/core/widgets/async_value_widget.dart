import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget Function(Object, StackTrace?)? error;

  const AsyncValueWidget({Key? key, required this.value, required this.data, this.error})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ?? (e, st) => Center(child: Text(e.toString())), 
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
