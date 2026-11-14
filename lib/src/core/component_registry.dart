import 'package:flutter/widgets.dart';

abstract class CoreComponent {
  const CoreComponent();
}

final class ComponentRegistry {
  final _builders = <Type, Widget Function(CoreComponent)>{};

  void register<T extends CoreComponent>(Widget Function(T) builder) {
    if (_builders.containsKey(T)) {
      throw StateError('A Core builder is already registered for $T.');
    }
    _builders[T] = (component) => builder(component as T);
  }

  Widget build(CoreComponent component) {
    final type = component.runtimeType;
    final builder = _builders[type];
    if (builder == null) {
      throw StateError('No Core builder is registered for $type.');
    }
    return builder(component);
  }
}
