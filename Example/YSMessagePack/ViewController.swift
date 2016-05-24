//
//  ViewController.swift
//  YSMessagePack
//
//  Created by yuji on 05/24/2016.
//  Copyright (c) 2016 yuji. All rights reserved.
//

import UIKit
import YSMessagePack

struct MyDataStructure : Packable, CustomStringConvertible {
    var name: String
    var id: Int
    var boolVal: Bool
    
    var description: String {
        get {
            return "name: \(name)\nid: \(id)\nboolVal: \(boolVal)"
        }
    }
    
    func packFormat() -> [Packable] {
        // MessagePack only accept basic data structure,
        // therefore you need to define your own 'rule' on
        // how your data structure should be pack
        return [name, id, boolVal]
    }
    
    func msgtype() -> MsgPackTypes {
        return .Custom
    }
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let someString = "This is some string value"
        let someInteger = 1012312312312312
        let someDouble  = 1.231312312
        let someBool = true
        let myOwnDataStructure = MyDataStructure(name: "My Bug", id: 1, boolVal: true)
        // Now we want to pack them and send across
        // the `payload` is a NSData Object and you just
        // send them across
        let payload = packItems([someString, someInteger, someDouble, someBool, myOwnDataStructure])
        
        
        // Now unpack our packed data
        // This will return an array of `NSData`,
        // And you need to cast them to the desire type
        let unpack = try! payload.unpack()
        
        print(unpack.count)
        
        let strUnpacked = unpack[0].castToString()
        let intUnpacked = unpack[1].castToInt
        let doubleUnpacked = unpack[2].castToDouble
        let boolUnpacked = unpack[3].castToBool
        
        let myUnpackedDataStructure // put our data structure together
            = MyDataStructure(name:     unpack[4].castToString()!,
                              id:       unpack[5].castToInt,
                              boolVal:  unpack[6].castToBool!)
        
        print(strUnpacked)
        print(intUnpacked)
        print(doubleUnpacked)
        print(boolUnpacked)
        print()
        print(myUnpackedDataStructure)
    }
    
}

