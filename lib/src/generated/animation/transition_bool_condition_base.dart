// Core automatically generated
// lib/src/generated/animation/transition_bool_condition_base.dart.
// Do not modify manually.

import 'package:rive/src/generated/animation/transition_condition_base.dart';
import 'package:rive/src/generated/animation/transition_input_condition_base.dart';
import 'package:rive/src/rive_core/animation/transition_value_condition.dart';

const _coreTypes = <int>{
  TransitionBoolConditionBase.typeKey,
  TransitionValueConditionBase.typeKey,
  TransitionInputConditionBase.typeKey,
  TransitionConditionBase.typeKey
};

abstract class TransitionBoolConditionBase extends TransitionValueCondition {
  static const int typeKey = 71;
  @override
  int get coreType => TransitionBoolConditionBase.typeKey;
  @override
  Set<int> get coreTypes => _coreTypes;
}
