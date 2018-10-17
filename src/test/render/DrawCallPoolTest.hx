package test.render;
import minko.render.StencilOperation;
import minko.render.TriangleCulling;
import minko.render.CompareMode;
import minko.render.Blending.Destination;
import minko.render.MipFilter;
import minko.render.TextureFilter;
import minko.render.Texture;
import minko.render.SamplerStates;
import minko.render.WrapMode;
import Lambda;
import Lambda;
import minko.utils.MathUtil;
import glm.Vec4;
import minko.render.Pass;
import glm.Vec2;
import minko.render.Blending.Source as BlendingSource;
import Lambda;
import minko.component.Renderer.EffectVariables;
import minko.component.Surface;
import minko.data.Provider;
import minko.data.Store;
import minko.file.AssetLibrary;
import minko.geometry.QuadGeometry;
import minko.material.Material;
import minko.render.DrawCall;
import minko.render.DrawCallPool;
import minko.render.States;
import minko.render.TextureSampler;
import minko.Tuple;
class DrawCallPoolTest extends haxe.unit.TestCase {
    inline private function _testStateBindingToDefaultValueSwap(stateMaterialValue:Any, stateName:String, effectFile:String, valueFunc:DrawCall -> Any) {
        var fx = MinkoTests.loadEffect(effectFile);

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        assertEquals(fx.techniques.get("default").length, 1);

        var pass :Pass= fx.techniques.get("default")[0];

        var pool:DrawCallPool = new DrawCallPool();
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();

        var material = Material.create();
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);

        var variables:EffectVariables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", material.uuid));
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var drawCalls = pool.drawCalls.iterator().next();
        var drawCall:DrawCall = drawCalls.first.length == 0 ? drawCalls.second[0] : drawCalls.first[0];
        var stateDefaultValues = drawCall.pass.stateBindings.defaultValues;

        material.data.set(stateName, stateMaterialValue);
        pool.update();

        var drawCallValue = valueFunc(drawCall);
        var stateDefaultValue = stateDefaultValues.get(stateName);

        var hasProperty = drawCall.targetData.hasProperty(stateName);
        assertTrue(hasProperty);

        assertEquals(valueFunc(drawCall), material.data.get(stateName));

        material.data.unset(stateName);
        pool.update();

        drawCallValue = valueFunc(drawCall);
        stateDefaultValue = stateDefaultValues.get(stateName);

        assertEquals(valueFunc(drawCall), stateDefaultValues.get(stateName));
    }

    inline private function _testStateTargetBindingToDefaultValueSwap(effectFile:String, stateName:String, stateMaterialValue:TextureSampler, renderTargetName:String, renderTargetSize:Vec2) {
        var assets = AssetLibrary.create(MinkoTests.canvas.context);
        var fx = MinkoTests.loadEffect(effectFile, assets);
        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 1);
        assertEquals(fx.techniques.get("default").length, 1);

        var pass :Pass= fx.techniques.get("default")[0];

        var pool:DrawCallPool = new DrawCallPool();
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();

        var material = Material.create();
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);

        var variables:EffectVariables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", material.uuid));
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);
        var drawCall = pool.drawCalls.iterator().next().first[0];
        var stateDefaultValues = drawCall.pass.stateBindings.defaultValues;

        material.data.set(stateName, stateMaterialValue);
        pool.update();

        var hasProperty = drawCall.targetData.hasProperty(stateName);
        assertTrue(hasProperty);

        //
        assertEquals(drawCall.target, material.data.get(stateName));

        material.data.unset(stateName);
        pool.update();

        var states = drawCall.pass.states;

        assertEquals(drawCall.target, stateDefaultValues.get(stateName));
        assertFalse(states.target == States.DEFAULT_TARGET);
        assertEquals(states.target, assets.texture(renderTargetName));
        assertFalse(assets.texture(renderTargetName) == null);
        assertEquals(assets.texture(renderTargetName).width, Math.floor(renderTargetSize.x));
        assertEquals(assets.texture(renderTargetName).height, Math.floor(renderTargetSize.y));
    }


//Functions to factor tests
    inline private function createDrawCallWithState(effectFile:String, stateName:String, stateMaterialValue, material:Material, targetData:Store) {
        var fx = MinkoTests.loadEffect(effectFile);
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();

        var variables:EffectVariables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));
        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        return pool.drawCalls.iterator().next().first[0];
    }

/*
    public function testDrawCallPoolTest() {
        var drawCallPool:DrawCallPool = new DrawCallPool();
        assertTrue(true);
    }


    public function testUniformDefaultToBindingSwap() {
        var fx = MinkoTests.loadEffect("effect/uniform/binding/OneUniformBindingAndDefault.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        var variables = new EffectVariables();  variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));


        var uDiffuseColorDefaultValue = pass.uniformBindings.defaultValues.get("uDiffuseColor");

        assertTrue(  MathUtil.vec4_equals(uDiffuseColorDefaultValue, new Vec4(0.1, 0.2, 0.3, 0.4)));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0];
        assertEquals(begin_second.boundFloatUniforms.length, 1);
        assertTrue(MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data,  (pass.uniformBindings.defaultValues.get("uDiffuseColor"))));

        var p = Provider.create();

        p.set("diffuseColor", new Vec4(1.0,1.0,1.0,1.0));
        targetData.addProvider(p);
        pool.update();

        assertEquals(begin_second.boundFloatUniforms.length, 1);
        assertFalse(  MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data, (pass.uniformBindings.defaultValues.get("uDiffuseColor"))));
        assertTrue(  MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data, (targetData.get("diffuseColor"))));
    }

 
    public function testUniformBindingToDefaultSwap() {
        var fx = MinkoTests.loadEffect("effect/uniform/binding/OneUniformBindingAndDefault.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var geom = QuadGeometry.create(MinkoTests.canvas.context);
           var variables = new EffectVariables();
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        var uDiffuseColorDefaultValue = pass.uniformBindings.defaultValues.get("uDiffuseColor");
        assertTrue( MathUtil.vec4_equals(uDiffuseColorDefaultValue, new Vec4(0.1, 0.2, 0.3, 0.4)));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        var p = Provider.create();

        p.set("diffuseColor",new Vec4(1.0));
        targetData.addProvider(p);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);
        var begin_second=pool.drawCalls.iterator().next().first[0];
        assertEquals(begin_second.boundFloatUniforms.length, 1);
        assertFalse( MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data, (pass.uniformBindings.defaultValues.get("uDiffuseColor"))));
        assertTrue( MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data, (targetData.get("diffuseColor"))));

        p.unset("diffuseColor");
        pool.update();

        assertEquals(begin_second.boundFloatUniforms.length, 1);
        assertTrue(MathUtil.vec4_equals(begin_second.boundFloatUniforms[0].data, (pass.uniformBindings.defaultValues.get("uDiffuseColor"))));
    }



    public function testWatchAndDefineIntMacro() {
        var fx = MinkoTests.loadEffect("effect/macro/binding/OneIntMacroBinding.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var variables = new EffectVariables();

        assertEquals(Lambda.count(pass.macroBindings.bindings), 1);
        assertEquals(targetData.getPropertyChanged("bar").numCallbacks, 0);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        assertEquals(targetData.getPropertyChanged("bar").numCallbacks, 1);
        var begin_second=pool.drawCalls.iterator().next().first[0];

        assertFalse(begin_second.program.definedMacroNames.indexOf("FOO") !=  -1);

        var p = Provider.create();
        p.set("bar", 42);
        targetData.addProvider(p);
        pool.update();

        assertTrue(begin_second.program.definedMacroNames.indexOf("FOO") != -1);

        p.unset("bar");
        pool.update();

        assertFalse(begin_second.program.definedMacroNames.indexOf("FOO") != -1);
    }


    public function testWatchAndDefineVariableIntMacro() {
        var fx = MinkoTests.loadEffect("effect/macro/binding/OneVariableIntMacroBinding.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var p = Provider.create();
        var materialUuid = p.uuid;
        var variables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", materialUuid));

        var pass :Pass= fx.techniques.get("default")[0];

        assertEquals(Lambda.count(pass.macroBindings.bindings), 1);
        assertEquals(targetData.getPropertyChanged("bar").numCallbacks, 0);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        assertEquals(targetData.getPropertyChanged("material[" + materialUuid + "].bar").numCallbacks, 1);

        var begin_second=pool.drawCalls.iterator().next().first[0];


        assertFalse(begin_second.program.definedMacroNames.indexOf("FOO") !=  -1);

        p.set("bar", 42);
        targetData.addProviderbyName(p, "material");
        pool.update();

        assertTrue(begin_second.program.definedMacroNames.indexOf("FOO") !=  -1);

        p.unset("bar");
        pool.update();

        assertFalse(begin_second.program.definedMacroNames.indexOf("FOO") !=  -1);
    }


 
    public function testStopWatchingMacroAfterDrawCallsRemoved() {
        var fx = MinkoTests.loadEffect("effect/macro/binding/OneVariableIntMacroBinding.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var p = Provider.create();
        var materialUuid = p.uuid ;
        var variables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", materialUuid));

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        assertEquals(targetData.getPropertyChanged("material[" + materialUuid + "].bar").numCallbacks, 1);

        pool.removeDrawCalls(drawCalls);

        assertEquals(targetData.getPropertyChanged("material[" + materialUuid + "].bar").numCallbacks, 0);
    }


 
    public function testSameMacroBindingDifferentVariables() {
        var fx = MinkoTests.loadEffect("effect/macro/binding/OneVariableIntMacroBinding.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var p1 = Provider.create();
        var p2 = Provider.create();
        var materialUuid1 = p1.uuid;
        var materialUuid2 = p2.uuid;
        var variables1 = new EffectVariables();
        variables1.push(new Tuple<String, String>("materialUuid", materialUuid1));
        var variables2 = new EffectVariables();
        variables2.push(new Tuple<String, String>("materialUuid", materialUuid2));

        targetData.addProviderbyName(p1, Surface.MATERIAL_COLLECTION_NAME);
        targetData.addProviderbyName(p2, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables1, rootData, rendererData, targetData);
        var drawCalls2 = pool.addDrawCalls(fx, "default", variables2, rootData, rendererData, targetData);

        assertEquals(targetData.getPropertyChanged("material[" + materialUuid1 + "].bar").numCallbacks, 1);
        assertEquals(targetData.getPropertyChanged("material[" + materialUuid2 + "].bar").numCallbacks, 1);
    }

//Sampler states binding swap

 
    public function testSamplerStateSwapWrapModeBindingToDefaultClamp() {
        var samplerStateMaterialValue = WrapMode.REPEAT;
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingWrapModeWithDefaultValueClamp.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0];

        var samplers =begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, material.data.get(samplerStateBindingName));
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals( sampler.wrapMode, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }



    public function testSamplerStateSwapWrapModeBindingToDefaultRepeat() {
        var samplerStateMaterialValue = WrapMode.CLAMP;
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingWrapModeWithDefaultValueClamp.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables();
        variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);
        var begin_second=pool.drawCalls.iterator().next().first[0];
        var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, material.data.get(samplerStateBindingName));
        assertEquals(  sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(  sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals(  sampler.wrapMode, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStateSwapTextureFilterBindingToDefaultLinear() {
        var samplerStateMaterialValue = TextureFilter.NEAREST;
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingTextureFilterWithDefaultValueLinear.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);
        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, material.data.get(samplerStateBindingName));
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);

        material.data.unset(samplerStateBindingName);
        pool.update();

        var value = pass.uniformBindings.defaultValues.get(sampleStateUniformName);

        assertEquals( sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(  sampler.textureFilter, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }
    public function testSamplerStateSwapTextureFilterBindingToDefaultNearest() {
        var samplerStateMaterialValue = TextureFilter.LINEAR;
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingTextureFilterWithDefaultValueNearest.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        var p = Provider.create();
        material.data.set(samplerBindingName, texture );
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        var value = material.data.get (samplerStateBindingName);

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, material.data.get (samplerStateBindingName));
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals( sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals( sampler.textureFilter, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
        assertEquals( sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

 
    public function testSamplerStateSwapMipFilterBindingToDefaultNone() {
        var samplerStateMaterialValue = MipFilter.LINEAR;
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueNone.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture );
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, material.data.get (samplerStateBindingName));

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals( sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
    }

 
    public function testSamplerStateSwapMipFilterBindingToDefaultLinear() {
        var samplerStateMaterialValue = MipFilter.NONE;
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueLinear.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, material.data.get (samplerStateBindingName));

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals( sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
    }

 
    public function testSamplerStateSwapMipFilterBindingToDefaultNearest() {
        var samplerStateMaterialValue = MipFilter.NONE;
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingMipFilterWithDefaultValueNearest.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);
        material.data.set(samplerStateBindingName, samplerStateMaterialValue);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, material.data.get (samplerStateBindingName));

        material.data.unset(samplerStateBindingName);
        pool.update();

        assertEquals( sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals( sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals( sampler.mipFilter, pass.uniformBindings.defaultValues.get(sampleStateUniformName));
    }

// Sampler states binding with no binding value and no default value

 
    public function testSamplerStatesBindingWrapModeNoDefaultValue() {
        var samplerStateProperty = SamplerStates.PROPERTY_WRAP_MODE;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingWrapModeNoDefaultValue.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);
        assertFalse(pass.uniformBindings.defaultValues.hasProperty(sampleStateUniformName));

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

 
    public function testSamplerStateTextureFilterBindingNoDefaultValue() {
        var samplerStateProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingTextureFilterNoDefaultValue.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);
        assertFalse(pass.uniformBindings.defaultValues.hasProperty(sampleStateUniformName));

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

 
    public function testSamplerStatesBindingMipFilterNoDefaultValue() {
        var samplerStateProperty = SamplerStates.PROPERTY_MIP_FILTER;

        var fx = MinkoTests.loadEffect("effect/sampler-state/binding/SamplerStatesBindingMipFilterNoDefaultValue.effect");
        var pass :Pass= fx.techniques.get("default")[0];
        var pool:DrawCallPool = new DrawCallPool();
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStateProperty);

        var samplerStateBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, samplerStateProperty);

        var material = Material.create();
        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var variables = new EffectVariables(); variables.push(new Tuple<String, String>("materialUuid", material.uuid));

        material.data.set(samplerBindingName, texture);

        var geom = QuadGeometry.create(MinkoTests.canvas.context);
        variables.push(new Tuple<String, String>("geometryUuid", geom.uuid));

        targetData.addProviderbyName(geom.data, Surface.GEOMETRY_COLLECTION_NAME);
        targetData.addProviderbyName(material.data, Surface.MATERIAL_COLLECTION_NAME);

        var drawCalls = pool.addDrawCalls(fx, "default", variables, rootData, rendererData, targetData);

        var begin_second=pool.drawCalls.iterator().next().first[0]; var samplers = begin_second.samplers;
        var sampler = samplers[0];

        assertEquals(samplers.length, 1);
        assertFalse(pass.uniformBindings.defaultValues.hasProperty(sampleStateUniformName));

        assertEquals(sampler.wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(sampler.textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(sampler.mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

 
//States

//Priority

 
    public function testStatesBindingPriorityWithDefaultValueFirst() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueFirst.effect";

        _testStateBindingToDefaultValueSwap(stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueBackground() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueBackground.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueOpaque() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueOpaque.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueTransparent() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueTransparent.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueLast() {
        var stateMaterialValue = 42.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueLast.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueNumber() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueNumber.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

 
    public function testStatesBindingPriorityWithDefaultValueArray() {
        var stateMaterialValue = 0.0;
        var stateName = States.PROPERTY_PRIORITY;
        var effectFile = "effect/state/binding/with-default-value/priority/StatesBindingPriorityWithDefaultValueArray.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.priority;
        });
    }

// ZSorted

 
    public function testStatesBindingZSortedWithDefaultValueFalse() {
        var stateMaterialValue = true;
        var stateName = States.PROPERTY_ZSORTED;
        var effectFile = "effect/state/binding/with-default-value/zsorted/StatesBindingZSortedWithDefaultValueFalse.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.zSorted;
        });
    }

 
    public function testStatesBindingZSortedWithDefaultValueTrue() {
        var stateMaterialValue = false;
        var stateName = States.PROPERTY_ZSORTED;
        var effectFile = "effect/state/binding/with-default-value/zsorted/StatesBindingZSortedWithDefaultValueTrue.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.zSorted;
        });
    }

//BlendingSource

 
    public function testStatesBindingBlendingSourceWithDefaultValueZero() {
        var stateMaterialValue = BlendingSource.ONE;
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueZero.effect";

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueOne() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOne.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueSrcColor() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueSrcColor.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusSrcColor() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusSrcColor.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueSrcAlpha.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusSrcAlpha.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueDstAlpha.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

 
    public function testStatesBindingBlendingSourceWithDefaultValueOneMinusDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_SOURCE;
        var effectFile = "effect/state/binding/with-default-value/blending-source/StatesBindingBlendingSourceWithDefaultValueOneMinusDstAlpha.effect";
        var stateMaterialValue = BlendingSource.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingSource;
        });
    }

// Blending destination

 
    public function testStatesBindingBlendingDestinationWithDefaultValueZero() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueZero.effect";
        var stateMaterialValue = Destination.ONE;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueOne() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOne.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueDstColor() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueDstColor.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusDstColor() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusDstColor.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueSrcAlphaSaturate() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueSrcAlphaSaturate.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusSrcAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusSrcAlpha.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueDstAlpha.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

 
    public function testStatesBindingBlendingDestinationWithDefaultValueOneMinusDstAlpha() {
        var stateName = States.PROPERTY_BLENDING_DESTINATION;
        var effectFile = "effect/state/binding/with-default-value/blending-destination/StatesBindingBlendingDestinationWithDefaultValueOneMinusDstAlpha.effect";
        var stateMaterialValue = Destination.ZERO;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.blendingDestination;
        });
    }

// Color mask

 
    public function testStatesBindingColorMaskWithDefaultValueTrue() {
        var stateName = States.PROPERTY_COLOR_MASK;
        var effectFile = "effect/state/binding/with-default-value/color-mask/StatesBindingColorMaskWithDefaultValueTrue.effect";
        var stateMaterialValue = false;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.colorMask;
        });
    }

 
    public function testStatesBindingColorMaskWithDefaultValueFalse() {
        var stateName = States.PROPERTY_COLOR_MASK;
        var effectFile = "effect/state/binding/with-default-value/color-mask/StatesBindingColorMaskWithDefaultValueFalse.effect";
        var stateMaterialValue = true;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.colorMask;
        });
    }

// Depth Mask

 
    public function testStatesBindingDepthMaskWithDefaultValueTrue() {
        var stateName = States.PROPERTY_DEPTH_MASK;
        var effectFile = "effect/state/binding/with-default-value/depth-mask/StatesBindingDepthMaskWithDefaultValueTrue.effect";
        var stateMaterialValue = false;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthMask;
        });
    }

 
    public function testStatesBindingDepthMaskWithDefaultValueFalse() {
        var stateName = States.PROPERTY_DEPTH_MASK;
        var effectFile = "effect/state/binding/with-default-value/depth-mask/StatesBindingDepthMaskWithDefaultValueFalse.effect";
        var stateMaterialValue = true;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthMask;
        });
    }

// Depth Function

 
    public function testStatesBindingDepthFunctionWithDefaultValueAlways() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueAlways.effect";
        var stateMaterialValue = CompareMode.EQUAL;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueGreater() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueGreater.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueGreaterEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueGreaterEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueLess() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueLess.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueLessEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueLessEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueNever() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueNever.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

 
    public function testStatesBindingDepthFunctionWithDefaultValueNotEqual() {
        var stateName = States.PROPERTY_DEPTH_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/depth-function/StatesBindingDepthFunctionWithDefaultValueNotEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.depthFunction;
        });
    }

// Triangle culling

 
    public function testStatesBindingTriangleCullingWithDefaultValueNone() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueNone.effect";
        var stateMaterialValue = TriangleCulling.FRONT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.triangleCulling;
        });
    }

 
    public function testStatesBindingTriangleCullingWithDefaultValueFront() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueFront.effect";
        var stateMaterialValue = TriangleCulling.NONE;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.triangleCulling;
        });
    }

 
    public function testStatesBindingTriangleCullingWithDefaultValueBack() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueBack.effect";
        var stateMaterialValue = TriangleCulling.NONE;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.triangleCulling;
        });
    }

 
    public function testStatesBindingTriangleCullingWithDefaultValueBoth() {
        var stateName = States.PROPERTY_TRIANGLE_CULLING;
        var effectFile = "effect/state/binding/with-default-value/triangle-culling/StatesBindingTriangleCullingWithDefaultValueBoth.effect";
        var stateMaterialValue = TriangleCulling.NONE;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.triangleCulling;
        });
    }

// Stencil function

 
    public function testStatesBindingStencilFunctionWithDefaultValueAlways() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueAlways.effect";
        var stateMaterialValue = CompareMode.EQUAL;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueGreater() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueGreater.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueGreaterEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueGreaterEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueLess() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueLess.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueLessEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueLessEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueNever() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueNever.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

 
    public function testStatesBindingStencilFunctionWithDefaultValueNotEqual() {
        var stateName = States.PROPERTY_STENCIL_FUNCTION;
        var effectFile = "effect/state/binding/with-default-value/stencil-function/StatesBindingStencilFunctionWithDefaultValueNotEqual.effect";
        var stateMaterialValue = CompareMode.ALWAYS;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFunction;
        });
    }

// Stencil reference

 
    public function testStatesBindingStencilReferenceWithDefaultValue0() {
        var stateName = States.PROPERTY_STENCIL_REFERENCE;
        var effectFile = "effect/state/binding/with-default-value/stencil-reference/StatesBindingStencilReferenceWithDefaultValue0.effect";
        var stateMaterialValue = 1;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilReference;
        });
    }

 
    public function testStatesBindingStencilReferenceWithDefaultValue1() {
        var stateName = States.PROPERTY_STENCIL_REFERENCE;
        var effectFile = "effect/state/binding/with-default-value/stencil-reference/StatesBindingStencilReferenceWithDefaultValue1.effect";
        var stateMaterialValue = 0;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilReference;
        });
    }

// Stencil mask

 
    public function testStatesBindingStencilMaskWithDefaultValue0() {
        var stateName = States.PROPERTY_STENCIL_MASK;
        var effectFile = "effect/state/binding/with-default-value/stencil-mask/StatesBindingStencilMaskWithDefaultValue0.effect";
        var stateMaterialValue = 1;

        _testStateBindingToDefaultValueSwap(stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilMask;
        });
    }

 
    public function testStatesBindingStencilMaskWithDefaultValue1() {
        var stateName = States.PROPERTY_STENCIL_MASK;
        var effectFile = "effect/state/binding/with-default-value/stencil-mask/StatesBindingStencilMaskWithDefaultValue1.effect";
        var stateMaterialValue = 0;

        _testStateBindingToDefaultValueSwap(stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilMask;
        });
    }

//Stencil fail operation

 
    public function testStatesBindingStencilFailOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueKeep.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueZero.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueReplace.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueIncr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueIncrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueDecr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueDecrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

 
    public function testStatesBindingStencilFailOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_FAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-fail-operation/StatesBindingStencilFailOperationWithDefaultValueInvert.effect";
        var stateMaterialValue = StencilOperation.DECR;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilFailOperation;
        });
    }

// Stencil Z fail operation

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueKeep.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueZero.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueReplace.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueIncr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueIncrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueDecr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueDecrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

 
    public function testStatesBindingStencilZFailOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_ZFAIL_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-fail-operation/StatesBindingStencilZFailOperationWithDefaultValueInvert.effect";
        var stateMaterialValue = StencilOperation.DECR;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZFailOperation;
        });
    }

//Stencil Z pass operation

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueKeep() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueKeep.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueZero() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueZero.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueReplace() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueReplace.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueIncr() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueIncr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueIncrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueIncrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueDecr() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueDecr.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueDecrWrap() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueDecrWrap.effect";
        var stateMaterialValue = StencilOperation.INVERT;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

 
    public function testStatesBindingStencilZPassOperationWithDefaultValueInvert() {
        var stateName = States.PROPERTY_STENCIL_ZPASS_OPERATION;
        var effectFile = "effect/state/binding/with-default-value/stencil-z-pass-operation/StatesBindingStencilZPassOperationWithDefaultValueInvert.effect";
        var stateMaterialValue = StencilOperation.DECR;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.stencilZPassOperation;
        });
    }

//Scissor test

 
    public function testStatesBindingScissorTestWithDefaultValueTrue() {
        var stateName = States.PROPERTY_SCISSOR_TEST;
        var effectFile = "effect/state/binding/with-default-value/scissor-test/StatesBindingScissorTestWithDefaultValueTrue.effect";
        var stateMaterialValue = false;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.scissorTest;
        });
    }

 
    public function testStatesBindingScissorTestWithDefaultValueFalse() {
        var stateName = States.PROPERTY_SCISSOR_TEST;
        var effectFile = "effect/state/binding/with-default-value/scissor-test/StatesBindingScissorTestWithDefaultValueFalse.effect";
        var stateMaterialValue = true;

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.scissorTest;
        });
    }

//Scissor box

 
    public function testStatesBindingScissorBoxWithDefaultValueArray() {
        var stateName = States.PROPERTY_SCISSOR_BOX;
        var effectFile = "effect/state/binding/with-default-value/scissor-box/StatesBindingScissorBoxWithDefaultValueArray.effect";
        var stateMaterialValue =new Vec4(0);

       _testStateBindingToDefaultValueSwap (stateMaterialValue, stateName, effectFile, function(d:DrawCall)
        {
        return d.scissorBox;
        });
    }
    */

// Target

 
    public function testStatesBindingTargetWithDefaultValueSize() {
        var stateName = States.PROPERTY_TARGET;
        var effectFile = "effect/state/binding/with-default-value/target/StatesBindingTargetWithDefaultValueSize.effect";
        var resourceId = 0;
        var stateMaterialValue = new TextureSampler("TEST", resourceId);
        var renderTargetName = "test-render-target";
        var renderTargetSize = new Vec2(1024, 1024);

        _testStateTargetBindingToDefaultValueSwap(effectFile, stateName, stateMaterialValue, renderTargetName, renderTargetSize);
    }

 
    public function testStatesBindingTargetWithDefaultValueWidthHeight() {
        var stateName = States.PROPERTY_TARGET;
        var effectFile = "effect/state/binding/with-default-value/target/StatesBindingTargetWithDefaultValueWidthHeight.effect";
        var resourceId = 0;
        var stateMaterialValue = new TextureSampler("TEST", resourceId);
        var renderTargetName = "test-render-target";
        var renderTargetSize =  new Vec2(2048, 1024);

        _testStateTargetBindingToDefaultValueSwap(effectFile, stateName, stateMaterialValue, renderTargetName, renderTargetSize);
    }

}
