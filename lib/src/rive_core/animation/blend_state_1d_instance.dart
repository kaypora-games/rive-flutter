import 'package:plato/plato.dart';
import 'package:rive/src/rive_core/animation/animation_reset_factory.dart'
    as animation_reset_factory;
import 'package:rive/src/rive_core/animation/blend_animation_1d.dart';
import 'package:rive/src/rive_core/animation/blend_state_1d.dart';
import 'package:rive/src/rive_core/animation/blend_state_instance.dart';
import 'package:rive/src/rive_core/container_component.dart';
import 'package:rive/src/rive_core/layer_state_flags.dart';
import 'package:rive/src/rive_core/state_machine_controller.dart';

// ignore: unused_element
const _logr = Logr.always(prefix: 'blend-state-1d-instance');

/// [BlendState1D] mixing logic that runs inside the [StateMachine].
class BlendState1DInstance
    extends BlendStateInstance<BlendState1D, BlendAnimation1D> {
  late animation_reset_factory.AnimationReset? animationReset;
  BlendState1DInstance(BlendState1D state) : super(state) {

    animationInstances.sort(
        (a, b) => a.blendAnimation.value.compareTo(b.blendAnimation.value));

    animationReset =
        state.flags & LayerStateFlags.reset == LayerStateFlags.reset
            ? animation_reset_factory.fromAnimations(
                animationInstances
                    .map((animationInstance) => animationInstance.animationInstance.animation),
                    // .toList(growable: false),
                state.context,
                true)
            : null;

    // if (selected) _logr.chain('BUILD-STATE-1D >', this);

  }

  // static bool selected = false;

  /// Binary find the closest animation index.
  int animationIndex(double value) {

    var end = animationInstances.length - 1;
    if (end == -1) return 0; // animation instances is empty

    var idx = 0;
    var closestValue = 0.0;
    var start = 0;

    int mid;

    do {
      mid = (start + end) >> 1;
      closestValue = animationInstances[mid].blendAnimation.value;
      if (closestValue < value) {
        start = mid + 1;
      } else if (closestValue > value) {
        end = mid - 1;
      } else {
        idx = mid;
        break;
        // return mid;
        // idx = start = mid;
        // break;
      }

      idx = start;
    }
    while (start <= end);

    // if (selected) _logr.chain('ANIMATION-INDEX >', this, 'value=', value, idx);

    return idx;
  }

  // BlendStateAnimationInstance<BlendAnimation1D>? _from;
  // BlendStateAnimationInstance<BlendAnimation1D>? _to;

  @override
  String get ticker => printr(
      animationInstances.map((a) => a.animationInstance.animation.name).join(','),
    // _from?.animationInstance.animation.name??'',
    // _to?.animationInstance.animation.name??'',
  );

  @override
  bool advance(double seconds, StateMachineController controller) {

    if (!super.advance(seconds, controller)) { // skipping no animationInstance advanced

      // if (selected) _logr.chain('ADVANCE > FAILED', this, seconds);
      return false;
    }

    var inputValue = controller.getInputValue((state as BlendState1D).inputId);
    var value = (inputValue is double
            ? inputValue
            : (state as BlendState1D).input?.value) ??
        0;
    var index = animationIndex(value);
    var to = index >= 0 && index < animationInstances.length
        ? animationInstances[index]
        : null;
    var from = index - 1 >= 0 && index - 1 < animationInstances.length
        ? animationInstances[index - 1]
        : null;

    double mix, mixFrom;
    if (to == null ||
        from == null ||
        to.blendAnimation.value == from.blendAnimation.value) {
      mix = mixFrom = 1;
    } else {
      mix = (value - from.blendAnimation.value) /
          (to.blendAnimation.value - from.blendAnimation.value);
      mixFrom = 1.0 - mix;
    }

    var toValue = to?.blendAnimation.value;
    var fromValue = from?.blendAnimation.value;
    for (final animation in animationInstances) {
      if (animation.blendAnimation.value == toValue) {
        animation.mix = mix;
      } else if (animation.blendAnimation.value == fromValue) {
        animation.mix = mixFrom;
      } else {
        animation.mix = 0;
      }
    }

    // if (selected) _logr.chain('ADVANCE > MIX', this, seconds, mix, mixFrom);

    return true;
  }

  @override
  void apply(CoreContext core, double mix) {
    if (animationReset != null) {
      animationReset!.apply(core);
    }
    super.apply(core, mix);
  }
}
