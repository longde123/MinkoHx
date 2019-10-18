package minko.file;
import minko.signal.Signal2;
import minko.component.JobManager;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.component.JobManager.Job;
import minko.data.Provider;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal;
import minko.StreamingCommon;
class ParsingJob extends Job {

    private var _parsingFunction:Void -> Void;
    private var _completeFunction:Void -> Void;
    private var _complete:Bool;
    //private var _priority:Float;
    private var _readingHeader:Bool;


    public static function create(parsingFunction:Void -> Void, completeFunction:Void -> Void, priority = 1.0) {
        return (new ParsingJob(parsingFunction, completeFunction, priority));
    }

    override function get_complete() {
        return _complete;
    }

    override public function beforeFirstStep() {
    }

    override public function step() {
        if (_parsingFunction != null) {
            _parsingFunction();
        }

        _complete = true;
    }

    override function set_priority(p) {
        if (_priority == p) {
            return p;
        }

        if (_readingHeader) {
            _priority = p;

            return p;
        }

        beforePriorityChanged.execute((this), _priority);

        _priority = priority;

        priorityChanged.execute((this), priority);
        return p;
    }

    override function get_priority() {
        return _priority;
    }

    override public function afterLastStep() {
        if (_completeFunction != null) {
            _completeFunction();
        }
    }

    public function new(parsingFunction:Void -> Void, completeFunction:Void -> Void, priority) {
        this._parsingFunction = parsingFunction;
        this._completeFunction = completeFunction;
        this._complete = false;
        this._priority = priority;
    }
}
class AbstractStreamedAssetParser extends AbstractSerializerParser {
    private var _assetLibrary:AssetLibrary;
    private var _options:Options;

    private var _streamingOptions:StreamingOptions;

    private var _linkedAsset:LinkedAsset;

    private var _jobManager:JobManager;

//private var _filename:String;
//private var _resolvedFilename:String;
    private var _assetExtension:Int;
    private var _fileOffset:Int;

    private var _deferParsing:Bool;
    private var _dependencyId:Int;

    private var _headerIsRead:Bool;
    private var _readingHeader:Bool;

    private var _previousLod:Int;
    private var _currentLod:Int;

    private var _nextLodOffset:Int;
    private var _nextLodSize:Int;

    private var _loaderErrorSlot:SignalSlot2<LinkedAsset, String>;
    private var _loaderCompleteSlot:SignalSlot2<LinkedAsset, Bytes> ;


//private var _complete:Bool;

    private var _data:Provider;
    private var _dataPropertyChangedSlot:SignalSlot2<Provider, String> ;

    private var _requiredLod:Int;
    private var _priority:Float;

    private var _beforePriorityChanged:Signal2<AbstractStreamedAssetParser, Float>;
    private var _priorityChanged:Signal2<AbstractStreamedAssetParser, Float>;
    private var _lodRequestComplete:Signal<AbstractStreamedAssetParser>;

    private var _ready:Signal<AbstractStreamedAssetParser>;
//private var _progress :Signal2<AbstractStreamedAssetParser, Float>;
    private var  completeLod:Array<Int>;
    public var priority(get, set):Float;

    function get_priority() {
        if (_readingHeader) {
            return 0.0 ;
        }

        return _priority;
    }

    function set_priority(p) {
        _priority = p;
        return p;
    }
 //   public var requiredLod(get, set):Float;

    function get_requiredLod() {
        return _requiredLod;
    }

    function set_requiredLod(p) {
        _requiredLod = p;
        return p;
    }


    public var data(get, set):Provider;

    function get_data() {
        return _data;
    }

    function set_data(d) {
        _data = d;

        return d;
    }
    public var streamingOptions(get, set):StreamingOptions;

    function set_streamingOptions(s) {
        _streamingOptions = s;
        return s;
    }

    function get_streamingOptions() {
        return _streamingOptions;
    }

    public var linkedAsset(get, set):LinkedAsset;

    function get_linkedAsset() {
        return _linkedAsset;
    }

    function set_linkedAsset(l) {
        _linkedAsset = l;
        return l;
    }

    public function useJobBasedParsing(jobManager:JobManager) {
        _jobManager = jobManager;
    }

    public var priorityChanged(get, null):Signal2<AbstractStreamedAssetParser, Float>;

    function get_priorityChanged() {
        return _priorityChanged;
    }

    public var beforePriorityChanged(get, null):Signal2<AbstractStreamedAssetParser, Float>;

    function get_beforePriorityChanged() {
        return _beforePriorityChanged;
    }
    public var lodRequestComplete(get, null):Signal<AbstractStreamedAssetParser >;

    function get_lodRequestComplete() {
        return _lodRequestComplete;
    }

    public var ready(get, null):Signal<AbstractStreamedAssetParser>;

    function get_ready() {
        return _ready;
    }

    override function get_progress() {
        return _progress;
    }


    public var deferParsing(get, set):Bool;

    public function set_deferParsing(d) {
        _deferParsing = true;

        _dependencyId = d;
        return d;
    }

    function get_deferParsing() {
        return _deferParsing;
    }

    public var dependencyId(get, null):Int;

    function get_dependencyId() {
        return _dependencyId;
    }

    public function useDescriptor(filename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        return false;
    }

    public function parsed(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

    }

    public function headerParsed(data:Bytes, options:Options, linkedAssetId:Int):Void {

    }

    public function lodParsed(previousLod:Int, currentLod:Int, data:Bytes, options:Options) {

    }

    public function setComplete(currentLod) {
        return false;
    }

    public function completed() {

    }

    public function lodRangeFetchingBound(currentLod:Int, requiredLod:Int, lodRangeMinSize:Int, lodRangeMaxSize:Int, lodRangeRequestMinSize:Int, lodRangeRequestMaxSize:Int)
    :minko.Tuple.Tuple4<Int,Int,Int,Int>
    {
        return null;
    }

    public function lodRangeRequestByteRange(lowerLod:Int, upperLod:Int, offset:Int, size:Int ):minko.Tuple<Int,Int> {
        return null;

    }

    public function lodLowerBound(lod) {
        return 0;
    }

    public var maxLod(get, null):Int;

    function get_maxLod() {
        return 0;
    }
    public var assetExtension(null, set):Int;

    function set_assetExtension(value) {
        _assetExtension = value;
        return value;
    }

    public var assetHeaderOffset(get, null):Int;

    function get_assetHeaderOffset() {
        return 0;
    }

    public var streamedAssetHeaderOffset(get, null):Int;

    function get_streamedAssetHeaderOffset() {
        return assetHeaderOffset + StreamingCommon.MINKO_SCENE_HEADER_SIZE + _dependencySize;
    }


    public function new() {
        completeLod=[];
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        if (this.data != null) {
            _dataPropertyChangedSlot = this.data.propertyChanged.connect(function(provider:Provider, propertyName:String) {
                if (propertyName == "requiredLod") {
                    requiredLod = (provider.get(propertyName));
                }
                else if (propertyName == "priority") {
                    priority = (provider.get(propertyName));
                }
            });
        }

        _assetLibrary = assetLibrary;
        _options = options;

        _filename = filename;
        _resolvedFilename = resolvedFilename;

        if (useDescriptor(filename, options, data, assetLibrary)) {
            //只是头文件结束
            terminate();

            return;
        }

        if (_deferParsing) {
            return;
        }

        if (!_headerIsRead) {
            _headerIsRead = true;

            parseHeader(data, options);

            prepareNextLod();
        }

        parsed(filename, resolvedFilename, options, data, assetLibrary);

        ready.execute((this));
    }

    public function prepareForNextLodRequest() {
        if (_deferParsing && !_headerIsRead) {
            if (!_readingHeader) {
                parseStreamedAssetHeader();
            }

            return false;
        }

        return true;
    }

    public function getNextLodRequestInfo(offset:Int, size:Int) {
        //ref
        offset = _nextLodOffset;
        size = _nextLodSize;
    }

    public function lodRequestFetchingBegin() {
    }

    public function lodRequestFetchingProgress(progressRate:Float) {
    }

    public function lodRequestFetchingError(error) {
        this.error.execute(this, error);
    }

    public function lodRequestFetchingComplete(data:Bytes) {
        if (_jobManager) {

            var parsingJob = ParsingJob.create(function() {
                parseLod(_previousLod, _currentLod, data, _options);
            }, function() {

                lodRequestComplete.execute((this));

                prepareNextLod();
            }
            );

            _jobManager.pushJob(parsingJob);
        } else {
            parseLod(_previousLod, _currentLod, data, _options);

            lodRequestComplete.execute((this));

            prepareNextLod();
        }
    }

    function parseLod(previousLod:Int, currentLod:Int, data:Bytes, options:Options) {
        lodParsed(previousLod, currentLod, data, options);
    }

    function parseHeader(data:Bytes, options:Options) {
        readHeader(_filename, data, _assetExtension);

        var streamedAssetHeaderData = new BytesInput(data);
        streamedAssetHeaderData.position = streamedAssetHeaderOffset;

        var linkedAssetId = 0;

        headerParsed(streamedAssetHeaderData, options, linkedAssetId);

        if (_linkedAsset == null) {
            _linkedAsset = _dependency.getLinkedAssetReference(linkedAssetId);
        }
    }

    function prepareNextLod() {

        if (Lambda.has(completeLod,_currentLod)) {
            terminate();
        }
        else {
            _previousLod = _currentLod;
            completeLod.push(_currentLod);
            nextLod(_previousLod, _requiredLod, _currentLod, _nextLodOffset, _nextLodSize);
        }
    }

    function terminate() {
        _dataPropertyChangedSlot = null;

        completed();


        complete.execute(this);
    }

    function requiredLod(requiredLod) {
        if (_requiredLod == requiredLod) {
            return;
        }

        _requiredLod = requiredLod;

        if (!_headerIsRead) {
            return;
        }

        nextLod(_previousLod, _requiredLod, _currentLod, _nextLodOffset, _nextLodSize);
    }


    function nextLod(previousLod, requiredLod, nextLod, nextLodOffset, nextLodSize) {
        var lodRangeMinSize = 1;
        var lodRangeMaxSize = 0;
        var lodRangeRequestMinSize = 0;
        var lodRangeRequestMaxSize = 0;

         var t:minko.Tuple.Tuple4<Int,Int,Int,Int>= lodRangeFetchingBound(previousLod, requiredLod, lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize);
        lodRangeMinSize=t.first;
        lodRangeMaxSize=t.second;
        lodRangeRequestMinSize=t.thiree;
        lodRangeRequestMaxSize=t.four;

        var lowerLod = previousLod + 1;
        var upperLod = lowerLod;

        var requirementIsFulfilled = false;

        do {
            if (upperLod >= maxLod) {
                break;
            }

            var lodRangeSize = upperLod - lowerLod;

            if (lodRangeMinSize > 0 && lodRangeSize < lodRangeMinSize) {
                ++upperLod;

                continue;
            }

            if (lodRangeMaxSize > 0 && lodRangeSize >= lodRangeMaxSize) {
                break;
            }

            var lodRangeRequestOffset = 0;
            var lodRangeRequestSize = 0;

            var lt:minko.Tuple<Int,Int> =lodRangeRequestByteRange(lowerLod, upperLod, lodRangeRequestOffset, lodRangeRequestSize);
            lodRangeRequestOffset=lt.first;
            lodRangeRequestSize=lt.second;

            if (lodRangeRequestMaxSize > 0 && lodRangeRequestSize >= lodRangeRequestMaxSize) {
                break;
            }

            if (lodRangeRequestMinSize == 0 || lodRangeRequestSize >= lodRangeRequestMinSize) {
                requirementIsFulfilled = true;
            }
            else {
                ++upperLod;
            }
        } while (!requirementIsFulfilled);

        lowerLod = Math.min(maxLod, lowerLod);
        upperLod = Math.min(maxLod, upperLod);

        nextLod = lodLowerBound(upperLod);
        var lt:minko.Tuple<Int,Int> =lodRangeRequestByteRange(lowerLod, upperLod, nextLodOffset, nextLodSize);
        nextLodOffset=lt.first;
        nextLodSize=lt.second;

    }

    function parseStreamedAssetHeader() {
        beforePriorityChanged.execute((this), priority);
        _readingHeader = true;
        priorityChanged.execute((this), priority);
        var assetHeaderSize = StreamingCommon.MINKO_SCENE_HEADER_SIZE + 2;

        var headerOptions:Options = _options.clone();
        headerOptions.loadAsynchronously = (true);
        headerOptions.seekingOffset = (0);
        headerOptions.seekedLength = (assetHeaderSize);
        headerOptions.storeDataIfNotParsed = (false);
        headerOptions.parserFunction = (function(UnnamedParameter1) {
            return null;
        });

        _loaderErrorSlot = _linkedAsset.error.connect(function(linkedAssetThis, error) {
            _loaderErrorSlot = null;
            _loaderCompleteSlot = null;
            _readingHeader = false;
            this.error.execute(this, error);
        });

        _loaderCompleteSlot = _linkedAsset.complete.connect(function(linkedAsset:LinkedAsset, linkedAssetData:Bytes) {
                _loaderErrorSlot = null;
                _loaderCompleteSlot = null;
                _headerIsRead = true;
                beforePriorityChanged.execute(this, priority);
                _readingHeader = false;
                priorityChanged.execute((this), priority);
                parseHeader(linkedAssetData, _options);
                prepareNextLod();
                parsed(_filename, _resolvedFilename, _options, linkedAssetData, _assetLibrary);
                ready.execute((this));

        },0,true);

        _linkedAsset.resolve(headerOptions);
    }

}
