package minko.utils;
class StringFunctions {
    //------------------------------------------------------------------------------------
    //	This method allows replacing a single character in a string, to help convert
    //	C++ code where a single character in a character array is replaced.
    //------------------------------------------------------------------------------------
    static public function changeCharacter(sourceString:String, charIndex:Int, changeChar:String) {
        return (charIndex > 0 ? sourceString.substring(0, charIndex) : "")
        + changeChar + (charIndex < sourceString.length - 1 ? sourceString.substring(charIndex + 1) : "");
    }

    //------------------------------------------------------------------------------------
    //	This method replicates the classic C string function 'isxdigit' (and 'iswxdigit').
    //------------------------------------------------------------------------------------
    static public function isDigit(character:String) {
        //todo;
        return false;
    }

    static public function isXDigit(character:String) {
        if (isDigit(character))
            return true;
        else if ("ABCDEFabcdef".indexOf(character) > -1)
            return true;
        else
            return false;
    }

    //------------------------------------------------------------------------------------
    //	This method replicates the classic C string function 'strchr' (and 'wcschr').
    //------------------------------------------------------------------------------------
    static public function strChr(stringToSearch:String, charToFind:String) {
        var index = stringToSearch.indexOf(charToFind);
        if (index > -1)
            return stringToSearch.substring(index);
        else
            return null;
    }

    //------------------------------------------------------------------------------------
    //	This method replicates the classic C string function 'strrchr' (and 'wcsrchr').
    //------------------------------------------------------------------------------------
    static public function strRChr(stringToSearch:String, charToFind:String) {
        var index = stringToSearch.lastIndexOf(charToFind);
        if (index > -1)
            return stringToSearch.substring(index);
        else
            return null;
    }

    //------------------------------------------------------------------------------------
    //	This method replicates the classic C string function 'strstr' (and 'wcsstr').
    //------------------------------------------------------------------------------------
    static public function strStr(stringToSearch:String, stringToFind:String) {
        var index = stringToSearch.indexOf(stringToFind);
        if (index > -1)
            return stringToSearch.substring(index);
        else
            return null;
    }

//------------------------------------------------------------------------------------
//	This method replicates the classic C string function 'strtok' (and 'wcstok').
//	Note that the .NET string 'Split' method cannot be used to replicate 'strtok' since
//	it doesn't allow changing the delimiters between each token retrieval.
//------------------------------------------------------------------------------------
    private static var activeString:String;
    private static var activePosition:Int;

    static public function strTok(stringToTokenize:String, delimiters:String) {
        if (stringToTokenize != null) {
            activeString = stringToTokenize;
            activePosition = -1;
        }

        //the stringToTokenize was never set:
        if (activeString == null)
            return null;

        //all tokens have already been extracted:
        if (activePosition == activeString.length)
            return null;

        //bypass delimiters:
        activePosition++;
        while (activePosition < activeString.length && delimiters.indexOf(activeString.charAt(activePosition)) > -1) {
            activePosition++;
        }

        //only delimiters were left, so return null:
        if (activePosition == activeString.length)
            return null;

        //get starting position of string to return:
        var startingPosition = activePosition;

        //read until next delimiter:
        do {
            activePosition++;
        } while (activePosition < activeString.length && delimiters.indexOf(activeString.charAt(activePosition)) == -1);

        return activeString.substring(startingPosition, activePosition - startingPosition);
    }

}
