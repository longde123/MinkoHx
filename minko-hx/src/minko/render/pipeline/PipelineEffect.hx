package minko.render.pipeline;

/**
 * Pipeline-native effect: a set of stage techniques. It is the only effect
 * representation used by the new render pipeline.
 */
class PipelineEffect {
    public var name:String;
    public var techniques:Array<PipelineTechnique>;

    public function new(name:String = "") {
        this.name = name;
        this.techniques = [];
    }

    public static function create(name:String = ""):PipelineEffect {
        return new PipelineEffect(name);
    }

    public function addTechnique(technique:PipelineTechnique):PipelineTechnique {
        if (technique == null) {
            throw "PipelineEffect.addTechnique(): technique cannot be null";
        }
        techniques.push(technique);
        return technique;
    }

    public function techniqueFor(stage:EffectStage):PipelineTechnique {
        for (technique in techniques) {
            if (technique.stage == stage) {
                return technique;
            }
        }
        return null;
    }

    public function hasTechniqueFor(stage:EffectStage):Bool {
        return techniqueFor(stage) != null;
    }
}
