//
//  msgpackMain.swift
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

struct TestObject: Packable, CustomStringConvertible {
    var name: String
    var index: Int
    var array: [Int]
    
    func packFormat() -> [AnyObject] {
        return [name, index, array]
    }
    
    var description: String {
        get {
            return "name: \(name)|index: \(index)|array: \(array)\n"
        }
    }
    
}

func packUnpackGroupTest() {
    let testObj1 = TestObject(name: "TestObject1", index: 1, array: [0])
    let testObj2 = TestObject(name: "TestObject2", index: 2, array: [0,1])
    let testObj3 = TestObject(name: "TestObject3", index: 3, array: [0,1,2])
    let testObj4 = TestObject(name: "TestObject4", index: 4, array: [0,1,2,3])
    let testObj5 = TestObject(name: "TestObject5", index: 5, array: [0,1,2,3,4])
    let badObj   = TestObject(name: "badObject", index: -100, array: [])
    let testObj6 = TestObject(name: "TestObject6", index: 6, array: [0,1,2,3,4,5])
    let testObj7 = TestObject(name: "TestObject7", index: 7, array: [0,1,2,3,4,5,6])
    let testObj8 = TestObject(name: "TestObject8", index: 8, array: [0,1,2,3,4,5,6,7])
    let testObj9 = TestObject(name: "TestObject9", index: 9, array: [0,1,2,3,4,5,6,7,8])
    let testObj0 = TestObject(name: "TestObject0", index: 0, array: [0,1,2,3,4,5,6,7,8,9])
    
    
    // Remove the inline command to test `badObj` case
    let packed = packItems([Mask(testObj1),Mask(testObj2),/* Mask(badObj), */ Mask(testObj3),Mask(testObj4),Mask(testObj5),Mask(testObj6),Mask(testObj7),Mask(testObj8),Mask(testObj9),Mask(testObj0)])
    
    
    do {
        
        var goodTestObjects = [TestObject]()
        
        //Here we unpack 3 objects as a group and unpack 8 set of group. We will use objects unpacked in each group to construct an TestObject and add to an array
        //We will also abort execution if we found a bad `TestObject` with name `badObject`
        
        try packed.unpackByGroupsWith(3, numberOfSetsToUnpack: 8) { (unpackedData, isLast) -> Bool in
            guard let name = unpackedData[0].castToString() else {return false}
            let index = unpackedData[1].castToInt
            let array = unpackedData[2].mapUnpackedArray({$0.castToInt})
            let testObj = TestObject(name: name, index: index, array: array)
            
            if testObj.name == "badObject" {
                NSLog("Bad Object found, abort unpacking")
                NSLog("TestObjects unpacked: \(goodTestObjects)")
                return false //abort
            }
            
            goodTestObjects.append(testObj)
            
            if isLast {
                NSLog("The last object has been unpacked:\n\(goodTestObjects)")
            }
            
            return true //continue
        }
        
    } catch {
        print(error)
    }
}