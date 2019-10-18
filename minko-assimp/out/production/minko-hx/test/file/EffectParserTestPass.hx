package test.file;
import minko.data.Binding.Source;
import minko.data.BindingMap.MacroType;
import minko.render.TriangleCulling;
import minko.render.StencilOperation;
import minko.render.CompareMode;
import minko.render.Blending.Destination;
import minko.render.States;
import minko.render.Blending.Source as BlendingSource;
import Array;
import Lambda;

import minko.file.AssetLibrary;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import minko.render.Effect;
import minko.render.Pass;
import minko.utils.MathUtil;
class EffectParserTestPass extends haxe.unit.TestCase {
    inline function loadEffect(filename:String, assets:AssetLibrary = null):Effect {
        return MinkoTests.loadEffect(filename, assets);
    }
    public function testOneAttributeBinding() {
        var fx:Effect = loadEffect("effect/attribute/binding/OneAttributeBinding.effect");
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        //   trace(defaults);
        assertEquals(defaults.length, 1);
        assertEquals(Lambda.count(defaults[0].attributeBindings.bindings), 1);
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").propertyName, "geometry[@{geometryUuid}].position");
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").source, Source.TARGET);

    }


    public function testTwoAttributeBindings() {
        var fx = loadEffect("effect/attribute/binding/TwoAttributeBindings.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertEquals(Lambda.count(defaults[0].attributeBindings.bindings), 2);
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").propertyName, "geometry[@{geometryUuid}].position");
        assertEquals(defaults[0].attributeBindings.bindings.get("aPosition").source, Source.TARGET);
        assertEquals(defaults[0].attributeBindings.bindings.get("aUv").propertyName, "geometry[@{geometryUuid}].uv");
        assertEquals(defaults[0].attributeBindings.bindings.get("aUv").source, Source.TARGET);
    }

//**************
//** Uniforms **
//**************

    public function testOneUniformBinding() {
        var fx = loadEffect("effect/uniform/binding/OneUniformBinding.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertEquals(Lambda.count(defaults[0].uniformBindings.bindings), 1);
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseMap").propertyName, "material[@{materialUuid}].diffuseMap");
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseMap").source, Source.TARGET);
    }


    public function testBoolDefaultValue() {
        var fx = MinkoTests.loadEffect("effect/uniform/default-value/BoolDefaultValue.effect");

        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 1);
        assertEquals(defaults[0].uniformBindings.defaultValues.get("testBool1Uniform"), 1);
        assertTrue(MathUtil.vec2_equals(defaults[0].uniformBindings.defaultValues.get("testBool2Uniform"), new Vec2(1, 0)));
        assertTrue(MathUtil.vec3_equals(defaults[0].uniformBindings.defaultValues.get("testBool3Uniform"), new Vec3(1, 0, 1)));
        assertTrue(MathUtil.vec4_equals(defaults[0].uniformBindings.defaultValues.get("testBool4Uniform"), new Vec4(1, 0, 1, 0)));
    }

    public function testFloat4DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/uniform/default-value/Float4DefaultValue.effect");

        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);

        assertTrue(MathUtil.vec4_equals(defaults[0].uniformBindings.defaultValues.get("testFloat4Uniform"), new Vec4(1.0, 1.0, 1.0, 1.0)));
    }

    public function testOneUniformBindingAndDefault() {
        var fx = MinkoTests.loadEffect("effect/uniform/binding/OneUniformBindingAndDefault.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertEquals(Lambda.count(defaults[0].uniformBindings.bindings), 1);
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseColor").propertyName, "diffuseColor");
        assertEquals(defaults[0].uniformBindings.bindings.get("uDiffuseColor").source, Source.TARGET);
        assertTrue(defaults[0].uniformBindings.defaultValues.hasProperty("uDiffuseColor"));
    }

//************
//** Macros **
//************


    public function testMacroIntDefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroIntDefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_INT_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_INT_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_INT_MACRO"), MacroType.INT);
        assertEquals(defaults[0].macroBindings.defaultValues.get("TEST_INT_MACRO"), 42);
    }


    public function testMacroInt2DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroInt2DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_INT2_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_INT2_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_INT2_MACRO"), MacroType.INT2);
        assertTrue(MathUtil.vec2_equals(defaults[0].macroBindings.defaultValues.get("TEST_INT2_MACRO"), new Vec2(42, 23)));
    }

    public function testMacroInt3DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroInt3DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_INT3_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_INT3_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_INT3_MACRO"), MacroType.INT3);
        assertTrue(MathUtil.vec3_equals(defaults[0].macroBindings.defaultValues.get("TEST_INT3_MACRO"), new Vec3(42, 23, 13)));
    }


    public function testMacroInt4DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroInt4DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_INT4_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_INT4_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_INT4_MACRO"), MacroType.INT4);
        assertTrue(MathUtil.vec4_equals(defaults[0].macroBindings.defaultValues.get("TEST_INT4_MACRO"), new Vec4(42, 23, 13, 7)));
    }


    public function testMacroFloatDefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroFloatDefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_FLOAT_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_FLOAT_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_FLOAT_MACRO"), MacroType.FLOAT);
        assertEquals(defaults[0].macroBindings.defaultValues.get("TEST_FLOAT_MACRO"), 42.24);
    }


    public function testMacroFloat2DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroFloat2DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_FLOAT2_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_FLOAT2_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_FLOAT2_MACRO"), MacroType.FLOAT2);
        assertTrue(MathUtil.vec2_equals(defaults[0].macroBindings.defaultValues.get("TEST_FLOAT2_MACRO"), new Vec2(42.24, 23.32)));
    }


    public function testMacroFloat3DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroFloat3DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_FLOAT3_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_FLOAT3_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_FLOAT3_MACRO"), MacroType.FLOAT3);
        assertTrue(MathUtil.vec3_equals(defaults[0].macroBindings.defaultValues.get("TEST_FLOAT3_MACRO"), new Vec3(42.24, 23.32, 13.31)));
    }


    public function testMacroFloat4DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroFloat4DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_FLOAT4_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_FLOAT4_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_FLOAT4_MACRO"), MacroType.FLOAT4);
        assertTrue(MathUtil.vec4_equals(defaults[0].macroBindings.defaultValues.get("TEST_FLOAT4_MACRO"), new Vec4(42.24, 23.32, 13.31, 7.7)));
    }


    public function testMacroBoolDefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroBoolDefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_BOOL_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_BOOL_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_BOOL_MACRO"), MacroType.BOOL);
        assertEquals(defaults[0].macroBindings.defaultValues.get("TEST_BOOL_MACRO"), 1);
    }


    public function testMacroBool2DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroBool2DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_BOOL2_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_BOOL2_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_BOOL2_MACRO"), MacroType.BOOL2);
        assertTrue(MathUtil.vec2_equals(defaults[0].macroBindings.defaultValues.get("TEST_BOOL2_MACRO"), new Vec2(1, 0)));
    }


    public function testMacroBool3DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroBool3DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_BOOL3_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_BOOL3_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_BOOL3_MACRO"), MacroType.BOOL3);
        assertTrue(MathUtil.vec3_equals(defaults[0].macroBindings.defaultValues.get("TEST_BOOL3_MACRO"), new Vec3(1, 0, 1)));
    }


    public function testMacroBool4DefaultValue() {
        var fx = MinkoTests.loadEffect("effect/macro/default-value/MacroBool4DefaultValue.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 1);
        assertTrue(defaults[0].macroBindings.defaultValues.hasProperty("TEST_BOOL4_MACRO"));
        assertTrue(defaults[0].macroBindings.types.exists("TEST_BOOL4_MACRO"));
        assertEquals(defaults[0].macroBindings.types.get("TEST_BOOL4_MACRO"), MacroType.BOOL4);
        assertTrue(MathUtil.vec4_equals(defaults[0].macroBindings.defaultValues.get("TEST_BOOL4_MACRO"), new Vec4(1, 0, 1, 0)));
    }
//************
//** Passes **
//************


    public function testMultiplePassesHaveDifferentStateData() {
        var fx = MinkoTests.loadEffect("effect/pass/MultiplePasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default"); assertEquals(defaults.length, 3);
        assertFalse(defaults[0].stateBindings.bindings == defaults[1].stateBindings.bindings);
        assertFalse(defaults[0].stateBindings.defaultValues == defaults[1].stateBindings.defaultValues);
        assertFalse(defaults[0].stateBindings.defaultValues.providers[0] == defaults[1].stateBindings.defaultValues.providers[0]);
        assertFalse(defaults[0].stateBindings.bindings == defaults[2].stateBindings.bindings);
        assertFalse(defaults[0].stateBindings.defaultValues == defaults[2].stateBindings.defaultValues);
        assertFalse(defaults[0].stateBindings.defaultValues.providers[0] == defaults[2].stateBindings.defaultValues.providers[0]);
        assertFalse(defaults[1].stateBindings.bindings == defaults[2].stateBindings.bindings);
        assertFalse(defaults[1].stateBindings.defaultValues == defaults[2].stateBindings.defaultValues);
        assertFalse(defaults[1].stateBindings.defaultValues.providers[0] == defaults[2].stateBindings.defaultValues.providers[0]);
        assertEquals(defaults[0].stateBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].stateBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].stateBindings.defaultValues.providers.length, 1);
    }

    public function testMultiplePassesHaveDifferentUniformData() {
        var fx = MinkoTests.loadEffect("effect/pass/MultiplePasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 3);
        assertFalse(defaults[0].uniformBindings.bindings == defaults[1].uniformBindings.bindings);
        assertFalse(defaults[0].uniformBindings.defaultValues == defaults[1].uniformBindings.defaultValues);
        assertFalse(defaults[0].uniformBindings.defaultValues.providers[0] == defaults[1].uniformBindings.defaultValues.providers[0]);
        assertFalse(defaults[0].uniformBindings.bindings == defaults[2].uniformBindings.bindings);
        assertFalse(defaults[0].uniformBindings.defaultValues == defaults[2].uniformBindings.defaultValues);
        assertFalse(defaults[0].uniformBindings.defaultValues.providers[0] == defaults[2].uniformBindings.defaultValues.providers[0]);
        assertFalse(defaults[1].uniformBindings.bindings == defaults[2].uniformBindings.bindings);
        assertFalse(defaults[1].uniformBindings.defaultValues == defaults[2].uniformBindings.defaultValues);
        assertFalse(defaults[1].uniformBindings.defaultValues.providers[0] == defaults[2].uniformBindings.defaultValues.providers[0]);

        assertEquals(defaults[0].uniformBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].uniformBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].uniformBindings.defaultValues.providers.length, 1);
    }


    public function testMultiplePassesHaveDifferentMacroData() {
        var fx = MinkoTests.loadEffect("effect/pass/MultiplePasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 3);
        assertFalse(defaults[0].macroBindings.bindings == defaults[1].macroBindings.bindings);
        assertFalse(defaults[0].macroBindings.defaultValues == defaults[1].macroBindings.defaultValues);
        assertFalse(defaults[0].macroBindings.defaultValues.providers[0] == defaults[1].macroBindings.defaultValues.providers[0]);
        assertFalse(defaults[0].macroBindings.bindings == defaults[2].macroBindings.bindings);
        assertFalse(defaults[0].macroBindings.defaultValues == defaults[2].macroBindings.defaultValues);
        assertFalse(defaults[0].macroBindings.defaultValues.providers[0] == defaults[2].macroBindings.defaultValues.providers[0]);
        assertFalse(defaults[1].macroBindings.bindings == defaults[2].macroBindings.bindings);
        assertFalse(defaults[1].macroBindings.defaultValues == defaults[2].macroBindings.defaultValues);
        assertFalse(defaults[1].macroBindings.defaultValues.providers[0] == defaults[2].macroBindings.defaultValues.providers[0]);
        assertEquals(defaults[0].macroBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].macroBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].macroBindings.defaultValues.providers.length, 1);
    }


    public function testMultiplePassesHaveDifferentAttributeData() {
        var fx = MinkoTests.loadEffect("effect/pass/MultiplePasses.effect");

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults.length, 3);
        assertFalse(defaults[0].attributeBindings.bindings == defaults[1].attributeBindings.bindings);
        assertFalse(defaults[0].attributeBindings.defaultValues == defaults[1].attributeBindings.defaultValues);
        assertFalse(defaults[0].attributeBindings.defaultValues.providers[0] == defaults[1].attributeBindings.defaultValues.providers[0]);
        assertFalse(defaults[0].attributeBindings.bindings == defaults[2].attributeBindings.bindings);
        assertFalse(defaults[0].attributeBindings.defaultValues == defaults[2].attributeBindings.defaultValues);
        assertFalse(defaults[0].attributeBindings.defaultValues.providers[0] == defaults[2].attributeBindings.defaultValues.providers[0]);
        assertFalse(defaults[1].attributeBindings.bindings == defaults[2].attributeBindings.bindings);
        assertFalse(defaults[1].attributeBindings.defaultValues == defaults[2].attributeBindings.defaultValues);
        assertFalse(defaults[1].attributeBindings.defaultValues.providers[0] == defaults[2].attributeBindings.defaultValues.providers[0]);
        assertEquals(defaults[0].attributeBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[1].attributeBindings.defaultValues.providers.length, 1);
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertEquals(defaults[2].attributeBindings.defaultValues.providers.length, 1);

    }

//************
//** States **
//************

//* State default values *
    public function testStatesDefaultValues()
    {
        var fx = loadEffect("effect/state/default-value/StatesDefaultValues.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var states:States = defaults[0].states;

        assertEquals(states.priority, States.DEFAULT_PRIORITY);
        assertEquals(states.zSorted, States.DEFAULT_ZSORTED);
        assertEquals(states.blendingSourceFactor, States.DEFAULT_BLENDING_SOURCE);
        assertEquals(states.blendingDestinationFactor, States.DEFAULT_BLENDING_DESTINATION);
        assertEquals(states.colorMask, States.DEFAULT_COLOR_MASK);
        assertEquals(states.depthMask, States.DEFAULT_DEPTH_MASK);
        assertEquals(states.depthFunction, States.DEFAULT_DEPTH_FUNCTION);
        assertEquals(states.triangleCulling, States.DEFAULT_TRIANGLE_CULLING);
        assertEquals(states.stencilFunction, States.DEFAULT_STENCIL_FUNCTION);
        assertEquals(states.stencilReference, States.DEFAULT_STENCIL_REFERENCE);
        assertEquals(states.stencilMask, States.DEFAULT_STENCIL_MASK);
        assertEquals(states.stencilFailOperation, States.DEFAULT_STENCIL_FAIL_OPERATION);
        assertEquals(states.stencilZFailOperation, States.DEFAULT_STENCIL_ZFAIL_OPERATION);
        assertEquals(states.stencilZPassOperation, States.DEFAULT_STENCIL_ZPASS_OPERATION);
        assertEquals(states.scissorTest, States.DEFAULT_SCISSOR_TEST);
        assertEquals(states.scissorBox, States.DEFAULT_SCISSOR_BOX);
        assertEquals(states.target, States.DEFAULT_TARGET);
    }

// Priority


    public function testStatesPriorityFloatValue()
    {
        var fx = loadEffect("effect/state/default-value/priority/StatesPriorityFloatValue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.priority, 42.0);
    }

    public function testStatesPriorityArrayValue()
    {
        var fx = loadEffect("effect/state/default-value/priority/StatesPriorityArrayValue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.priority, 2042.0);
    }

// ZSorted


    public function testStatesZSortedTrue()
    {
        var fx = loadEffect("effect/state/default-value/zsorted/StatesZSortedTrue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.zSorted, true);
    }


    public function testStatesZSortedFalse()
    {
        var fx = loadEffect("effect/state/default-value/zsorted/StatesZSortedFalse.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.zSorted, false);
    }

// Blending mode


    public function testStatesBlendingModeDefault()
    {
        var fx = loadEffect("effect/state/default-value/blending-mode/StatesBlendingModeDefault.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ONE);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ZERO);
    }

    public function testStatesBlendingModeAdditive()
    {
        var fx = loadEffect("effect/state/default-value/blending-mode/StatesBlendingModeAdditive.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.SRC_ALPHA);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE);
    }

    public function testStatesBlendingModeAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-mode/StatesBlendingModeAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.SRC_ALPHA);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE_MINUS_SRC_ALPHA);
    }


    public function testStatesBlendingModeArray()
    {
        var fx = loadEffect("effect/state/default-value/blending-mode/StatesBlendingModeArray.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.SRC_COLOR);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.SRC_ALPHA_SATURATE);
    }

// Blending Source


    public function testStatesBlendingSourceZero()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceZero.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ZERO);
    }


    public function testStatesBlendingSourceOne()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceOne.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ONE);
    }


    public function testStatesBlendingSourceSrcColor()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceSrcColor.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.SRC_COLOR);
    }


    public function testStatesBlendingSourceOneMinusSrcColor()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceOneMinusSrcColor.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ONE_MINUS_SRC_COLOR);
    }


    public function testStatesBlendingSourceSrcAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceSrcAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.SRC_ALPHA);
    }


    public function testStatesBlendingSourceOneMinusSrcAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceOneMinusSrcAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ONE_MINUS_SRC_ALPHA);
    }


    public function testStatesBlendingSourceDstAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceDstAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.DST_ALPHA);
    }


    public function testStatesBlendingSourceOneMinusDstAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-source/StatesBlendingSourceOneMinusDstAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingSourceFactor, BlendingSource.ONE_MINUS_DST_ALPHA);
    }

// Blending destination


    public function testStatesBlendingDestinationZero()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationZero.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ZERO);
    }


    public function testStatesBlendingDestinationOne()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationOne.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE);
    }


    public function testStatesBlendingDestinationDstColor()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationDstColor.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.DST_COLOR);
    }


    public function testStatesBlendingDestinationOneMinusDstColor()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationOneMinusDstColor.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE_MINUS_DST_COLOR);
    }


    public function testStatesBlendingDestinationSrcAlphaSaturate()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationSrcAlphaSaturate.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.SRC_ALPHA_SATURATE);
    }


    public function testStatesBlendingDestinationOneMinusSrcAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationOneMinusSrcAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE_MINUS_SRC_ALPHA);
    }


    public function testStatesBlendingDestinationDstAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationDstAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.DST_ALPHA);
    }


    public function testStatesBlendingDestinationOneMinusDstAlpha()
    {
        var fx = loadEffect("effect/state/default-value/blending-destination/StatesBlendingDestinationOneMinusDstAlpha.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.blendingDestinationFactor, Destination.ONE_MINUS_DST_ALPHA);
    }

// Color mask


    public function testStatesColorMaskTrue()
    {
        var fx = loadEffect("effect/state/default-value/color-mask/StatesColorMaskTrue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.colorMask, true);
    }


    public function testStatesColorMaskFalse()
    {
        var fx = loadEffect("effect/state/default-value/color-mask/StatesColorMaskFalse.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.colorMask, false);
    }

// Depth mask


    public function testStatesDepthMaskTrue()
    {
        var fx = loadEffect("effect/state/default-value/depth-mask/StatesDepthMaskTrue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthMask;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthMask, true);
    }


    public function testStatesDepthMaskFalse()
    {
        var fx = loadEffect("effect/state/default-value/depth-mask/StatesDepthMaskFalse.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthMask;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthMask, false);
    }

// Depth function


    public function testStatesDepthFunctionAlways()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionAlways.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.ALWAYS);
    }


    public function testStatesDepthFunctionEqual()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.EQUAL);
    }


    public function testStatesDepthFunctionGreater()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionGreater.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.GREATER);
    }


    public function testStatesDepthFunctionGreaterEqual()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionGreaterEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.GREATER_EQUAL);
    }


    public function testStatesDepthFunctionLess()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionLess.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.LESS);
    }


    public function testStatesDepthFunctionLessEqual()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionLessEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.LESS_EQUAL);
    }


    public function testStatesDepthFunctionNever()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionNever.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.NEVER);
    }


    public function testStatesDepthFunctionNotEqual()
    {
        var fx = loadEffect("effect/state/default-value/depth-function/StatesDepthFunctionNotEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        var value = defaults[0].states.depthFunction;

        assertFalse(fx == null);
        assertEquals(defaults[0].states.depthFunction, CompareMode.NOT_EQUAL);
    }

// Triangle Culling


    public function testStatesTriangleCullingBack()
    {
        var fx = loadEffect("effect/state/default-value/triangle-culling/StatesTriangleCullingBack.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.triangleCulling, TriangleCulling.BACK);
    }


    public function testStatesTriangleCullingBoth()
    {
        var fx = loadEffect("effect/state/default-value/triangle-culling/StatesTriangleCullingBoth.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.triangleCulling, TriangleCulling.BOTH);
    }


    public function testStatesTriangleCullingFront()
    {
        var fx = loadEffect("effect/state/default-value/triangle-culling/StatesTriangleCullingFront.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.triangleCulling, TriangleCulling.FRONT);
    }


    public function testStatesTriangleCullingNone()
    {
        var fx = loadEffect("effect/state/default-value/triangle-culling/StatesTriangleCullingNone.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.triangleCulling, TriangleCulling.NONE);
    }

// Stencil test


    public function testStatesStencilTestArrayWithOpsArray()
    {
        var fx = loadEffect("effect/state/default-value/stencil-test/StatesStencilTestArrayWithOpsArray.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.EQUAL);
        assertEquals(defaults[0].states.stencilReference, 1);
        assertEquals(defaults[0].states.stencilMask, 0);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.INCR_WRAP);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.DECR);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.DECR_WRAP);
    }


    public function testStatesStencilTestObjectWithOpsArray()
    {
        var fx = loadEffect("effect/state/default-value/stencil-test/StatesStencilTestObjectWithOpsArray.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.EQUAL);
        assertEquals(defaults[0].states.stencilReference, 1);
        assertEquals(defaults[0].states.stencilMask, 0);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.ZERO);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.REPLACE);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INCR);
    }


    public function testStatesStencilTestArrayWithOpsObject()
    {
        var fx = loadEffect("effect/state/default-value/stencil-test/StatesStencilTestArrayWithOpsObject.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.EQUAL);
        assertEquals(defaults[0].states.stencilReference, 1);
        assertEquals(defaults[0].states.stencilMask, 0);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.ZERO);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.REPLACE);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INCR);
    }


    public function testStatesStencilTestObjectWithOpsObject()
    {
        var fx = loadEffect("effect/state/default-value/stencil-test/StatesStencilTestObjectWithOpsObject.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.EQUAL);
        assertEquals(defaults[0].states.stencilReference, 1);
        assertEquals(defaults[0].states.stencilMask, 0);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.ZERO);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.REPLACE);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INCR);
    }

// Stencil function


    public function testStatesStencilFunctionAlways()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionAlways.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.ALWAYS);
    }


    public function testStatesStencilFunctionEqual()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.EQUAL);
    }


    public function testStatesStencilFunctionGreater()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionGreater.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.GREATER);
    }


    public function testStatesStencilFunctionGreaterEqual()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionGreaterEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.GREATER_EQUAL);
    }


    public function testStatesStencilFunctionLess()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionLess.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.LESS);
    }


    public function testStatesStencilFunctionLessEqual()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionLessEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.LESS_EQUAL);
    }


    public function testStatesStencilFunctionNever()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionNever.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.NEVER);
    }


    public function testStatesStencilFunctionNotEqual()
    {
        var fx = loadEffect("effect/state/default-value/stencil-function/StatesStencilFunctionNotEqual.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFunction, CompareMode.NOT_EQUAL);
    }

// Stencil Reference


    public function testStatesStencilReference0()
    {
        var fx = loadEffect("effect/state/default-value/stencil-reference/StatesStencilReference0.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilReference, 0);
    }


    public function testStatesStencilReference1()
    {
        var fx = loadEffect("effect/state/default-value/stencil-reference/StatesStencilReference1.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilReference, 1);
    }

// Stencil Mask


    public function testStatesStencilMask0()
    {
        var fx = loadEffect("effect/state/default-value/stencil-mask/StatesStencilMask0.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilMask, 0);
    }


    public function testStatesStencilMask1()
    {
        var fx = loadEffect("effect/state/default-value/stencil-mask/StatesStencilMask1.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilMask, 1);
    }

// Stencil fail operation


    public function testStatesStencilFailOperationKeep()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationKeep.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.KEEP);
    }


    public function testStatesStencilFailOperationZero()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationZero.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.ZERO);
    }


    public function testStatesStencilFailOperationReplace()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationReplace.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.REPLACE);
    }


    public function testStatesStencilFailOperationIncr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationIncr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.INCR);
    }


    public function testStatesStencilFailOperationIncrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationIncrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.INCR_WRAP);
    }


    public function testStatesStencilFailOperationDecr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationDecr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.DECR);
    }


    public function testStatesStencilFailOperationDecrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationDecrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.DECR_WRAP);
    }


    public function testStatesStencilFailOperationInvert()
    {
        var fx = loadEffect("effect/state/default-value/stencil-fail-operation/StatesStencilFailOperationInvert.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilFailOperation, StencilOperation.INVERT);
    }

// Stencil Z fail operation


    public function testStatesStencilZFailOperationKeep()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationKeep.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.KEEP);
    }


    public function testStatesStencilZFailOperationZero()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationZero.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.ZERO);
    }


    public function testStatesStencilZFailOperationReplace()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationReplace.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.REPLACE);
    }


    public function testStatesStencilZFailOperationIncr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationIncr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.INCR);
    }


    public function testStatesStencilZFailOperationIncrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationIncrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.INCR_WRAP);
    }


    public function testStatesStencilZFailOperationDecr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationDecr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.DECR);
    }


    public function testStatesStencilZFailOperationDecrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationDecrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.DECR_WRAP);
    }


    public function testStatesStencilZFailOperationInvert()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-fail-operation/StatesStencilZFailOperationInvert.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZFailOperation, StencilOperation.INVERT);
    }

// Stencil Z pass operation


    public function testStatesStencilZPassOperationKeep()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationKeep.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.KEEP);
    }


    public function testStatesStencilZPassOperationZero()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationZero.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.ZERO);
    }


    public function testStatesStencilZPassOperationReplace()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationReplace.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.REPLACE);
    }


    public function testStatesStencilZPassOperationIncr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationIncr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INCR);
    }


    public function testStatesStencilZPassOperationIncrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationIncrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INCR_WRAP);
    }


    public function testStatesStencilZPassOperationDecr()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationDecr.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.DECR);
    }


    public function testStatesStencilZPassOperationDecrWrap()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationDecrWrap.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.DECR_WRAP);
    }


    public function testStatesStencilZPassOperationInvert()
    {
        var fx = loadEffect("effect/state/default-value/stencil-z-pass-operation/StatesStencilZPassOperationInvert.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.stencilZPassOperation, StencilOperation.INVERT);
    }

// Scissor test


    public function testStatesScissorTestTrue()
    {
        var fx = loadEffect("effect/state/default-value/scissor-test/StatesScissorTestTrue.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.scissorTest, true);
    }


    public function testStatesScissorTestFalse()
    {
        var fx = loadEffect("effect/state/default-value/scissor-test/StatesScissorTestFalse.effect");
        var defaults:Array<Pass> = fx.techniques.get("default");
        assertFalse(fx == null);
        assertEquals(defaults[0].states.scissorTest, false);
    }

}
