package test.render;
import minko.utils.RandomNumbers;
import minko.render.MipFilter;
import minko.render.TextureFilter;
import minko.render.WrapMode;
import minko.render.SamplerStates;
import minko.render.Program;
import minko.render.Shader;
import minko.render.Texture;
import minko.component.Renderer.EffectVariables;
import minko.render.States;
import glm.Vec3;
import glm.Vec2;
import minko.Tuple;
import glm.Vec4;
import Array;
import haxe.ds.StringMap;
import minko.data.Binding;
import minko.data.Provider;
import minko.data.Store;
import minko.render.DrawCall;
import minko.render.ProgramInputs.InputType;
import minko.render.ProgramInputs.UniformInput;
import minko.utils.MathUtil;
import minko.utils.VectorHelper;


class DrawCallTest extends haxe.unit.TestCase {

    private var dummyVertexShader = "void main() { gl_Position = vec4(1.0); }";
    private var dummyFragmentShader = "void main() { gl_FragColor = vec4(1.0); }";

    inline private function _testMultipleUniformsFromRootData<T, U>(
        inputType:InputType,
        inputSize:Int,
        valueFunc:Void -> T,
        uniformsFunc:DrawCall -> Array<UniformValue<U>>) {
        var rootData = new Store();
        var rendererData = new Store();
        var targetData = new Store();
        var defaultValues = new Store();

        var p = Provider.create();
        var numProperties = Math.floor(1 + Math.abs(RandomNumbers.nextNumber() % 32));
        var bindings = new StringMap<Binding>();
        var inputs = new Array<UniformInput>();

        for (i in 0...numProperties) {
            var propertyName = randomString(10);

            if (!p.hasProperty(propertyName)) {
                p.set(propertyName, valueFunc());
                bindings.set("u" + propertyName, new Binding().setBinding(propertyName, Source.ROOT));
                inputs.push(new UniformInput("u" + propertyName, Math.floor(1 + Math.abs(RandomNumbers.nextNumber())), 1, inputType));
            }
        }
        rootData.addProvider(p);

        var drawCall = new DrawCall(0, null, [], rootData, rendererData, targetData);

        var uniformIsBound = true;
        for (input in inputs) {
            uniformIsBound = uniformIsBound && drawCall.bindUniform(input, bindings, defaultValues) != null;
        }
        assertTrue(uniformIsBound);

        var uniforms = uniformsFunc(drawCall);
        assertEquals(uniforms.length, inputs.length);
        for (i in 0... numProperties) {
            assertBoundUniform(uniforms, i, inputSize, bindings.get(inputs[i].name), inputs[i], rootData);
        }
    }



    inline private function assertBoundUniform<T>(boundUniforms:Array<UniformValue<T>>, index:Int, inputSize:Int, binding:Binding, input:UniformInput, store:Store) {

        var uniformValue:UniformValue<T> = boundUniforms[index];
        assertTrue(VectorHelper.equals(uniformValue.data, store.getUnsafePointer(binding.propertyName)));
        assertEquals(uniformValue.location, input.location);
        assertEquals(uniformValue.size, inputSize);
    }

    public function randomString(len) {
        var alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        var s = "";

        for (i in 0...len) {
            s += alphanum.charAt(RandomNumbers.nextNumberCeiling(10) % (alphanum.length - 1));
        }

        return s;
    }

    public function testConstructor() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();

        var drawCall:DrawCall = new DrawCall(0, null, new EffectVariables(), rootData, rendererData, targetData);
        assertTrue(true);
    }

    public function testOneFloatUniformBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 42.0);
        rootData.addProvider(p);

        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foo", Source.ROOT));


        var drawCall:DrawCall = new DrawCall(0, null, new EffectVariables(), rootData, rendererData, targetData);
        var input:UniformInput = new UniformInput("uFoo", 23, 1, InputType.float1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms.length, 0);
        assertEquals(drawCall.boundFloatUniforms.length, 1);
        assertEquals(drawCall.boundFloatUniforms[0].data, rootData.getUnsafePointer("foo"));
        assertEquals(drawCall.boundFloatUniforms[0].location, 23);
        assertEquals(drawCall.boundFloatUniforms[0].size, 1);
    }


    public function testMultipleFloatUniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.float1, 1, function() {
            return RandomNumbers.nextNumber();
        }, function(d:DrawCall) {
            return d.boundFloatUniforms;
        }
        );
    }

    public function testMultipleFloat2UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(
            InputType.float2,
            2,
            function() {
                return MathUtil.diskRand(100.0);
            },
            function(d:DrawCall) {
                return d.boundFloatUniforms;
            });
    }


    public function testMultipleFloat3UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.float3, 3, function() {
            return MathUtil.sphericalRand(-100.0);
        },
        function(d:DrawCall) {return d.boundFloatUniforms;
        });
    }


    public function testMultipleFloat4UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.float4, 4, function() {
            return new Vec4(MathUtil.linearRand(-100.0, 100.0), MathUtil.linearRand(-100.0, 100.0), MathUtil.linearRand(-100.0, 100.0), MathUtil.linearRand(-100.0, 100.0));
        }, function(d:DrawCall) {return d.boundFloatUniforms;
        }
        );
    }


    public function testOneFloatUniformWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 42.0);
        rootData.addProviderbyName(p, "foos");

        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foos[@{bar}].foo", Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("bar", "0")
        ],
        rootData, rendererData, targetData);
        var input = new UniformInput("uFoo", 23, 1, InputType.float1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms.length, 0);
        assertEquals(drawCall.boundFloatUniforms.length, 1);
        assertEquals(drawCall.boundFloatUniforms[0].data, p.getUnsafePointer("foo"));
        assertEquals(drawCall.boundFloatUniforms[0].location, 23);
        assertEquals(drawCall.boundFloatUniforms[0].size, 1);
    }


    public function testOneIntUniformBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 42);
        rootData.addProvider(p);
        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foo", Source.ROOT));

        var drawCall:DrawCall = new DrawCall(0, null, [], rootData, rendererData, targetData);
        var input = new  UniformInput("uFoo", 23, 1, InputType.int1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms.length, 1);
        assertEquals(drawCall.boundFloatUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms[0].data, rootData.getUnsafePointer("foo"));
        assertEquals(drawCall.boundIntUniforms[0].location, 23);
        assertEquals(drawCall.boundIntUniforms[0].size, 1);
    }


    public function testMultipleIntUniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.int1, 1, function() {
            return RandomNumbers.nextNumber();
        }, function(d:DrawCall) {return d.boundIntUniforms;
        });
    }


    public function testMultipleInt2UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.int2, 2, function() {
            return new Vec2(RandomNumbers.nextNumber(), RandomNumbers.nextNumber());
        }, function(d:DrawCall) {return d.boundIntUniforms;
        }
        );
    }


    public function testMultipleInt3UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.int3, 3, function() {
            return new Vec3(RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), RandomNumbers.nextNumber());
        }, function(d:DrawCall) {return d.boundIntUniforms;
        }
        );
    }


    public function testMultipleInt4UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.int4, 4, function() {
            return new Vec4(RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), RandomNumbers.nextNumber(), RandomNumbers.nextNumber());
        }, function(d:DrawCall) {return d.boundIntUniforms;
        });
    }


    public function testOneIntUniformWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 42);
        rootData.addProviderbyName(p, "foos");
        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foos[@{bar}].foo", Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("bar", "0")
        ],
        rootData, rendererData, targetData);
        var input = new UniformInput("uFoo", 23, 1, InputType.int1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms.length, 1);
        assertEquals(drawCall.boundFloatUniforms.length, 0);
        assertEquals(drawCall.boundIntUniforms[0].data, p.getUnsafePointer("foo"));
        assertEquals(drawCall.boundIntUniforms[0].location, 23);
        assertEquals(drawCall.boundIntUniforms[0].size, 1);
    }


    public function testOneBoolUniformBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 1);
        rootData.addProvider(p);

        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foo", Source.ROOT));

        var drawCall:DrawCall = new DrawCall(0, null, [], rootData, rendererData, targetData);
        var input = new UniformInput("uFoo", 23, 1, InputType.bool1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 1);
        assertEquals(drawCall.boundIntUniforms.length, 0);
        assertEquals(drawCall.boundFloatUniforms.length, 0);
        assertEquals(drawCall.boundBoolUniforms[0].data, rootData.getUnsafePointer("foo"));
        assertEquals(drawCall.boundBoolUniforms[0].location, 23);
        assertEquals(drawCall.boundBoolUniforms[0].size, 1);
    }


    public function testMultipleBoolUniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.bool1, 1, function() {
            return RandomNumbers.nextNumber() % 2;
        }, function(d:DrawCall) {return d.boundBoolUniforms;
        }
        );
    }


    public function testMultipleBool2UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.bool2, 2, function() {
            return new Vec2(RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2);
        }, function(d:DrawCall) {return d.boundBoolUniforms;
        }
        );
    }


    public function testMultipleBool3UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.bool3, 3, function() {
            return new Vec3(RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2);
        }, function(d:DrawCall) {return d.boundBoolUniforms;
        }
        );
    }


    public function testMultipleBool4UniformBindingsFromRootData() {
        _testMultipleUniformsFromRootData(InputType.bool4, 4, function() {
            return new Vec4(RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2, RandomNumbers.nextNumber() % 2);
        }, function(d:DrawCall) {return d.boundBoolUniforms;
        }
        );
    }


    public function testOneBoolUniformWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        p.set("foo", 1);
        rootData.addProviderbyName(p, "foos");
        var bindings = new StringMap<Binding>();
        bindings.set("uFoo", new Binding().setBinding("foos[@{bar}].foo", Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("bar", "0")
        ],
        rootData, rendererData, targetData);
        var input = new UniformInput("uFoo", 23, 1, InputType.bool1);

        var uniformIsBound = drawCall.bindUniform(input, bindings, defaultValues) != null;

        assertTrue(uniformIsBound);
        assertEquals(drawCall.boundBoolUniforms.length, 1);
        assertEquals(drawCall.boundIntUniforms.length, 0);
        assertEquals(drawCall.boundFloatUniforms.length, 0);
        assertEquals(drawCall.boundBoolUniforms[0].data, p.getUnsafePointer("foo"));
        assertEquals(drawCall.boundBoolUniforms[0].location, 23);
        assertEquals(drawCall.boundBoolUniforms[0].size, 1);
    }


    public function testRenderTargetDefaultValue() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var states = new States();

        defaultValues.addProvider(states.data);

        var drawCall:DrawCall = new DrawCall(0, null,new EffectVariables(), rootData, rendererData, targetData);

        drawCall.bindStates(new StringMap<Binding>(), defaultValues);

        assertEquals(drawCall.target, States.DEFAULT_TARGET);
    }

    public function testRenderTargetFromDefaultValues() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var states = new States();

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);

        texture.upload();
        states.target=(texture);
        defaultValues.addProvider(states.data);

        var drawCall:DrawCall = new DrawCall(0, null, [], rootData, rendererData, targetData);

        drawCall.bindStates(new StringMap<Binding>(), defaultValues);

        assertFalse(drawCall.target == States.DEFAULT_TARGET);
        assertEquals(drawCall.target, texture);
     //   assertEquals(drawCall.target.id, 1);
    }


    public function testRenderTargetBindingFromTargetData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        var p = Provider.create();

        texture.upload();
        p.set(States.PROPERTY_TARGET, texture);
        targetData.addProvider(p);

        var bindings = new StringMap<Binding>();
        bindings.set(States.PROPERTY_TARGET, new Binding().setBinding(States.PROPERTY_TARGET, Source.TARGET));
        var drawCall:DrawCall = new DrawCall(0, null, [], rootData, rendererData, targetData);

        drawCall.bindStates(bindings, defaultValues);

        assertFalse(drawCall.target == States.DEFAULT_TARGET);
        assertEquals(drawCall.target, texture);
     //   assertEquals(drawCall.target.id, 2);
    }

//Sampler states bindings

// Sampler states without bindings and without default values (implicit default values)


    public function testSamplerStatesImplicitDefaultValues() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;


        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));


        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);


        var location = 23;
        var size = 0;

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader:Shader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader:Shader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program:Program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

// Sampler states with explicit default value


    public function testSamplerStatesWrapModeWithDefaultValueRepeat() {
        var samplerStatesProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var sampleStateUniformDefaultValue = WrapMode.REPEAT;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));

        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);


        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, defaultValues.get(sampleStateUniformName));
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStatesWrapModeWithDefaultValueClamp() {
        var samplerStatesProperty = SamplerStates.PROPERTY_WRAP_MODE;
        var sampleStateUniformDefaultValue = WrapMode.CLAMP;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);


        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, defaultValues.get(sampleStateUniformName));
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStatesTextureFilterWithDefaultValueLinear() {
        var samplerStatesProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var sampleStateUniformDefaultValue = TextureFilter.LINEAR;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, defaultValues.get(sampleStateUniformName));
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStatesTextureFilterWithDefaultValueNearest() {
        var samplerStatesProperty = SamplerStates.PROPERTY_TEXTURE_FILTER;
        var sampleStateUniformDefaultValue = TextureFilter.NEAREST;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture );
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, defaultValues.get(sampleStateUniformName));
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }

    public function testSamplerStatesMipFilterWithDefaultValueLinear() {
        var samplerStatesProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var sampleStateUniformDefaultValue = MipFilter.LINEAR;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, defaultValues.get(sampleStateUniformName));
    }


    public function testSamplerStatesMipFilterWithDefaultValueLinearNearest() {
        var samplerStatesProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var sampleStateUniformDefaultValue = MipFilter.NEAREST;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);
        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);
        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, defaultValues.get(sampleStateUniformName));
    }


    public function testSamplerStatesMipFilterWithDefaultValueNone() {
        var samplerStatesProperty = SamplerStates.PROPERTY_MIP_FILTER;
        var sampleStateUniformDefaultValue = MipFilter.NONE;

        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();
        var defaultValueProvider = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var sampleStateUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, samplerStatesProperty);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;

        defaultValues.addProvider(defaultValueProvider);
        defaultValueProvider.set(sampleStateUniformName, sampleStateUniformDefaultValue);

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);
        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, defaultValues.get(sampleStateUniformName));
    }

// Sampler states with variable binding


    public function testSamplerStatesWrapModeWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();

        var p = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var wrapModeUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, SamplerStates.PROPERTY_WRAP_MODE);
        var wrapModeBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, SamplerStates.PROPERTY_WRAP_MODE);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        p.set(wrapModeBindingName, WrapMode.REPEAT);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;
        var wrapModeUniformValue = "material[@{id}]." + wrapModeBindingName;


        var location = 23;
        var size = 0;

        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        bindings.set(wrapModeUniformName, new Binding().setBinding(wrapModeUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertFalse(resolvedBindings[0] == null);
        assertEquals(resolvedBindings[1], null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, p.get(wrapModeBindingName));
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStatesTextureFilterWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var textureFilterUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, SamplerStates.PROPERTY_TEXTURE_FILTER);
        var textureFilterBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, SamplerStates.PROPERTY_TEXTURE_FILTER);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        p.set(textureFilterBindingName, TextureFilter.LINEAR);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;
        var textureFilterUniformValue = "material[@{id}]." + textureFilterBindingName;


        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        bindings.set(textureFilterUniformName, new Binding().setBinding(textureFilterUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);


        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertFalse(resolvedBindings[1] == null);
        assertEquals(resolvedBindings[2], null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, p.get(textureFilterBindingName));
        assertEquals(samplers[0].mipFilter, SamplerStates.DEFAULT_MIP_FILTER);
    }


    public function testSamplerStatesMipFilterWithVariableBindingFromRootData() {
        var rootData:Store = new Store();
        var rendererData:Store = new Store();
        var targetData:Store = new Store();
        var defaultValues:Store = new Store();
        var location = 23;
        var size = 0;

        var p = Provider.create();

        var samplerUniformName = "uDiffuseMap";
        var samplerBindingName = "diffuseMap";

        var mipFilterUniformName = SamplerStates.uniformNameToSamplerStateName(samplerUniformName, SamplerStates.PROPERTY_MIP_FILTER);
        var mipFilterBindingName = SamplerStates.uniformNameToSamplerStateBindingName(samplerBindingName, SamplerStates.PROPERTY_MIP_FILTER);

        var texture = Texture.create(MinkoTests.canvas.context, 1024, 1024, false, true);
        p.set(samplerBindingName, texture);
        p.set(mipFilterBindingName, MipFilter.LINEAR);
        rootData.addProviderbyName(p, "material");

        var samplerUniformValue = "material[@{id}]." + samplerBindingName;
        var mipFilterUniformValue = "material[@{id}]." + mipFilterBindingName;


        var bindings = new StringMap<Binding>();
        bindings.set(samplerUniformName, new Binding().setBinding(samplerUniformValue, Source.ROOT));
        bindings.set(mipFilterUniformName, new Binding().setBinding(mipFilterUniformValue, Source.ROOT));
        var drawCall:DrawCall = new DrawCall(0, null,
        [
            new Tuple<String, String>("id", "0")
        ], rootData, rendererData, targetData);

        var input = new UniformInput(samplerUniformName, location, size, InputType.sampler2d);

        var vertexShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.VERTEX_SHADER, dummyVertexShader);
        var fragmentShader = Shader.createbySource(MinkoTests.canvas.context, ShaderType.FRAGMENT_SHADER, dummyFragmentShader);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("program", MinkoTests.canvas.context, vertexShader, fragmentShader);
        program.upload();

        drawCall.bind(program);

        var resolveBinding = drawCall.bindUniform(input, bindings, defaultValues);
        var resolvedBindings = drawCall.bindSamplerStates(input, bindings, defaultValues);

        var samplers = drawCall.samplers;

        assertEquals(resolvedBindings.length, 3);
        assertEquals(resolvedBindings[0], null);
        assertEquals(resolvedBindings[1], null);
        assertFalse(resolvedBindings[2] == null);

        assertEquals(samplers.length, 1);
        assertEquals(samplers[0].location, location);
        assertEquals(samplers[0].wrapMode, SamplerStates.DEFAULT_WRAP_MODE);
        assertEquals(samplers[0].textureFilter, SamplerStates.DEFAULT_TEXTURE_FILTER);
        assertEquals(samplers[0].mipFilter, p.get(mipFilterBindingName));
    }
}
