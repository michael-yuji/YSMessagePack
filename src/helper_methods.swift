//
//  helper_methods.swift
//  messagePack
//
//  Created by 悠二 on 11/3/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation

public typealias ByteArray      = [UInt8]

public extension Array
{
    func dataValue() -> NSData {return NSData(bytes: self, length: self.count)}
    
    mutating func flip() {
        var temp = self
        var buffer = [Element]()
        buffer.reserveCapacity(temp.count)
        for (var i = temp.count; i > 0 ; i--) {
            buffer.append(temp[i - 1])
        }
        self = buffer
    }
    
    mutating func flip(exception: Int) {
        var temp = self
        let ex   = self[exception]
        temp.removeAtIndex(exception)
        temp.flip()
        temp.insert(ex, atIndex: exception)
        self = temp
    }

}

extension Int {
    //Helper methods
    var _16_bit_array: ByteArray {
        get {
            return ByteArray(arrayLiteral: UInt8( self >> 8),
                UInt8((self ^ (self >> 8) * 0x100))
            )
        }
    }
    
    var _32_bit_array: ByteArray {
        get {
            return ByteArray(arrayLiteral:  UInt8((self >> 24)                       ),
                UInt8((self >> 16) ^ (self >> 24) * 0x100),
                UInt8((self >> 8 ) ^ (self >> 16) * 0x100),
                UInt8 (self        ^ (self >>  8) * 0x100)
            )
        }
    }
    
}

extension UInt8
{
    func _16bitValue(jointWith value: UInt8) -> Int {return Int(self) * 0x100 + Int(value)}
    func _32bitValue(joinWith value1: UInt8, and value2: UInt8) -> Int {return Int(self) * 0x10000 + Int(value1) * 0x100 + Int(value2)}
    
    #if arch(arm64)
    func _64bitValue(joinWith value1: UInt8,
        _ value2: UInt8,
        _ value3: UInt8,
        _ value4: UInt8,
        _ value5: UInt8,
        _ value6: UInt8,
        _ value7: UInt8) -> Int
    { return    Int(self)   * 0x10000_0000_0000_00 +
        Int(value1) * 0x10000_0000_0000 +
        Int(value2) * 0x10000_0000_00 +
        Int(value3) * 0x10000_0000 +
        Int(value4) * 0x10000_00 +
        Int(value5) * 0x10000 +
        Int(value6) * 0x100 +
        Int(value7)
    }
    #endif
}
