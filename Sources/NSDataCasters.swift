//
//  NSDataCasters.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

#if swift(>=3)
    public extension Array {
        public init(count: Int, repeatedValue: Element) {
            self.init(repeating: repeatedValue, count: count)
        }
    }
#endif

public extension NSData {
    
    ///Return the byte array of self
    func byteArrayValue() -> ByteArray {
        //buffer
        var byte_array: ByteArray = ByteArray(count: self.length, repeatedValue: 0)
        
        //getBytes and put it into the buffer
        self.getBytes(&byte_array, length: self.length)
        return byte_array
    }
    
    ///Get the byte array of self
    var byteArray: [UInt8] {
        var byte_array: [UInt8] = [UInt8](count: self.length, repeatedValue: 0)
        //getBytes and put it into the buffer
        self.getBytes(&byte_array, length: self.length)
        return byte_array
    }
    
    ///Cast data into Int value according to its byte_array value
    var castToInt: Int {
        var int_value: Int = 0
        self.getBytes(&int_value, length: MemoryLayout<Int>.size)
        
        return int_value
    }
    
    var castToUInt: Int {
        var int_value: Int = 0
        self.getBytes(&int_value, length: MemoryLayout<Int>.size)
        return int_value
    }
    
    ///Cast data into Int8 value according to its byte_array value
    var castToInt8: Int8 {
        var int_value: Int8 = 0
        self.getBytes(&int_value, length: MemoryLayout<Int8>.size)
        return int_value
    }
    
    ///Cast data into Double value according to its byte_array value
    var castToDouble: Double {
        var double_value: Double = 0
        self.getBytes(&double_value, length: MemoryLayout<Double>.size)
        return double_value
    }
    
    ///Cast data into Double value according to its byte_array value
    var castTFloat: Float {
        var double_value: Float = 0
        self.getBytes(&double_value, length: MemoryLayout<Float>.size)
        return double_value
    }
    
    /**
     Cast Data into String/NSString according to its byte_array value
     - Parameter withEncoding: encoding to use, default is `ascii`
     */
    @inline(__always)
    func castToString(withEncoding encoding: String.Encoding = .ascii) -> String? {
        return String(data: Data(bytes: self.byteArray), encoding: encoding)
    }
    
    ///Cast data into NSArray according to its byte_array value
    var castToArray: [NSData]? {
        let array = NSKeyedUnarchiver.unarchiveObject(with: Data(bytes: self.byteArray)) as? NSArray
        return (array == nil) ? nil : array! as? [NSData]
    }
    
    @inline(__always)
    func castToStringArray(withEncoding encoding: String.Encoding = .ascii) -> [String?] {
        return self.castToArray!.map({($0).castToString(withEncoding: encoding)})
    }
    
    ///Cast data into NSDictionary according to its byte_array value
    var castToDictionary: NSDictionary? {
        return NSKeyedUnarchiver.unarchiveObject(with: Data(bytes: self.byteArray)) as? NSDictionary
    }

    var castToBool: Bool? {
        return self.bytes.assumingMemoryBound(to: Bool.self).pointee
    }
    
    @inline(__always)
    func mapUnpackedArray<T>(handler: (NSData) throws -> T) -> [T]{
        return try! self.castToArray!.map(handler)
    }
    
    public var castToUInt64: UInt64 {
        var int_value: UInt64 = 0
        self.getBytes(&int_value, length: MemoryLayout<UInt64>.size)
        return int_value
    }
    
}
