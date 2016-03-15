//
//  pack.swift
//  messagePack
//
//  Created by 悠二 on 11/3/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation

/**Pack items in the array by each's type and map into a single byte-array
 - Warning: DO NOT INCLUDE BOOL TYPE OR THE BOOL WILL PACK AS AN INT VALUE
 - parameter thingsToPack: an array of objects you want to pack
 - parameter withOptions packing options
 */
func packItems(things_to_pack: [AnyObject], withOptions options: packOptions = [.PackWithASCIIStringEncoding]) -> NSData {
    var byteArray = ByteArray()
    
    for item in things_to_pack
    {
//        print(item)
        pack_any_type(&byteArray, item: item, options: options)
    }
    return byteArray.dataValue()
}

private func pack_any_type<T>(inout byteArray: [UInt8], item: T?, options: packOptions = [.PackWithASCIIStringEncoding]) {
    switch item
    {
    case is String:
        let str = item as! String
        var encoding: NSStringEncoding = NSASCIIStringEncoding
        
        if options.rawValue & packOptions.PackWithASCIIStringEncoding.rawValue == 0 {
            if options.rawValue & packOptions.PackWithUTF8StringEncoding.rawValue != 0 {
                encoding = NSUTF8StringEncoding
            }
        }
        
        try! byteArray += str.pack(withEncoding: encoding)!.byteArrayValue()
        
    case is Int, is Int8, is Int16, is Int32, is Int64:
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
        byteArray += int.pack().byteArrayValue()
        
    case is UInt, is UInt8, is UInt16, is UInt32, is UInt64:
        let uint = item as! UInt64
        byteArray += uint.pack().byteArrayValue()
        
    case is Float32, is Float64:
        byteArray += (item as! Double).pack().byteArrayValue()
        
    case is NSData:
        byteArray += (item as! NSData).pack().byteArrayValue()
        
    case is [AnyObject]:
        byteArray += (item as! [AnyObject]).pack().byteArrayValue()
        
    case is NSDictionary:
        byteArray += (item as! NSDictionary).pack().byteArrayValue()
        
    case is Float32:
        byteArray += (item as! Float32).pack().byteArrayValue()
        
    case is Float64:
        byteArray += (item as! Float64).pack().byteArrayValue()
    
//    case is BooleanLiteralType:
//        byteArray += (item as! Bool).pack().byteArrayValue()
        
    case nil:
        byteArray += [0xc0]
        
    default: break
    }
}

private func size_after_pack_calculator<T>(item_to_switch: T) -> Int {
    var i = 0
    switch item_to_switch {
    case is String:
        let str = item_to_switch as! String
        try! i += str.pack(withEncoding: NSASCIIStringEncoding)!.byteArrayValue().count
        
    case is Int:
        let int = item_to_switch as! Int
    
        i += int.pack().byteArrayValue().count
        
    case is NSData:
        i += (item_to_switch as! NSData).byteArrayValue().count
    default: break
    }
    return i
}

//MARK: Bool

extension Bool {
    func pack() -> NSData {
        switch self {
        case true:  return [0xc3].dataValue()
        case false: return [0xc2].dataValue()
        }
    }
}

//MARK: String
extension StringLiteralType {
    func pack(withEncoding encoding: NSStringEncoding) throws -> NSData?
    {
        let data    = self.dataUsingEncoding(encoding)
        if data     == nil {throw PackingError.dataEncodingError}
        var mirror  = (data?.byteArrayValue())
        
        var prefix:     UInt8!
        var lengthByte: [UInt8] = []
        
        #if arch(arm) || arch(i386)
            switch data!.length {
            case (0b00000...0b11111) :   prefix = UInt8(0b101_00000 + data!.length)
            case (0b100000...0xFF)   :   prefix = 0xd9; lengthByte.append(UInt8(data!.length))
            case (0x100...0xFFFF)    :   prefix = 0xda; lengthByte  += [UInt8(data!.length / 0x100),
                                                                        UInt8(data!.length % 0x100)]
            default: throw PackingError.dataEncodingError
            }
        #else
            switch data!.length {
            case (0b00000...0b11111) :   prefix = UInt8(0b101_00000 + data!.length)
            case (0b100000...0xFF)   :   prefix = 0xd9; lengthByte.append(UInt8(data!.length))
            case (0x100...0xFFFF)    :   prefix = 0xda; lengthByte +=  [UInt8(data!.length / 0x100),
                                                                        UInt8(data!.length % 0x100)]
            case (0x10000...0xFFFFFFFF): prefix = 0xdb; lengthByte +=  [UInt8(data!.length / 0x10000),
                                                                        UInt8(data!.length % 0x10000 / 0x100),
                                                                        UInt8(data!.length % 0x10000 % 0x100)]
            default: throw PackingError.dataEncodingError
            }
        #endif
        
        if mirror != nil {mirror?.insert(prefix, atIndex: 0)}
        else {throw PackingError.packingError }
        for (index, lengthByte) in lengthByte.enumerate() {mirror?.insert(lengthByte, atIndex: 1 + index)}
        return NSData(bytes: mirror!, length: mirror!.count)
    }
}


//MARK: Integers
extension UnsignedIntegerType
{
    func pack() -> NSData
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
        data_mirror.insert(param.prefix, atIndex: 0)
        return data_mirror.dataValue()
    }
}


extension SignedIntegerType {
    func pack() -> NSData
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
            return NSData(bytes: &dummy, length: sizeof(Int8))
        }
        
        let data = NSData(bytes: &value, length: param.size)
        var data_mirror = data.byteArrayValue()
        data_mirror.flip()
        
        if !(0 <= value && value <= 0b01111111) {
            data_mirror.insert(param.prefix, atIndex: 0)
        }
        return data_mirror.dataValue()
    }
}

//MARK: Floating Point
extension FloatingPointType {
    func pack() -> NSData
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
        data_mirror.insert(param.prefix, atIndex: 0)
        return data_mirror.dataValue()
    }
}

//MARK: Binary

extension NSData {
    func pack() -> NSData
    {
        var prefix: UInt8!
        var temp = self.length.pack().byteArrayValue()
        
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
        temp += self.byte_array
        return temp.dataValue()
    }
}

//MARK: Dictionary/Map
extension NSDictionary
{
    func pack() -> NSData
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
            pack_any_type(&byteArray, item: key)
            pack_any_type(&byteArray, item: value)
        }
        return byteArray.dataValue()
    }
    
    private var byteArray_length: size_t {
        var i = 0
        for (key, value) in self {
            i += size_after_pack_calculator(key)
            i += size_after_pack_calculator(value)
        }
        return i
    }
}

extension Dictionary
{
    func pack() -> NSData
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
            switch key {
            case is String:
                let str = value as! String
                try! byteArray += str.pack(withEncoding: NSASCIIStringEncoding)!.byteArrayValue()
                
            case is Int:
                let int = value as! Int
                byteArray += int.pack().byteArrayValue()
                
            case is NSData:
                byteArray += (value as! NSData).byteArrayValue()
                
            default: break
            }
        }
        return byteArray.dataValue()
    }
}


//MARK: Array
extension NSArray
{
    func pack() -> NSData
    {
        var byteArray = ByteArray()
//        print(self.count)
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                print(self.count._16_bit_array)
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
            pack_any_type(&byteArray, item: value)
        }
        return byteArray.dataValue()
    }
    
    
    private var byteArray_length: size_t {
        var i = 0
        for item in self {
            i += size_after_pack_calculator(item)
        }
        return i
    }
}

extension Array
{
    func pack() -> NSData
    {
        var byteArray = ByteArray()
        
        #if arch(arm) || arch(i386)
            switch self.count {
            case 0...15:
                byteArray.append(UInt8(0b10010000 | self.count))
            case 16...0xffff:
                byteArray.append(0xdc)
                p
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
            pack_any_type(&byteArray, item: value)
        }
        return byteArray.dataValue()
    }
    
    private var byteArray_length: size_t {
        var i = 0
        for item in self {
            i += size_after_pack_calculator(item)
        }
        return i
    }
}