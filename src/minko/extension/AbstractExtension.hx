package minko.extension;
class AbstractExtension {
    public function bind() {

    }

    public function new() {
    }
}
class SerializerExtension<T> {
    static function activateExtension() {
        var extension = new T();

        return extension.bind();
    }
}
