//
//  misc.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

public typealias ByteArray      = [UInt8]

extension Array
{
    func dataValue() -> NSData {return NSData(bytes: self, length: self.count)}
    
    mutating func flip() {
        var temp = self
        var buffer = [Element]()
        buffer.reserveCapacity(temp.count)
        var i = temp.count
        while i > 0 {
            buffer.append(temp[i-1])
            i -= 1
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

public struct unpackOptions: OptionSetType {
    public var rawValue: UInt8
    public static let keepRemainingBytes = unpackOptions(rawValue: 1 << 1)
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

public struct packOptions: OptionSetType {
    public var rawValue: UInt8
    public static let PackWithASCIIStringEncoding  = packOptions(rawValue: 1 << 1)
    public static let PackWithUTF8StringEncoding   = packOptions(rawValue: 1 << 2)
    public static let PackIntegersAsUInt           = packOptions(rawValue: 1 << 3)
    public static let PackAllPossitiveIntAsUInt    = packOptions(rawValue: 1 << 4)
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

enum control_flow {
    case Continue
    case Break
    case None
}

public enum PackingError: ErrorType
{
    case dataEncodingError
    case packingError
}

public enum UnpackingError: ErrorType
{
    case cannotUnpackMap_bad_map_data
    case UnknownDataType_undifined_prefix
    case UnknownDataType_cannot_find_type_to_match_prefix
    case InvaildDataFormat
}

public enum DataTypes: Int {
    case Nil
    case fixstr
    case Bool
    case Str_8bit
    case Str_16bit
    case Str_32bit
    case fixInt,    fixNegativeInt
    case UInt8,     Int8
    case UInt16,    Int16
    case UInt32,    Int32
    case UInt64,    Int64
    case float32,   float64
    case bin8, bin16, bin32
    case fixarray, array16, array32
    case fixmap, map16, map32
    case remainingBytes
    
    func getDataPrefixSize() throws ->  Int {
        var shift = 0
        switch self {
        case .Nil:          shift = 0
        case .Bool:         shift = 0
        case .fixInt,
             .fixNegativeInt:    shift = 0
        case .fixstr,
             .fixarray,
             .fixmap:       shift = 1
        case .Str_8bit,
             .bin8:         shift = 2
        case .Str_16bit,
             .bin16,
             .array16,
             .map16:        shift = 3
        case .Str_32bit,
             .bin32,
             .array32,
             .map32:        shift = 5
        case .UInt8,
             .UInt16,
             .UInt32,
             .UInt64,
             .Int8,
             .Int16,
             .Int32,
             .Int64:        shift = 1
        default:
            print(self)
            print(self == .fixInt)
            throw UnpackingError.UnknownDataType_cannot_find_type_to_match_prefix
        }
        return shift
    }
}
