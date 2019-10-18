package minko.file;
import Lambda;
import minko.signal.Signal;
import haxe.io.Bytes;
import Lambda;
import minko.component.JobManager.Job;
import minko.file.Options.FileStatus;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
class Parameters {
    public var maxNumActiveParsers:Int;
    public var useJobBasedParsing:Bool;
    public var requestAbortingEnabled:Bool;
    public var abortableRequestProgressThreshold:Float;

    public function new() {
        this.maxNumActiveParsers = 20;
        this.useJobBasedParsing = false;
        this.requestAbortingEnabled = true;
        this.abortableRequestProgressThreshold = 0.5;
    }
}

class ParserEntry {
    public var parser:AbstractStreamedAssetParser;
    public var loaderErrorSlot:SignalSlot2<LinkedAsset, String>;
    public var loaderCompleteSlot:SignalSlot2<LinkedAsset, Bytes>;
    public var parserBeforePriorityChangedSlot:SignalSlot2<AbstractStreamedAssetParser, Float>;
    public var parserPriorityChangedSlot:SignalSlot2<AbstractStreamedAssetParser, Float>;
    public var parserLodRequestCompleteSlot:SignalSlot<AbstractStreamedAssetParser>;
    public var parserErrorSlot:SignalSlot2<AbstractParser, String>;
    public var parserCompleteSlot:SignalSlot<AbstractParser>;
    public var pendingData:Bytes;

    public function new(parser:AbstractStreamedAssetParser) {
        this.parser = parser;
    }
}

class ParserEntryPriorityComparator {
    public static function functorMethod(left:ParserEntry, right:ParserEntry) {
        var epsilon = 1e-3;

        var leftPriority = left.parser.priority;
        var rightPriority = right.parser.priority;

        if (leftPriority > rightPriority) {
            return true;
        }

        if (rightPriority > leftPriority) {
            return false;
        }

        if (left < right) {
            return true;
        }

        if (right < left) {
            return false;
        }

        return false;
    }
}
class StreamedAssetParserScheduler extends Job {
    private var _options:Options;
    private var _entries:Array< ParserEntry >;
    private var _activeEntries:Array< ParserEntry >;
    private var _pendingDataEntries:Array< ParserEntry >;
    private var _parameters:Parameters;
    private var _complete:Bool;
//private var _priority:Float;

    private var _active:Signal<StreamedAssetParserScheduler>;
    private var _inactive:Signal<StreamedAssetParserScheduler>;

    public static function create(options:Options, parameters:Parameters) {
        return new StreamedAssetParserScheduler(options, parameters);
    }
    public var active(get, null):Signal<StreamedAssetParserScheduler>;

    function get_active() {
        return _active;
    }
    public var inactive(get, null):Signal<StreamedAssetParserScheduler>;

    function get_inactive() {
        return _inactive;
    }


    public function new(options:Options, parameters:Parameters) {
        super();
        this._options = options;
        this._entries = [];
        this._activeEntries = [];
        this._parameters = parameters;
        this._complete = false;
        this._active = new Signal<StreamedAssetParserScheduler>();
        this._inactive = new Signal<StreamedAssetParserScheduler>();
    }

    public function addParser(parser:AbstractStreamedAssetParser) {
        var entry = new ParserEntry(parser);
        _entries.push(entry);
        entry.parserErrorSlot = parser.error.connect(function(parser:AbstractParser, error:String) {
            removeEntry(entry);
        });

        entry.parserCompleteSlot = parser.complete.connect(function(parser:AbstractParser) {
            removeEntry(entry);
        });

        startListeningToEntry(entry);
    }

    public function removeParser(parser:AbstractStreamedAssetParser) {

        var entryIt = Lambda.find(_entries, function(entry:ParserEntry) {
            return entry.parser == parser;
        });

        if (entryIt != null) {
            removeEntry(entryIt);
        }
    }

    override function set_priority(value) {
        if (_priority == value) {
            return;
        }

        var previousValue = _priority;

        _priority = value;

        if (_priority <= 0.0) {
            inactive.execute(this);
        }
        else if (previousValue <= 0.0 && _activeEntries.length > 0) {
            active.execute(this);
        }
        return value;
    }

    override function get_priority() {
        if (Lambda.empty(_pendingDataEntries) && (!hasPendingRequest() || _activeEntries.length >= _parameters.maxNumActiveParsers)) {
            return 0.0 ;
        }

        return _priority;
    }

    override function get_complete() {
        return _complete;
    }

    override public function step() {
        while (hasPendingRequest() && _activeEntries.length < _parameters.maxNumActiveParsers) {
            var entry = headingParser();

            if (!entry.parser.prepareForNextLodRequest()) {
                continue;
            }

            popHeadingParser();

            var previousNumActiveEntries = _activeEntries.length;
            var numActiveEntries = previousNumActiveEntries + 1;

            _activeEntries.insert(entry);

            entryActivated(entry, numActiveEntries, previousNumActiveEntries);

            executeRequest(entry);
        }

        for (entry in _pendingDataEntries) {
            entry.parser.lodRequestFetchingComplete(entry.pendingData);

//List<byte>().swap(entry.pendingData);
        }

        _pendingDataEntries=[];
    }

    override public function beforeFirstStep() {
    }

    override public function afterLastStep() {
    }

    public function hasPendingRequest() {
        return _entries.length > 0 && headingParser().parser.priority > 0.0;
    }

    function headingParser():ParserEntry {
        return _entries.iterator().next();
    }

    public function popHeadingParser() {
        var entryIt = _entries.iterator().next();
        var entry = entryIt;

        _entries.remove(entryIt);

        return entry;
    }

    public function removeEntry(entry:ParserEntry) {
        stopListeningToEntry(entry);

        entry.parserErrorSlot = null;
        entry.parserCompleteSlot = null;

        _entries.remove(entry);

        var previousNumActiveEntries = _activeEntries.length;

        _activeEntries.remove(entry);

        var numActiveEntries = _activeEntries.length;

        entryDeactivated(entry, numActiveEntries, previousNumActiveEntries);

        if (_entries.length == 0 && _activeEntries.length == 0) {
            _complete = true;
        }
    }

    public function executeRequest(entry:ParserEntry) {
        stopListeningToEntry(entry);

        var parser = entry.parser;

        var offset = 0;
        var size = 0;

        parser.getNextLodRequestInfo(offset, size);

        var linkedAsset = parser.linkedAsset;

        var filename = linkedAsset.filename;

        var options = _options;
        options.parserFunction = (function(extension) {
            return null;
        });
        options.seekingOffset = (offset);
        options.seekedLength = (size);
        options.loadAsynchronously = (true);
        options.storeDataIfNotParsed = (false);

        if (_parameters.requestAbortingEnabled) {

            options.fileStatusFunction = (function(file:File, progress:Float) {
                if (progress < 1.0 && entry.parser.priority <= 0.0) {
                    return FileStatus.Aborted;
                }

                if (progress < _parameters.abortableRequestProgressThreshold) {
                    if (_priority <= 0.0) {
                        return FileStatus.Aborted;
                    }

                    var priorityRank = 0;

                    for (inactiveEntry in _entries) {
                        if (priorityRank >= _parameters.maxNumActiveParsers || inactiveEntry.parser.priority - entry.parser.priority < 1e-3) {
                            break;
                        }

                        ++priorityRank;
                    }

                    if (priorityRank >= _parameters.maxNumActiveParsers) {
                        return Options.FileStatus.Aborted;
                    }
                }

                return Options.FileStatus.Pending;
            });
        }

        entry.loaderErrorSlot = linkedAsset.error.connect(function(loaderThis:LinkedAsset, error) {
            parser.lodRequestFetchingError(("StreamedAssetLoadingError" + "Failed to load streamed asset " + filename));

            requestDisposed(entry);
        });

        entry.loaderCompleteSlot = linkedAsset.complete.connect(function(loaderThis:LinkedAsset, data:Bytes) {
            requestComplete(entry, data);
        });

        parser.lodRequestFetchingBegin();

        linkedAsset.resolve(options);
    }

    public function requestComplete(entry:ParserEntry, data:Bytes) {

        entry.parserLodRequestCompleteSlot = entry.parser.lodRequestComplete.connect(function(parser:AbstractStreamedAssetParser) {
            requestDisposed(entry);
        });

        entry.parser.useJobBasedParsing(_parameters.useJobBasedParsing ? jobManager : null);

        if (_priority > 0.0) {
            entry.parser.lodRequestFetchingComplete(data);
        }
        else {
            _pendingDataEntries.insert(entry);

            entry.pendingData = data;
        }
    }

    public function requestDisposed(entry:ParserEntry) {
        entry.loaderErrorSlot = null;
        entry.loaderCompleteSlot = null;
        entry.parserLodRequestCompleteSlot = null;

        var previousNumActiveEntries = _activeEntries.length;
        var numActiveEntries = previousNumActiveEntries - 1;

        if (Lambda.has(_activeEntries, entry) == false) {
            return;
        }

        entryDeactivated(entry, numActiveEntries, previousNumActiveEntries);

        _entries.insert(entry);

        startListeningToEntry(entry);
    }

    public function startListeningToEntry(entry:ParserEntry) {
        entry.parserBeforePriorityChangedSlot = entry.parser.beforePriorityChanged.connect(function(parser:AbstractStreamedAssetParser, priority:Float) {
            _entries.remove(entry);
        });

        entry.parserPriorityChangedSlot = entry.parser.priorityChanged.connect(function(parser:AbstractStreamedAssetParser, priority:Float) {
            _entries.push(entry);
        });
    }

    public function stopListeningToEntry(entry:ParserEntry) {
        entry.parserBeforePriorityChangedSlot = null;
        entry.parserPriorityChangedSlot = null;
    }

    public function entryActivated(entry:ParserEntry, numActiveEntries:Int, previousNumActiveEntries:Int) {
        if (previousNumActiveEntries == 0 && numActiveEntries > 0) {
            active.execute(this);
        }
    }

    public function entryDeactivated(entry:ParserEntry, numActiveEntries:Int, previousNumActiveEntries:Int) {
        if (previousNumActiveEntries > 0 && numActiveEntries == 0) {
            inactive.execute(this);
        }
    }

}
