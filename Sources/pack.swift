//
//  pack.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

public enum MsgPackTypes {
    case Bool, Uint, Int, Float, String, Array, Dictionary, Data, Custom, Nil
}
public protocol Packable {
    func packFormat() -> [Packable]
    func msgtype() -> MsgPackTypes
}

public class Nil : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    public func msgtype() -> MsgPackTypes {
        return .Nil
    }
}

/**Pack items in the array by each's type and map into a single byte-array
 - Warning: USE MASK(YOUR_ITEM) if $YOUR_ITEM is Bool, Uint64/32/16/8, Int64/32/16/8 or your custom structs / classes
 - parameter thingsToPack: an array of objects you want to pack
 - parameter withOptions packing options
 */

public func pack(items: [Packable?], withOptions options: packOptions = [.PackWithASCIIStringEncoding]) -> NSData
{
    var byteArray = ByteArray()
    
    for item in items
    {
        pack(item: item, appendToBytes: &byteArray, withOptions: options)
    }

    return byteArray.dataValue()
}



private func pack(item: Packable?, appendToBytes byteArray: inout [UInt8], withOptions options: packOptions = [.PackWithASCIIStringEncoding])
{
    if item == nil {
        byteArray += [0xc0]
        return
    }
    
    switch item!.msgtype()
    {
        
    case .Custom:
        for i in item!.packFormat() {
            pack(item: i, appendToBytes: &byteArray)
        }
        
    case .String:
        let str = item as! String

        var encoding: String.Encoding = .ascii
        if options.rawValue & packOptions.PackWithASCIIStringEncoding.rawValue == 0 {
            if options.rawValue & packOptions.PackWithUTF8StringEncoding.rawValue != 0 {

                encoding = .utf8
            }
        }
        
        try! byteArray += str.pack(withEncoding: encoding)!.byteArrayValue()
        
    case .Int:
        var int = item as! Int
        if options.rawValue & packOptions.PackAllPossitiveIntAsUInt.rawValue != 0 || options.rawValue & packOptions.PackIntegersAsUInt.rawValue != 0 {
            if int >= 0 {
                fallthrough
            } else {
                if options.rawValue & packOptions.PackIntegersAsUInt.rawValue != 0 {
                    int = 0
                }
            }
        }
        byteArray += int.packed().byteArrayValue()
        
    case .Uint:
        let uint = item as! UInt64
        byteArray += uint.packed().byteArrayValue()
        
    case .Float:
        byteArray += (item as! Double).packed().byteArrayValue()
        
    case .Bool:
        byteArray += (item as! Bool).packed().byteArrayValue()
        
    case .Data:
        byteArray += (item as! NSData).packed().byteArrayValue()
        
    case .Array:
        byteArray += (item as! [AnyObject]).packed().byteArrayValue()
        
    case .Dictionary:
        byteArray += (item as! NSDictionary).packed().byteArrayValue()

    case .Nil:
        byteArray += [0xc0]
    }
}


private func calculateSizeAfterPack<T>(forItem item: T) -> Int {
    var i = 0
    switch item {
    case is String:
        let str = item as! String
        #if swift(>=3)
            try! i += str.pack(withEncoding: .ascii)!.byteArray.count
        #else
            try! i += str.pack(withEncoding: NSASCIIStringEncoding)!.byteArrayValue().count
        #endif
    case is Int:
        let int = item as! Int
        i += int.packed().byteArrayValue().count
        
    case is NSData:
        i += (item as! NSData).byteArrayValue().count
    default: break
    }
    return i
}

//MARK: Bool

extension Bool : Packable {
    public func packed() -> NSData {
        switch self {
        case true:  return [0xc3].dataValue()
        case false: return [0xc2].dataValue()
        }
    }
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Bool
    }
}

//MARK: String
extension StringLiteralType : Packable {
    
    func pack(withEncoding encoding: String.Encoding) throws -> NSData?
    {
        let data = self.data(using: encoding)
        
        if let data = data {
            var mirror  = [UInt8](repeatElement(0, count: data.count))
            data.copyBytes(to: &mirror, count: data.count)
            
            var prefix: UInt8!
            var lengthByte: [UInt8] = []
            
            #if arch(arm) || arch(i386)
                switch data.length {
                case (0b00000...0b11111) :   prefix = UInt8(0b101_00000 + data.length)
                case (0b100000...0xFF)   :   prefix = 0xd9; lengthByte.append(UInt8(data.length))
                case (0x100...0xFFFF)    :   prefix = 0xda; lengthByte  += [UInt8(data.length / 0x100),
                                                                            UInt8(data.length % 0x100)]
                default: throw PackingError.dataEncodingError
                }
            #else
                switch data.count {
                case (0b00000...0b11111) :   prefix = UInt8(0b101_00000 + data.count)
                case (0b100000...0xFF)   :   prefix = 0xd9; lengthByte.append(UInt8(data.count))
                case (0x100...0xFFFF)    :   prefix = 0xda; lengthByte +=  [UInt8(data.count / 0x100),
                                                                            UInt8(data.count % 0x100)]
                case (0x10000...0xFFFFFFFF):
                    prefix = 0xdb
                    let buf = [UInt8(data.count / 0x10000), UInt8(data.count % 0x10000 / 0x100), UInt8(data.count % 0x10000 % 0x100)]
                    lengthByte +=  buf
                default: throw PackingError.dataEncodingError
                }
            #endif
            mirror.insert(prefix, at: 0)
            return NSData(bytes: mirror, length: mirror.count)
        } else {
            throw PackingError.dataEncodingError
        }
    }
   
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .String
    }
}


//MARK: Integers
public extension UnsignedIntegerType
{
    public func packed() -> NSData
    {
        var value  = self
        var param: (prefix: UInt8, size: size_t)!
        switch self {
        case (0..<0xFF),0xff:                                                param = (0xcc, 1);
        case (0x100..<0xFFFF),0xFFFF:                                        param = (0xcd, 2);
        case (0x10000..<0xFFFFFFFF),0xFFFFFFFF:                              param = (0xce, 4);
        case (0x100000000 ..< 0xFFFFFFFFFFFFFFFF),0xFFFFFFFFFFFFFFFF:        param = (0xcf, 8);
            
        default: break
        }
        
        let data = NSData(bytes: &value, length: param.size)
        
        var data_mirror = data.byteArrayValue()
        data_mirror.flip()
        #if swift(>=3)
            data_mirror.insert(param.prefix, at: 0)
        #else
            data_mirror.insert(param.prefix, atIndex: 0)
        #endif
        return data_mirror.dataValue()
    }
    
    
    public func packFormat() -> [Packable] {
        return []
    }
}


public extension SignedIntegerType {
    public func packed() -> NSData
    {
    
        var value  = self
        var param: (prefix: UInt8, size: size_t)!
        
        switch self {
        case (0..<0x7F), 0x7F,
             (-0x7F...0):                           param = (0xd0, 1);
        case (0x0..<0x7FFF), 0x7FFF,
             (-0x7FFF...0):                         param = (0xd1, 2);
        case (0..<0x7FFFFFFF), 0x7FFFFFFF,
             (-0x7FFFFFFF...0):                     param = (0xd2, 4);
        case (0x0 ..< 0x7FFFFFFFFFFFFFFF),
             (0x7FFFFFFFFFFFFFFF),
             (-0x7FFFFFFFFFFFFFFF ... 0):           param = (0xd3, 8);
        default: break
        }
        
        if (value < 0 && value >= -1 * 0b0001_1111) {
            var dummy = abs(value)
            dummy = dummy | 0b1110_0000
            return NSData(bytes: &dummy, length: MemoryLayout<Int8>.size)
        }
        
        let data = NSData(bytes: &value, length: param.size)
        var data_mirror = data.byteArrayValue()
        data_mirror.flip()
        
        if !(0 <= value && value <= 0b01111111) {
            #if swift(>=3)
                data_mirror.insert(param.prefix, at: 0)
            #else
                data_mirror.insert(param.prefix, atIndex: 0)
            #endif
        }
        return data_mirror.dataValue()
    }
}

//MARK: Floating Point
extension FloatingPointType {
    public func packed() -> NSData
    {
        var value = self
        var param: (prefix: UInt8, size: size_t)!
        switch self {
        case is Float32:    param = (0xca, 4)
        case is Float64:    param = (0xcb, 8)
        default: break
        }
        let data = NSMutableData(bytes: &value, length: param.size)
        var data_mirror = data.byteArrayValue()
        data_mirror.flip()
        #if swift(>=3)
            data_mirror.insert(param.prefix, at: 0)
        #else
            data_mirror.insert(param.prefix, atIndex: 0)
        #endif
        return data_mirror.dataValue()
    }
}

extension Double : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Float
    }
}

extension Float : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Float
    }
}

extension Int : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    public func msgtype() -> MsgPackTypes {
        return .Int
    }
}

extension Int8 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Int
    }
}


extension Int16 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Int
    }
}

extension Int32 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Int
    }
}


extension Int64 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Int
    }
}

extension UInt : Packable {
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Uint
    }
}

extension UInt8 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Uint
    }
}


extension UInt16 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Uint
    }
}

extension UInt32 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    public func msgtype() -> MsgPackTypes {
        return .Uint
    }
}


extension UInt64 : Packable {
    public func packFormat() -> [Packable] {
        return []
    }
    public func msgtype() -> MsgPackTypes {
        return .Uint
    }
}


//MARK: Binary

public extension NSData {
    public func packed() -> NSData
    {
        var prefix: UInt8!
        var temp = self.length.packed().byteArrayValue()
        
        #if arch(arm) || arch(i386)
            switch self.length {
            case (0..<0xFF), 0xff:                                          prefix = (0xc4);
            case (0x100..<0xFFFF), 0xffff:                                  prefix = (0xc5);
            default: break
            }
        #else
            switch self.length {
            case (0..<0xFF), 0xff:                                          prefix = (0xc4);
            case (0x100..<0xFFFF), 0xffff:                                  prefix = (0xc5);
            case (0x10000..<0xFFFFFFFF), 0xffffffff:                        prefix = (0xc6);
            default: break
            }
        #endif
        temp[0] = prefix
        temp += self.byteArray
        return temp.dataValue()
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Data
    }
}

//MARK: Dictionary/Map
extension NSDictionary : Packable
{
    public func packed() -> NSData
    {
        var byteArray = ByteArray()
        
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b1000_0000 | self.count))
            case 16...0xffff:
                byteArray.append(0xde)
                byteArray += self.count._16_bit_array
            default:            break
            }
        #else
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b1000_0000 | self.count))
            case 16...0xffff:
                byteArray.append(0xde)
                byteArray += self.count._16_bit_array
            case 0x10000...0xffffffff:
                byteArray.append(0xdf)
                byteArray += self.count._32_bit_array
            default:            break
            }
        #endif
        
        for (key, value) in self {
            pack(item: key as? Packable, appendToBytes: &byteArray)
            pack(item: value as? Packable, appendToBytes: &byteArray)
        }
        return byteArray.dataValue()
    }
    
    private var byteArray_length: size_t {
        var i = 0
        for (key, value) in self {
            i += calculateSizeAfterPack(forItem: key)
            i += calculateSizeAfterPack(forItem: value)
        }
        return i
    }
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Dictionary
    }
}

extension Dictionary : Packable
{
    public func packed() -> NSData
    {
        var byteArray = ByteArray()
        
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b1000_0000 | self.count))
            case 16...0xffff:
                byteArray.append(0xde)
                byteArray += self.count._16_bit_array
            default:            break
            }
        #else
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b1000_0000 | self.count))
            case 16...0xffff:
                byteArray.append(0xde)
                byteArray += self.count._16_bit_array
            case 0x10000...0xffffffff:
                byteArray.append(0xdf)
                byteArray += self.count._32_bit_array
            default:            break
            }
        #endif
        
        for (key, value) in self {
            pack(item: key as? Packable, appendToBytes: &byteArray)
            //            pack(&byteArray, item: value as? Packable)
            pack(item: value as? Packable, appendToBytes: &byteArray)
        }

        return byteArray.dataValue()
    }
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Dictionary
    }
}


//MARK: Array
extension NSArray : Packable
{
    public func packed() -> NSData
    {
        var byteArray = ByteArray()
        
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                byteArray += self.count._16_bit_array
            default: break
            }
        #else
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                byteArray += self.count._16_bit_array
            case 0x10000...0xffffffff:
                byteArray.append(0xdd)
                byteArray += self.count._32_bit_array
            default: break
            }
        #endif
        
        for value in self {
            pack(item: value as? Packable, appendToBytes: &byteArray)
        }
        return byteArray.dataValue()
    }
    
    private var byteArray_length: size_t {
        var i = 0
        for item in self {
            i += calculateSizeAfterPack(forItem: item)
        }
        return i
    }
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Array
    }
}

extension Array : Packable
{
    public func packed() -> NSData
    {
        var byteArray = ByteArray()
        
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                byteArray += self.count._16_bit_array
            default: break
            }
        #else
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                byteArray += self.count._16_bit_array
            case 0x10000...0xffffffff:
                byteArray.append(0xdd)
                byteArray += self.count._32_bit_array
            default: break
            }
        #endif
        
        for value in self {
            pack(item: value as? Packable, appendToBytes: &byteArray)
        }
        return byteArray.dataValue()
    }
    
    private var byteArray_length: size_t {
        var i = 0
        for item in self {
            i += calculateSizeAfterPack(forItem: item)
        }
        return i
    }
    
    public func packFormat() -> [Packable] {
        return []
    }
    
    public func msgtype() -> MsgPackTypes {
        return .Array
    }
}
