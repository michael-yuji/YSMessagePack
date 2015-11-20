//
//  NSDataHelper.swift
//  messagePack
//
//  Created by 悠二 on 11/3/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation

import Foundation

extension NSData {
    
    ///Return the byte array of self
    func byteArrayValue() -> ByteArray {
        //buffer
        var byte_array: ByteArray = ByteArray(count: self.length, repeatedValue: 0)
        //getBytes and put it into the buffer
        self.getBytes(&byte_array, length: self.length)
        return byte_array
    }
    
    ///Get the byte array of self
    var byte_array: [UInt8] {
        var byte_array: [UInt8] = [UInt8](count: self.length, repeatedValue: 0)
        //getBytes and put it into the buffer
        self.getBytes(&byte_array, length: self.length)
        return byte_array
    }
    
    ///Cast data into Int value according to its byte_array value
    var castToInt: Int {
        var int_value: Int = 0
        self.getBytes(&int_value, length: sizeof(Int))
        return int_value
    }
    
    ///Cast data into Int8 value according to its byte_array value
    var castToInt8: Int8 {
        var int_value: Int8 = 0
        self.getBytes(&int_value, length: sizeof(Int8))
        return int_value
    }
    
    ///Cast data into Double value according to its byte_array value
    var castToDouble: Double {
        var double_value: Double = 0
        self.getBytes(&double_value, length: sizeof(Double))
        return double_value
    }
    
    ///Cast data into Double value according to its byte_array value
    var castTFloat: Float {
        var double_value: Float = 0
        self.getBytes(&double_value, length: sizeof(Float))
        return double_value
    }
    
    /**
     Cast Data into String/NSString according to its byte_array value
     - Parameter withEncoding: encoding to use, default is `NSASCIIStringEncoding`
     */
    func castToString(withEncoding encoding: NSStringEncoding = NSASCIIStringEncoding) -> String? {
        return NSString(data: self, encoding: encoding) as String?
    }
    
    ///Cast data into NSArray according to its byte_array value
    var castToArray: NSArray? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(self) as? NSArray
    }
    
    ///Cast data into NSDictionary according to its byte_array value
    var castToDictionary: NSDictionary? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(self) as? NSDictionary
    }
    
    /**Joint two data into one by adding another data to the tail of the first's ([data][with])
     - Parameter data: data will be placed at first after joint
     - Parameter with: data will be put at the end after joint
     */
    static func joint(data: NSData, with otherData: NSData) -> NSData {
        var temp_data0 = [UInt8](count: data.length, repeatedValue: 0)
        var temp_data1 = [UInt8](count: otherData.length, repeatedValue: 0)
        data.getBytes(&temp_data0, length: data.length)
        otherData.getBytes(&temp_data1, length: otherData.length)
        return (temp_data0 + temp_data1).dataValue()
    }
}