import 'package:flutter/foundation.dart';
import 'package:rive/src/rive_core/runtime/exceptions/rive_format_error_exception.dart';
import 'package:stokanal/collections.dart';

export 'dart:typed_data';

export 'package:flutter/foundation.dart';
export 'package:rive/src/animation_list.dart';
export 'package:rive/src/asset_list.dart';
export 'package:rive/src/blend_animations.dart';
export 'package:rive/src/container_children.dart';
export 'package:rive/src/core/field_types/core_callback_type.dart';
export 'package:rive/src/core/importers/artboard_importer.dart';
export 'package:rive/src/core/importers/backboard_importer.dart';
export 'package:rive/src/core/importers/file_asset_importer.dart';
export 'package:rive/src/core/importers/keyed_object_importer.dart';
export 'package:rive/src/core/importers/keyed_property_importer.dart';
export 'package:rive/src/core/importers/layer_state_importer.dart';
export 'package:rive/src/core/importers/linear_animation_importer.dart';
export 'package:rive/src/core/importers/nested_state_machine_importer.dart';
export 'package:rive/src/core/importers/state_machine_importer.dart';
export 'package:rive/src/core/importers/state_machine_layer_component_importer.dart';
export 'package:rive/src/core/importers/state_machine_layer_importer.dart';
export 'package:rive/src/core/importers/state_machine_listener_importer.dart';
export 'package:rive/src/core/importers/state_transition_importer.dart';
export 'package:rive/src/data_enum_values.dart';
export 'package:rive/src/event_list.dart';
export 'package:rive/src/generated/rive_core_context.dart';
export 'package:rive/src/layer_component_events.dart';
export 'package:rive/src/listener_actions.dart';
export 'package:rive/src/runtime_artboard.dart';
export 'package:rive/src/state_machine_components.dart';
export 'package:rive/src/state_transition_conditions.dart';
export 'package:rive/src/state_transitions.dart';
export 'package:rive/src/viewmodel_list_items.dart';
export 'package:rive/src/viewmodel_properties.dart';

typedef PropertyChangeCallback = void Function(dynamic from, dynamic to);
typedef BatchAddCallback = void Function();

abstract class Core<T extends CoreContext> {
  static const int missingId = -1;
  covariant late T context;
  int get coreType;
  int id = missingId;
  Set<int> get coreTypes => {};

  @nonVirtual
  bool hasValidated = false;
  // bool get hasValidated => _hasValidated;

  void onAddedDirty();
  void onAdded() {}
  void onRemoved() {}
  void remove() => context.removeObject(this);
  bool import(ImportStack stack) => true;

  bool validate() => true;

  /// Make a duplicate of this core object, N.B. that all properties excluding
  /// object id are copied.
  K? clone<K extends Core>() {
    var object = context.makeCoreInstance(coreType);
    object?.copy(this);
    return object is K ? object : null;
  }

  /// Copies property values, currently doesn't trigger change callbacks. It's
  /// meant to be a helper for [clone].
  @protected
  void copy(covariant Core source) {}
}

// ignore: avoid_classes_with_only_static_members
class InternalCoreHelper {
  static void markValid(Core object) {
    object.hasValidated = true;
  }
}

abstract class CoreContext {
  static const int invalidPropertyKey = 0;

  Core? makeCoreInstance(int typeKey);
  T? resolve<T>(int id);
  T resolveWithDefault<T>(int id, T defaultValue);
  void markDependencyOrderDirty();
  bool markDependenciesDirty(covariant Core rootObject);
  void removeObject<T extends Core>(T object);
  T? addObject<T extends Core>(T? object);
  void markNeedsAdvance();
  void dirty(void Function() dirt);
}

// ignore: one_member_abstracts
abstract class ImportStackObject {
  final _resolveBefore = UniqueList.of<ImportStackObject>();
  bool _resolved = false;

  bool initStack(ImportStack stack) {
    var type = resolvesBefore;
    if (type == -1) {
      return true;
    }
    var importer = stack.latest<ImportStackObject>(type);
    if (importer == null) {
      return false;
    }
    importer._resolveBefore.add(this);
    return true;
  }

  int get resolvesBefore => -1;

  bool _internalResolve() {
    if (_resolved) {
      return true;
    }
    _resolved = true;
    for (final before in _resolveBefore) {
      if (!before._internalResolve()) {
        return false;
      }
    }
    return resolve();
  }

  bool resolve() => true;
}

/// Stack to help the RiveFile locate latest ImportStackObject created of a
/// certain type.
class ImportStack {
  final _latests = <int, ImportStackObject>{};
  T? latest<T extends ImportStackObject>(int coreType) {
    var latest = _latests[coreType];
    if (latest is T) {
      return latest;
    }
    return null;
  }

  T requireLatest<T extends ImportStackObject>(int coreType) {
    var object = latest<T>(coreType);
    if (object == null) {
      throw RiveFormatErrorException(
          'Rive file is corrupt. Couldn\'t find expected object of type '
          '$coreType in import stack.');
    }
    return object;
  }

  bool makeLatest(int coreType, ImportStackObject? importObject) {
    var latest = _latests[coreType];
    if (latest != null) {
      if (!latest._internalResolve()) {
        return false;
      }
    }
    if (importObject != null && importObject.initStack(this)) {
      _latests[coreType] = importObject;
    } else {
      _latests.remove(coreType);
    }
    return true;
  }

  bool resolve() {
    for (final object in _latests.values) {
      if (!object._internalResolve()) {
        return false;
      }
    }
    return true;
  }
}
