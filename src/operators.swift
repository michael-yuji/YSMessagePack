//
//  operators.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

infix operator +^ {}
infix operator +^= {}

public func +^ (lhs: NSMutableData, rhs: NSMutableData)-> NSMutableData {
    let x = (lhs.copy() as! NSMutableData)
    x.appendBytes(rhs.bytes, length: rhs.length)
    return x
}

public func +^= (lhs: NSMutableData, rhs: NSMutableData) {
    lhs.appendBytes(rhs.bytes, length: rhs.length)
}

public func +^ (inout lhs: NSData, rhs: NSData) -> NSData {
    let temp = (lhs.mutableCopy() as! NSMutableData)
    temp.appendBytes(rhs.bytes, length: rhs.length)
    return temp
}

public func +^= (inout lhs: NSData, rhs: NSData) {
    let temp = (lhs.mutableCopy() as! NSMutableData)
    temp.appendBytes(rhs.bytes, length: rhs.length)
    lhs = temp
}