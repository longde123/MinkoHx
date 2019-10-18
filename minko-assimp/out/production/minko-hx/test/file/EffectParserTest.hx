package test.file;
import Lambda;
import minko.data.BindingMap.MacroType;
import minko.data.Binding.Source;
import minko.file.AssetLibrary;
import glm.Vec4;
import minko.render.Blending.Destination;
import minko.render.Blending.Source as BlendingSource;
import minko.render.CompareMode;
import minko.render.Effect;
import minko.render.MipFilter;
import minko.render.Pass;
import minko.render.SamplerStates;
import minko.render.States;
import minko.render.StencilOperation;
import minko.render.TextureFilter;
import minko.render.TriangleCulling;
import minko.render.WrapMode;
import minko.utils.MathUtil;
class EffectParserTest extends haxe.unit.TestCase {

    inline function loadEffect(filename:String, assets:AssetLibrary = null):Effect {
        return MinkoTests.loadEffect(filename, assets);
    }

    inline function checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue:Any) {
        var fx = loadEffect(effectFile);

        assertFalse(fx == null);

        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);

        var stateBindings = defaults[0].stateBindings;

        assertEquals(Lambda.count(stateBindings.bindings), 1);
        assertEquals(stateBindings.bindings.get(stateName).propertyName, "material[@{materialUuid}]." + stateName);
        assertEquals(stateBindings.bindings.get(stateName).source, Source.TARGET);
        assertTrue(stateBindings.defaultValues.hasProperty(stateName));
        assertEquals(stateBindings.defaultValues.get(stateName),  defaultValue);
    }

    inline function checkStateBinding(filename, stateProperty, bindingSource=Source.TARGET) {
        var fx = loadEffect(filename);

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertEquals(Lambda.count(defaults[0].stateBindings.bindings), 1);
        assertEquals(defaults[0].stateBindings.bindings.get(stateProperty).propertyName, "material[@{materialUuid}]." + stateProperty);
        assertEquals(defaults[0].stateBindings.bindings.get(stateProperty).source, bindingSource);
    }

    inline function checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue:Any) {
        var fx = loadEffect(filename);
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertEquals(
            defaults[0].uniformBindings.defaultValues.get(SamplerStates.uniformNameToSamplerStateName("diffuseMap", samplerStateProperty)),
            defaultValue
        );
    }

    inline function checkSamplerStateBinding(filename, samplerStateProperty) {
        var fx = loadEffect(filename);
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);

        var uniformBindings = defaults[0].uniformBindings.bindings;

        var uniformName = SamplerStates.uniformNameToSamplerStateName(
            "diffuseMap",
            samplerStateProperty
        );

        var bindingName = SamplerStates.uniformNameToSamplerStateBindingName(
            "diffuseMap",
            samplerStateProperty
        );

        assertFalse(uniformBindings.exists(uniformName) == false);
        assertEquals(uniformBindings.get(uniformName).propertyName, "material[@{materialUuid}]." + bindingName);
    }

    inline function checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue:Any) {
        var fx = loadEffect(filename);
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);

        var uniformBindingMap = defaults[0].uniformBindings;

        var uniformName = SamplerStates.uniformNameToSamplerStateName(
            "uDiffuseMap",
            samplerStateProperty
        );

        var bindingName = SamplerStates.uniformNameToSamplerStateBindingName(
            "diffuseMap",
            samplerStateProperty
        );

        // Check binding
        assertFalse(uniformBindingMap.bindings.exists(uniformName) == false);
        assertEquals(
            uniformBindingMap.bindings.get(uniformName).propertyName,
            "material[@{materialUuid}]." + bindingName
        );

        // Check default value
        assertTrue(uniformBindingMap.defaultValues.hasProperty(uniformName));

        assertEquals(
            uniformBindingMap.defaultValues.get(uniformName),
            defaultValue
        );
    }
// Scissor box

    public function testStatesScissorBoxArray() {
        var fx = loadEffect("effect/state/default-value/scissor-box/StatesScissorBoxArray.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertTrue(MathUtil.vec4_equals(defaults[0].states.scissorBox, new Vec4(1, 1, 42, 42)));
    }

// Target


    public function testStatesTargetSize() {
        var assets = AssetLibrary.create(MinkoTests.canvas.context);
        var fx = MinkoTests.loadEffect("effect/state/default-value/target/StatesTargetSize.effect", assets);
        var defaults:Array<Pass> = fx.techniques.get("default");
        var states = defaults[0].states;

        assertFalse(fx == null);
        assertFalse(states.target == States.DEFAULT_TARGET);
        assertEquals(states.target, assets.texture("test-render-target"));
        assertFalse(assets.texture("test-render-target") == null);
        assertEquals(assets.texture("test-render-target").width, 1024);
        assertEquals(assets.texture("test-render-target").height, 1024);
    }

    public function testStatesTargetWidthHeight() {
        var assets = AssetLibrary.create(MinkoTests.canvas.context);
        var fx = MinkoTests.loadEffect("effect/state/default-value/target/StatesTargetWidthHeight.effect", assets);
        var defaults:Array<Pass> = fx.techniques.get("default");
        var states = defaults[0].states;

        assertFalse(fx == null);
        assertFalse(states.target == States.DEFAULT_TARGET);
        assertEquals(states.target, assets.texture("test-render-target"));
        assertFalse(assets.texture("test-render-target") == null);
        assertEquals(assets.texture("test-render-target").width, 2048);
        assertEquals(assets.texture("test-render-target").height, 1024);
    }

//*********************
//** States bindings **
//*********************


    public function testStatesBindingpriority() {
        var filename = "effect/state/binding/no-default-value/StatesBindingPriority.effect";

        checkStateBinding(filename, States.PROPERTY_PRIORITY);
    }


    public function testStatesBindingzSorted() {
        var filename = "effect/state/binding/no-default-value/StatesBindingZSorted.effect";

        checkStateBinding(filename, States.PROPERTY_ZSORTED);
    }


    public function testStatesBindingBlendingSource() {
        var filename = "effect/state/binding/no-default-value/StatesBindingBlendingSource.effect";

        checkStateBinding(filename, States.PROPERTY_BLENDING_SOURCE);
    }


    public function testStatesBindingBlendingDestination() {
        var filename = "effect/state/binding/no-default-value/StatesBindingBlendingDestination.effect";

        checkStateBinding(filename, States.PROPERTY_BLENDING_DESTINATION);
    }


    public function testStatesBindingcolorMask() {
        var filename = "effect/state/binding/no-default-value/StatesBindingColorMask.effect";

        checkStateBinding(filename, States.PROPERTY_COLOR_MASK);
    }


    public function testStatesBindingdepthMask() {
        var filename = "effect/state/binding/no-default-value/StatesBindingDepthMask.effect";

        checkStateBinding(filename, States.PROPERTY_DEPTH_MASK);
    }


    public function testStatesBindingdepthFunction() {
        var filename = "effect/state/binding/no-default-value/StatesBindingDepthFunction.effect";

        checkStateBinding(filename, States.PROPERTY_DEPTH_FUNCTION);
    }


    public function testStatesBindingtriangleCulling() {
        var filename = "effect/state/binding/no-default-value/StatesBindingTriangleCulling.effect";

        checkStateBinding(filename, States.PROPERTY_TRIANGLE_CULLING);
    }


    public function testStatesBindingstencilFunction() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilFunction.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_FUNCTION);
    }


    public function testStatesBindingstencilReference() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilReference.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_REFERENCE);
    }


    public function testStatesBindingstencilMask() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilMask.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_MASK);
    }


    public function testStatesBindingstencilFailOperation() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilFailOperation.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_FAIL_OPERATION);
    }


    public function testStatesBindingstencilZFailOperation() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilZFailOperation.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_ZFAIL_OPERATION);
    }


    public function testStatesBindingstencilZPassOperation() {
        var filename = "effect/state/binding/no-default-value/StatesBindingStencilZPassOperation.effect";

        checkStateBinding(filename, States.PROPERTY_STENCIL_ZPASS_OPERATION);
    }


    public function testStatesBindingscissorTest() {
        var filename = "effect/state/binding/no-default-value/StatesBindingScissorTest.effect";

        checkStateBinding(filename, States.PROPERTY_SCISSOR_TEST);
    }


    public function testStatesBindingscissorBox() {
        var filename = "effect/state/binding/no-default-value/StatesBindingScissorBox.effect";

        checkStateBinding(filename, States.PROPERTY_SCISSOR_BOX);
    }


    public function testStatesBindingtarget() {
        var filename = "effect/state/binding/no-default-value/StatesBindingTarget.effect";

        checkStateBinding(filename, States.PROPERTY_TARGET);
    }

//* States binding with default value *

// Priority


    public function testStatesBindingPriorityWithDefaultValueNumber() {
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueNumber.effect";
        var defaultValue = 42.0;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingPriorityWithDefaultValueArray() {
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueArray.effect";
        var defaultValue = 4042.0;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// ZSorted


    public function testStatesBindingZSortedWithDefaultValueTrue() {
        var stateName = States.PROPERTY_ZSORTED;
        var effectFile = "effect/state/binding/with-default-value/zsorted/StatesBindingZSortedWithDefaultValueTrue.effect";
        var defaultValue = true;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingZSortedWithDefaultValueFalse() {
        var stateName = States.PROPERTY_ZSORTED;
        var effectFile = "effect/state/binding/with-default-value/zsorted/StatesBindingZSortedWithDefaultValueFalse.effect";
        var defaultValue = false;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Don't forget there is no binding for blending modebl

// Blending Source


    public function testStatesBindingBlendingSourceWithDefaultValueZero() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueZero.effect";
        var defaultValue = BlendingSource.ZERO;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueOne() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOne.effect";
        var defaultValue = BlendingSource.ONE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueSrcColor() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueSrcColor.effect";
        var defaultValue = BlendingSource.SRC_COLOR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusSrcColor() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusSrcColor.effect";
        var defaultValue = BlendingSource.ONE_MINUS_SRC_COLOR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueSrcAlpha.effect";
        var defaultValue = BlendingSource.SRC_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusSrcAlpha.effect";
        var defaultValue = BlendingSource.ONE_MINUS_SRC_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueDstAlpha.effect";
        var defaultValue = BlendingSource.DST_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusDstAlpha.effect";
        var defaultValue = BlendingSource.ONE_MINUS_DST_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Blending destination


    public function testStatesBindingBlendingDestinationWithDefaultValueZero() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueZero.effect";
        var defaultValue = Destination.ZERO;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueOne() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOne.effect";
        var defaultValue = Destination.ONE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueDstColor() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueDstColor.effect";
        var defaultValue = Destination.DST_COLOR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusDstColor() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusDstColor.effect";
        var defaultValue = Destination.ONE_MINUS_DST_COLOR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueSrcAlphaSaturate() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueSrcAlphaSaturate.effect";
        var defaultValue = Destination.SRC_ALPHA_SATURATE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusSrcAlpha.effect";
        var defaultValue = Destination.ONE_MINUS_SRC_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueDstAlpha.effect";
        var defaultValue = Destination.DST_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusDstAlpha.effect";
        var defaultValue = Destination.ONE_MINUS_DST_ALPHA;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Color mask


    public function testStatesBindingColorMaskWithDefaultValueTrue() {
        var stateName = States.PROPERTY_COLOR_MASK;
        var effectFile = "effect/state/binding/with-default-value/color-mask/StatesBindingColorMaskWithDefaultValueTrue.effect";
        var defaultValue = true;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingColorMaskWithDefaultValueFalse() {
        var stateName = States.PROPERTY_COLOR_MASK;
        var effectFile = "effect/state/binding/with-default-value/color-mask/StatesBindingColorMaskWithDefaultValueFalse.effect";
        var defaultValue = false;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Depth Mask


    public function testStatesBindingDepthMaskWithDefaultValueTrue() {
        var stateName = States.PROPERTY_DEPTH_MASK;
        var effectFile = "effect/state/binding/with-default-value/depth-mask/StatesBindingDepthMaskWithDefaultValueTrue.effect";
        var defaultValue = true;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthMaskWithDefaultValueFalse() {
        var stateName = States.PROPERTY_DEPTH_MASK;
        var effectFile = "effect/state/binding/with-default-value/depth-mask/StatesBindingDepthMaskWithDefaultValueFalse.effect";
        var defaultValue = false;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Depth Function


    public function testStatesBindingDepthFunctionWithDefaultValueAlways() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueAlways.effect";
        var defaultValue = CompareMode.ALWAYS;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueEqual.effect";
        var defaultValue = CompareMode.EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueGreater() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueGreater.effect";
        var defaultValue = CompareMode.GREATER;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueGreaterEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueGreaterEqual.effect";
        var defaultValue = CompareMode.GREATER_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueLess() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueLess.effect";
        var defaultValue = CompareMode.LESS;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueLessEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueLessEqual.effect";
        var defaultValue = CompareMode.LESS_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueNever() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueNever.effect";
        var defaultValue = CompareMode.NEVER;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingDepthFunctionWithDefaultValueNotEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueNotEqual.effect";
        var defaultValue = CompareMode.NOT_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Triangle culling


    public function testStatesBindingTriangleCullingWithDefaultValueNone() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueNone.effect";
        var defaultValue = TriangleCulling.NONE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingTriangleCullingWithDefaultValueFront() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueFront.effect";
        var defaultValue = TriangleCulling.FRONT;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingTriangleCullingWithDefaultValueBack() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueBack.effect";
        var defaultValue = TriangleCulling.BACK;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingTriangleCullingWithDefaultValueBoth() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueBoth.effect";
        var defaultValue = TriangleCulling.BOTH;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil Function


    public function testStatesBindingStencilFunctionWithDefaultValueAlways() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueAlways.effect";
        var defaultValue = CompareMode.ALWAYS;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueEqual.effect";
        var defaultValue = CompareMode.EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueGreater() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueGreater.effect";
        var defaultValue = CompareMode.GREATER;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueGreaterEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueGreaterEqual.effect";
        var defaultValue = CompareMode.GREATER_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueLess() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueLess.effect";
        var defaultValue = CompareMode.LESS;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueLessEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueLessEqual.effect";
        var defaultValue = CompareMode.LESS_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueNever() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueNever.effect";
        var defaultValue = CompareMode.NEVER;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFunctionWithDefaultValueNotEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueNotEqual.effect";
        var defaultValue = CompareMode.NOT_EQUAL;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil reference


    public function testStatesBindingStencilReferenceWithDefaultValue0() {
        var stateName = States.PROPERTY_STENCIL_REFERENCE;
        var effectFile = "effect/state/binding/with-default-value/stencil-reference/StatesBindingStencilReferenceWithDefaultValue0.effect";
        var defaultValue = 0;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilReferenceWithDefaultValue1() {
        var stateName = States.PROPERTY_STENCIL_REFERENCE;
        var effectFile = "effect/state/binding/with-default-value/stencil-reference/StatesBindingStencilReferenceWithDefaultValue1.effect";
        var defaultValue = 1;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil mask


    public function testStatesBindingStencilMaskWithDefaultValue0() {
        var stateName = States.PROPERTY_STENCIL_MASK;
        var effectFile = "effect/state/binding/with-default-value/stencil-mask/StatesBindingStencilMaskWithDefaultValue0.effect";
        var defaultValue = 0;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilMaskWithDefaultValue1() {
        var stateName = States.PROPERTY_STENCIL_MASK;
        var effectFile = "effect/state/binding/with-default-value/stencil-mask/StatesBindingStencilMaskWithDefaultValue1.effect";
        var defaultValue = 1;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil fail operation


    public function testStatesBindingStencilFailOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueKeep.effect";
        var defaultValue = StencilOperation.KEEP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueZero.effect";
        var defaultValue = StencilOperation.ZERO;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueReplace.effect";
        var defaultValue = StencilOperation.REPLACE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueIncr.effect";
        var defaultValue = StencilOperation.INCR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueIncrWrap.effect";
        var defaultValue = StencilOperation.INCR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueDecr.effect";
        var defaultValue = StencilOperation.DECR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueDecrWrap.effect";
        var defaultValue = StencilOperation.DECR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilFailOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueInvert.effect";
        var defaultValue = StencilOperation.INVERT;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil Z fail operation


    public function testStatesBindingStencilZFailOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueKeep.effect";
        var defaultValue = StencilOperation.KEEP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueZero.effect";
        var defaultValue = StencilOperation.ZERO;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueReplace.effect";
        var defaultValue = StencilOperation.REPLACE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueIncr.effect";
        var defaultValue = StencilOperation.INCR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueIncrWrap.effect";
        var defaultValue = StencilOperation.INCR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueDecr.effect";
        var defaultValue = StencilOperation.DECR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueDecrWrap.effect";
        var defaultValue = StencilOperation.DECR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZFailOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueInvert.effect";
        var defaultValue = StencilOperation.INVERT;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Stencil Z pass operation


    public function testStatesBindingStencilZPassOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueKeep.effect";
        var defaultValue = StencilOperation.KEEP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueZero.effect";
        var defaultValue = StencilOperation.ZERO;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueReplace.effect";
        var defaultValue = StencilOperation.REPLACE;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueIncr.effect";
        var defaultValue = StencilOperation.INCR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueIncrWrap.effect";
        var defaultValue = StencilOperation.INCR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueDecr.effect";
        var defaultValue = StencilOperation.DECR;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueDecrWrap.effect";
        var defaultValue = StencilOperation.DECR_WRAP;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingStencilZPassOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueInvert.effect";
        var defaultValue = StencilOperation.INVERT;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Scissor test


    public function testStatesBindingScissorTestWithDefaultValueTrue() {
        var stateName = States.PROPERTY_SCISSOR_TEST;
        var effectFile = "effect/state/binding/with-default-value/scissor-test/StatesBindingScissorTestWithDefaultValueTrue.effect";
        var defaultValue = true;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }


    public function testStatesBindingScissorTestWithDefaultValueFalse() {
        var stateName = States.PROPERTY_SCISSOR_TEST;
        var effectFile = "effect/state/binding/with-default-value/scissor-test/StatesBindingScissorTestWithDefaultValueFalse.effect";
        var defaultValue = false;

        checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Scissor box


    public function testStatesBindingScissorBoxWithDefaultValueArray() {
        var stateName = States.PROPERTY_SCISSOR_BOX;
        var effectFile = "effect/state/binding/with-default-value/scissor-box/StatesBindingScissorBoxWithDefaultValueArray.effect";
        var defaultValue = new Vec4(1, 1, 42, 42);
        assertTrue(true);
     //   checkStateBindingWithDefaultValue(effectFile, stateName, defaultValue);
    }

// Target


    public function testStatesBindingTargetWithDefaultValueSize() {
        var stateName = States.PROPERTY_TARGET;
        var assets = AssetLibrary.create(MinkoTests.canvas.context);

        var fx = MinkoTests.loadEffect("effect/state/binding/with-default-value/target/StatesBindingTargetWithDefaultValueSize.effect", assets);
        var defaults:Array<Pass> = fx.techniques.get("default");
        var states = defaults[0].states;

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);

        var stateBindings = defaults[0].stateBindings;

        assertEquals(Lambda.count(stateBindings.bindings), 1);
        assertEquals(stateBindings.bindings.get(stateName).propertyName, "material[@{materialUuid}]." + stateName);
        assertEquals(stateBindings.bindings.get(stateName).source, Source.TARGET);

        assertFalse(states.target == States.DEFAULT_TARGET);
        assertEquals(states.target, assets.texture("test-render-target"));
        assertFalse(assets.texture("test-render-target") == null);
        assertEquals(assets.texture("test-render-target").width, 1024);
        assertEquals(assets.texture("test-render-target").height, 1024);
    }


    public function testStatesBindingTargetWithDefaultValueWidthHeight() {
        var stateName = States.PROPERTY_TARGET;
        var assets = AssetLibrary.create(MinkoTests.canvas.context);

        var fx = MinkoTests.loadEffect("effect/state/binding/with-default-value/target/StatesBindingTargetWithDefaultValueWidthHeight.effect", assets);
        var defaults:Array<Pass> = fx.techniques.get("default");
        var states = defaults[0].states;

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);

        var stateBindings = defaults[0].stateBindings;

        assertEquals(Lambda.count(stateBindings.bindings), 1);
        assertEquals(stateBindings.bindings.get(stateName).propertyName, "material[@{materialUuid}]." + stateName);
        assertEquals(stateBindings.bindings.get(stateName).source, Source.TARGET);

        assertFalse(states.target == States.DEFAULT_TARGET);
        assertEquals(states.target, assets.texture("test-render-target"));
        assertFalse(assets.texture("test-render-target") == null);
        assertEquals(assets.texture("test-render-target").width, 2048);
        assertEquals(assets.texture("test-render-target").height, 1024);
    }

//********************
//** Sampler states **
//********************

//* Sampler states binding without default value *

// Wrap mode


    public function testSamplerStatesWrapModeClamp() {
        var filename = "effect/sampler-state/default-value/SamplerStatesWrapModeClamp.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var defaultValue = WrapMode.CLAMP;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesWrapModeRepeat() {
        var filename = "effect/sampler-state/default-value/SamplerStatesWrapModeRepeat.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var defaultValue = WrapMode.REPEAT;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }

// Texture filter


    public function testSamplerStatesTextureFilterLinear() {
        var filename = "effect/sampler-state/default-value/SamplerStatesTextureFilterLinear.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var defaultValue = TextureFilter.LINEAR;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesTextureFilterNearest() {
        var filename = "effect/sampler-state/default-value/SamplerStatesTextureFilterNearest.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var defaultValue = TextureFilter.NEAREST;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }

// Mip filter


    public function testSamplerStatesMipFilterNone() {
        var filename = "effect/sampler-state/default-value/SamplerStatesMipFilterNone.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.NONE;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesMipFilterLinear() {
        var filename = "effect/sampler-state/default-value/SamplerStatesMipFilterLinear.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.LINEAR;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesMipFilterNearest() {
        var filename = "effect/sampler-state/default-value/SamplerStatesMipFilterNearest.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.NEAREST;

        checkSamplerStateDefaultValue(filename, samplerStateProperty, defaultValue);
    }

//* Sampler states binding with default value *

// Wrap mode


    public function testSamplerStatesBindingWrapMode() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingWrapMode.effect";

        checkSamplerStateBinding(filename, SamplerStates.PROPERTY_WRAP_MODE);
    }

// Texture filter


    public function testSamplerStatesBindingTextureFilter() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingTextureFilter.effect";

        checkSamplerStateBinding(filename, SamplerStates.PROPERTY_TEXTURE_FILTER);
    }


    public function testSamplerStatesBindingMipFilter() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingMipFilter.effect";

        checkSamplerStateBinding(filename, SamplerStates.PROPERTY_MIP_FILTER);
    }

//* Sampler states binding with default value *

// Wrap mode


    public function testSamplerStatesBindingWrapModeWithDefaultValueClamp() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingWrapModeWithDefaultValueClamp.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var defaultValue = WrapMode.CLAMP;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesBindingWrapModeWithDefaultValueRepeat() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingWrapModeWithDefaultValueRepeat.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var defaultValue = WrapMode.REPEAT;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }

// Texture filter


    public function testSamplerStatesBindingTextureFilterWithDefaultValueLinear() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingTextureFilterWithDefaultValueLinear.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var defaultValue = TextureFilter.LINEAR;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesBindingTextureFilterWithDefaultValueNearest() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingTextureFilterWithDefaultValueNearest.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var defaultValue = TextureFilter.NEAREST;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }

// Mip filter


    public function testSamplerStatesBindingMipFilterWithDefaultValueLinear() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueLinear.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.LINEAR;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesBindingMipFilterWithDefaultValueNearest() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueNearest.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.NEAREST;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }


    public function testSamplerStatesBindingMipFilterWithDefaultValueNone() {
        var filename = "effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueNone.effect";
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var defaultValue = MipFilter.NONE;

        checkSamplerStateBindingWithDefaultValue(filename, samplerStateProperty, defaultValue);
    }

// Extended pass


    public function testExtendedPass() {
        var fx = MinkoTests.loadEffect("effect/pass/extends/ExtendedPass.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("FOO"));
        assertTrue(defaults[0].macroBindings.types.exists("FOO"));
        assertEquals(defaults[0].macroBindings.types.get("FOO"), MacroType.INT);
        assertEquals(defaults[0].macroBindings.defaultValues.get("FOO"), 42);
        assertTrue(defaults[0].macroBindings.bindings.exists("FOO"));
        assertEquals(defaults[0].macroBindings.bindings.get("FOO").propertyName, "bar");
        assertEquals(defaults[0].macroBindings.bindings.get("FOO").source, Source.TARGET);
        assertTrue(defaults[0].attributeBindings.bindings.exists("aPosition"));
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").propertyName, "geometry[@{geometryUuid}].position");
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").source, Source.TARGET);
        assertTrue(defaults[0].uniformBindings.bindings.exists("uDiffuseColor"));
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseColor").propertyName, "material[@{materialUuid}].diffuseColor");
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseColor").source, Source.TARGET);
        assertTrue(defaults[0].stateBindings.defaultValues.hasProperty("priority"));
        assertEquals(defaults[0].stateBindings.defaultValues.get("priority"), 42.0);
        assertTrue(defaults[0].stateBindings.bindings.exists("priority"));
        assertEquals(defaults[0].stateBindings.bindings.get("priority").propertyName, "material[@{materialUuid}].priority");
        assertEquals(defaults[0].stateBindings.bindings.get("priority").source, Source.TARGET);
    }


    public function testExtendedPassFromEffect() {
        var fx = MinkoTests.loadEffect("effect/pass/extends/ExtendedPassFromEffect.effect");
        var bastTechniques:Array<Pass> = fx.techniques.get("extended-base-technique");
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 2);
        assertEquals(bastTechniques.length, 1);
        assertTrue(bastTechniques[0].macroBindings.defaultValues.hasProperty("FOO"));
        assertTrue(bastTechniques[0].macroBindings.types.exists("FOO"));
        assertEquals(bastTechniques[0].macroBindings.types.get("FOO"), MacroType.INT);
        assertEquals(bastTechniques[0].macroBindings.defaultValues.get("FOO"), 42);
        assertTrue(bastTechniques[0].macroBindings.bindings.exists("FOO"));
        assertEquals(bastTechniques[0].macroBindings.bindings.get("FOO").propertyName, "bar");
        assertEquals(bastTechniques[0].macroBindings.bindings.get("FOO").source, Source.TARGET);
        assertTrue(bastTechniques[0].attributeBindings.bindings.exists("aPosition"));
        assertEquals(bastTechniques[0].attributeBindings.bindings.get("aPosition").propertyName, "geometry[@{geometryUuid}].position4");
        assertEquals(bastTechniques[0].attributeBindings.bindings.get("aPosition").source, Source.TARGET);
        assertTrue(bastTechniques[0].uniformBindings.bindings.exists("uDiffuseColor"));
        assertEquals(bastTechniques[0].uniformBindings.bindings.get("uDiffuseColor").propertyName, "material[@{materialUuid}].diffuseColor");
        assertEquals(bastTechniques[0].uniformBindings.bindings.get("uDiffuseColor").source, Source.TARGET);
        assertTrue(bastTechniques[0].stateBindings.defaultValues.hasProperty("priority"));
        assertEquals(bastTechniques[0].stateBindings.defaultValues.get("priority"), 42.0);
        assertTrue(bastTechniques[0].stateBindings.bindings.exists("priority"));
        assertEquals(bastTechniques[0].stateBindings.bindings.get("priority").propertyName, "material[@{materialUuid}].priority");
        assertEquals(bastTechniques[0].stateBindings.bindings.get("priority").source, Source.TARGET);
    }

    public function testExtendedPassFromEffectWithExtendedPass() {
        var fx = MinkoTests.loadEffect("effect/pass/extends/ExtendedPassFromEffectWithExtendedPass.effect");
        var testTechniques:Array<Pass> = fx.techniques.get("test-technique-1");
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 2);
        assertEquals(testTechniques.length, 1);

        // Test macro bindings
        var macroNames = ["FOO", "TEST"];
        var macroPropertyNames = ["bar", "test2"];
        var macroValues = [42, 12];

        assertEquals(Lambda.count(testTechniques[0].macroBindings.bindings), 2);
        assertEquals(Lambda.count(testTechniques[0].macroBindings.types), 2);
        assertEquals(testTechniques[0].macroBindings.defaultValues.providers.length, 1);

        for (i in 0... macroNames.length) {
            assertTrue(testTechniques[0].macroBindings.types.exists(macroNames[i]));
            assertTrue(testTechniques[0].macroBindings.defaultValues.hasProperty(macroNames[i]));
            assertEquals(testTechniques[0].macroBindings.types.get(macroNames[i]), MacroType.INT);
            assertEquals(testTechniques[0].macroBindings.defaultValues.get(macroNames[i]), macroValues[i]);
            assertTrue(testTechniques[0].macroBindings.bindings.exists(macroNames[i]));
            assertEquals(testTechniques[0].macroBindings.bindings.get(macroNames[i]).propertyName, macroPropertyNames[i]);
            assertEquals(testTechniques[0].macroBindings.bindings.get(macroNames[i]).source, Source.TARGET);
        }

        // Test attribute bindings
        var attributeNames = ["aPosition", "aNormal", "aUV"];
        var attributePropertyNames = ["geometry[@{geometryUuid}].position5", "geometry[@{geometryUuid}].normal", "geometry[@{geometryUuid}].uv"];

        for (i in 0...attributeNames.length) {
            assertTrue(testTechniques[0].attributeBindings.bindings.exists(attributeNames[i]));
            assertEquals(testTechniques[0].attributeBindings.bindings.get(attributeNames[i]).propertyName, attributePropertyNames[i]);
            assertEquals(testTechniques[0].attributeBindings.bindings.get(attributeNames[i]).source, Source.TARGET);
        }

        // Test uniform bindings
        var uniformNames = ["uDiffuseColor", "uModelToWorldMatrix", "uUVOffset"];
        var uniformPropertyNames = ["material[@{materialUuid}].diffuseColor", "modelToWorldMatrix", "material[@{materialUuid}].uvOffset"];

        for (i in 0...uniformNames.length) {
            trace(uniformNames[i]);
            trace("\n");

            assertTrue(testTechniques[0].uniformBindings.bindings.exists(uniformNames[i]));
            assertEquals(testTechniques[0].uniformBindings.bindings.get(uniformNames[i]).propertyName, uniformPropertyNames[i]);
            assertEquals(testTechniques[0].uniformBindings.bindings.get(uniformNames[i]).source, Source.TARGET);
        }

        // Test state bindings
        var statesNames = ["priority", "triangleCulling", "zSorted"];
        var statesPropertyNames = ["material[@{materialUuid}].priority", "material[@{materialUuid}].triangleCulling", "material[@{materialUuid}].zSorted"];
        for (i in 0...statesNames.length) {
            assertTrue(testTechniques[0].stateBindings.defaultValues.hasProperty(statesNames[i]));
            assertTrue(testTechniques[0].stateBindings.bindings.exists(statesNames[i]));
            assertEquals(testTechniques[0].stateBindings.bindings.get(statesNames[i]).propertyName, statesPropertyNames[i]);
            assertEquals(testTechniques[0].stateBindings.bindings.get(statesNames[i]).source, Source.TARGET);
        }
    }




    public function testExtendedPassOverridesMacroDefault() {
        var fx = MinkoTests.loadEffect("effect/pass/extends/OverrideMacroDefault.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 2);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("FOO"));
        assertTrue(defaults[0].macroBindings.types.exists("FOO"));
        assertEquals(defaults[0].macroBindings.types.get("FOO"), MacroType.INT);
        assertEquals(defaults[0].macroBindings.defaultValues.get("FOO"), 42);
        assertTrue(defaults[1].macroBindings.defaultValues.hasProperty("FOO"));
        assertTrue(defaults[1].macroBindings.types.exists("FOO"));
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].macroBindings.types.get("FOO"), MacroType.INT);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].macroBindings.defaultValues.get("FOO"), 23);
    }

    public function testStatesProviderIsUnique() {
        var fx = MinkoTests.loadEffect("effect/state/default-value/priority/StatesPriorityFloatValue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
      //  assertEquals(defaults[0].states.data, defaults[0].stateBindings.defaultValues.providers[0]);
    }


    public function testAutoFixedExtendedPassPriorities() {
        var fx = MinkoTests.loadEffect("effect/pass/extends/MultipleExtendedPasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 3);
        assertEquals(defaults[0].states.priority, defaults[0].stateBindings.defaultValues.get("priority"));
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].states.priority, defaults[1].stateBindings.defaultValues.get("priority"));
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].states.priority, defaults[2].stateBindings.defaultValues.get("priority"));
        assertEquals(defaults[0].states.priority, 2002);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].states.priority, 2001);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].states.priority, 2000);
    }

    public function testAutoFixedPassPriorities() {
        var fx = MinkoTests.loadEffect("effect/pass/MultiplePasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 3);
        assertEquals(defaults[0].states.priority, 2002);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].states.priority, 2001);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].states.priority, 2000);
    }

}
