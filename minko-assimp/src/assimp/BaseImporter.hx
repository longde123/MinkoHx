package assimp;

import assimp.IOSystem.IOStream;
import assimp.format.Scene.AiScene;
import assimp.ImporterDesc.AiImporterDesc;
class BaseImporter {
    static public function AI_MAKE_MAGIC(string:String) {
        return (string.charCodeAt(0) << 24) + (string.charCodeAt(1) << 16) + (string.charCodeAt(2) << 8) + string.charCodeAt(3);
    }


    /** Called by Importer::GetImporterInfo to get a description of some loader features. Importers must provide this
     *  information. */
    public var info:AiImporterDesc;
    /** The error description of the last error that occurred. An empty string if there was no error.    */
    public var errorText:String;//= ""

/** Currently set progress handler. */
    public var progress:ProgressHandler;

    public function new() {

    }
/** Returns whether the class can handle the format of the given file.
     *.
     *  The implementation should be as quick as possible. A check for the file extension is enough. If no suitable
     *  loader is found with this strategy, canRead() is called again, the 'checkSig' parameter set to true this time.
     *  Now the implementation is expected to perform a full check of the file structure, possibly searching the first
     *  bytes of the file for magic identifiers or keywords.
     *
     *  @param file Path and file name of the file to be examined.
     *  @param checkSig Set to true if this method is called a second time. This time, the implementation may take more
     *  time to examine the contents of the file to be loaded for magic bytes, keywords, etc to be able to load files
     *  with unknown/not existent file extensions.
     *  @return true if the class can read this file, false if not. */
    public function canRead(file:String, ioStream:IOStream, checkSig:Bool):Bool {
        return false;
    }

    /** Imports the given file and returns the imported data.
     *  If the import succeeds, ownership of the data is transferred to the caller. If the import fails, null is
     *  returned. The function takes care that any partially constructed data is destroyed beforehand.
     *
     *  @param imp Importer object hosting this loader.
     *  @param file Path of the file to be imported.
     *  @return The imported data or null if failed. If it failed a human-readable error description can be retrieved
     *  by accessing errorText
     *
     *  @note This function is not intended to be overridden. Implement internReadFile() to do the import. If an
     *  exception is thrown somewhere in internReadFile(), this function will catch it and transform it into a suitable
     *  response to the caller.
     */
    public function readFile(imp:ImporterPimpl, ioStream:IOStream, filePath:String, buffers:Array<IOStream>):Null<AiScene> {

        progress = imp.progressHandler;
///assert(progress != null)

        // Gather configuration properties for this run
        setupProperties(imp);

        // create a scene object to hold the data
        var sc = new AiScene();

        // dispatch importing

        internReadFile(filePath, ioStream, sc, buffers);

        // return what we gathered from the import.
        return sc;
    }

    /** Called prior to ReadFile().
     *  The function is a request to the importer to update its configuration basing on the Importer's configuration
     *  property list.
     *  @param imp Importer instance
     */
    public function setupProperties(imp:ImporterPimpl) {

    }


    /** Called by Importer::GetExtensionList for each loaded importer.
     *  Take the extension list contained in the structure returned by info and insert all file extensions into the
     *  given set.
     *  @param extension set to collect file extensions in*/
    public function extensionList() {
        return info.fileExtensions;
    }

    /** Imports the given file into the given scene structure. The function is expected to throw an ImportErrorException
     *  if there is an error. If it terminates normally, the data in AiScene is expected to be correct. Override this
     *  function to implement the actual importing.
     * <br>
     *  The output scene must meet the following requirements:<br>
     * <ul>
     * <li>At least a root node must be there, even if its only purpose is to reference one mesh.</li>
     * <li>AiMesh.primitiveTypes may be 0. The types of primitives in the mesh are determined automatically in this
     *  case.</li>
     * <li>the vertex data is stored in a pseudo-indexed "verbose" format.
     *  In fact this means that every vertex that is referenced by a face is unique. Or the other way round: a vertex
     *  index may not occur twice in a single AiMesh.</li>
     * <li>AiAnimation.duration may be -1. Assimp determines the length of the animation automatically in this case as
     *  the length of the longest animation channel.</li>
     * <li>AiMesh.bitangents may be null if tangents and normals are given. In this case bitangents are computed as the
     *  cross product between normal and tangent.</li>
     * <li>There needn't be a material. If none is there a default material is generated. However, it is recommended
     *  practice for loaders to generate a default material for yourself that matches the default material setting for
     *  the file format better than Assimp's generic default material. Note that default materials *should* be named
     *  AI_DEFAULT_MATERIAL_NAME if they're just color-shaded or AI_DEFAULT_TEXTURED_MATERIAL_NAME if they define a
     *  (dummy) texture. </li>
     * </ul>
     *  If the AI_SCENE_FLAGS_INCOMPLETE-Flag is <b>not</b> set:<ul>
     * <li> at least one mesh must be there</li>
     * <li> there may be no meshes with 0 vertices or faces</li>
     * </ul>
     *  This won't be checked (except by the validation step): Assimp will crash if one of the conditions is not met!
     *
     *  @param file Path of the file to be imported.
     *  @param scene The scene object to hold the imported data. Null is not a valid parameter.
     *  */
    public function internReadFile(file:String, ioStream:IOStream, pScene:AiScene, buffers:Array<IOStream>):Void {

    }

    /** Extract file extension from a string
         *  @param file Input file
         *  @return extension without trailing dot, all lowercase
         */
    public function getExtension(file:String):String {
        var pos = file.lastIndexOf('.');

        // no file extension at all
        if (pos == -1) return "";

        return file.substring(pos + 1).toLowerCase(); // thanks to Andy Maloney for the hint
    }
}
