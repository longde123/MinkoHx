package minko.async;

/**
 * Minimal execution interface used by AbstractCanvas to poll workers without
 * depending on the concrete Worker type.
 */
interface IWorker {
    function poll():Void;
}
