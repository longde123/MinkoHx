package minko.utils;

class VectorHelper {

    static public function resize<T>(list:Array<T>, newSize:Int, value:T) {
        if (list.length > newSize) {
            while (list.length > newSize) {
                list.pop();
            }
        }
        else if (list.length < newSize) {
            for (i in list.length... newSize) {
                list.push(value);
            }
        }
    }

    static public function equals<T>(list1:Array<T>, list2:Array<T>) {
        if (list1.length != list2.length) {
            return false;
        }
        for (i in 0...list2.length) {
            if (list1[i] != list2[i]) {
                return false;
            }
        }
        return true;
    }

    static public function swap<T>(list1:Array<T>, list2:Array<T>) {
        var temp = list1.copy();
        resize(list1, list2.length, null);
        for (i in 0...list2.length) {
            list1[i] = list2[i];
        }
        resize(list2, temp.length, null);
        for (i in 0...temp.length) {
            list2[i] = temp[i];
        }
    }

    static public function initializedList<T>(size:Int, value:T) {
        var temp = new Array<T>();
        for (count in 0... size) {
            temp.push(value);
        }

        return temp;
    }


    static public function nestedList<T>(outerSize:Int, innerSize:Int, value:T) {

        var temp = new Array<Array<T>>();
        for (count in 0... outerSize) {
            temp.push(initializedList(innerSize, value));
        }

        return temp;
        return temp;
    }
}
