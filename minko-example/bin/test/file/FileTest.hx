package test.file;
import minko.file.File;
class FileTest extends haxe.unit.TestCase {

    public function testCreate() {

        var g = minko.file.File.create();

        assertTrue(true);

    }


    public function testCanonizeFilename() {
        assertEquals("foo", File.canonizeFilename("foo"));
        assertEquals("foo", File.canonizeFilename("./foo"));
        assertEquals("../foo", File.canonizeFilename("../foo"));
        assertEquals("foo/bar", File.canonizeFilename("foo/bar"));
        assertEquals("foo/bar/qux", File.canonizeFilename("foo/bar/qux"));
        assertEquals("foo/bar", File.canonizeFilename("./foo/bar"));
        assertEquals("foo/bar", File.canonizeFilename("foo/./bar"));
        assertEquals("../foo", File.canonizeFilename("./../foo"));
        assertEquals("foo", File.canonizeFilename("foo/bar/.."));
        assertEquals("foo", File.canonizeFilename("./foo/../foo"));
        assertEquals("..", File.canonizeFilename("../"));
        assertEquals("/", File.canonizeFilename("/"));
        assertEquals("/", File.canonizeFilename("//"));
        assertEquals("/", File.canonizeFilename("///./"));
        assertEquals(".", File.canonizeFilename("foo/../foo/.."));
        assertEquals(".", File.canonizeFilename("foo/foo/../.."));
        assertEquals("../..", File.canonizeFilename("../.."));
        assertEquals("../../..", File.canonizeFilename("../.././.."));
        assertEquals(".", File.canonizeFilename(""));
    }


    public function testSanitizeFilename() {
        assertEquals("../foo", File.sanitizeFilename("../foo"));
        assertEquals("../foo", File.sanitizeFilename("..\\foo"));
    }

}
