package minko.file;
import minko.signal.Signal2;
class AbstractWriterPreprocessor {
    public var statusChanged(get, null):Signal2<AbstractWriterPreprocessor, String>;


    public function new() {
    }

    public function progressRate() {
        return 0.0;
    }

    function get_statusChanged() {
        return null;
    }

    public function process(writable:Dynamic, assetLibrary:AssetLibrary) {

    }
}
