//
//  misc.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

public typealias ByteArray      = [UInt8]

#if swift(>=3)
public typealias ErrorType = ErrorProtocol
public typealias OptionSetType = OptionSet
public typealias SignedIntegerType = SignedInteger
public typealias UnsignedIntegerType = UnsignedInteger
public typealias FloatingPointType = FloatingPoint
public typealias dispatch_queue_priority_t = DispatchQoS
#endif

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
        
        #if swift(>=3)
            temp.remove(at: exception)
            temp.flip()
            temp.insert(ex, at: exception)
        #else
            temp.removeAtIndex(exception)
            temp.flip()
            temp.insert(ex, atIndex: exception)
        #endif
        
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
            return ByteArray(arrayLiteral:  UInt8((self >> 24)        ),
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
//    case cannotUnpackMap_bad_map_data
    case unknownDataTypeUndifinedPrefix
    case unknownDataTypeCannotFindTypeToMatchPrefix
    case unvaildDataFormat
    case invalidDataType
    case invaildDataFormat
}

public enum DataTypes: Int {
    case `nil`
    case fixstr
    case bool
    case str8bit
    case str16bit
    case str32bit
    case fixInt,    fixNegativeInt
    case uInt8,     int8
    case uInt16,    int16
    case uInt32,    int32
    case uInt64,    int64
    case float32,   float64
    case bin8, bin16, bin32
    case fixarray, array16, array32
    case fixmap, map16, map32
    case remainingBytes
    
    func getDataPrefixSize() throws ->  Int {
        var shift = 0
        switch self {
        case .`nil`:          shift = 0
        case .bool:         shift = 0
        case .fixInt,
             .fixNegativeInt:    shift = 0
        case .fixstr,
             .float32,
             .float64,
             .fixarray,
             .fixmap:       shift = 1
        case .str8bit,
             .bin8:         shift = 2
        case .str16bit,
             .bin16,
             .array16,
             .map16:        shift = 3
        case .str32bit,
             .bin32,
             .array32,
             .map32:        shift = 5
        case .uInt8,
             .uInt16,
             .uInt32,
             .uInt64,
             .int8,
             .int16,
             .int32,
             .int64:        shift = 1
        default:
            throw UnpackingError.unknownDataTypeCannotFindTypeToMatchPrefix
        }
        return shift
    }
}
