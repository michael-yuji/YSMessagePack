//
//  parse.swift
//  MessagePack2.0
//
//  Created by yuuji on 4/3/16.
//  Copyright © 2016 yuuji. All rights reserved.
//

import Foundation

private func parsePackedArray(bytes: ByteArray, atIndex index: Int, count: Int) -> size_t {
    var bytes = bytes
    bytes.removeFirst(index)
    var length: size_t = 0
    try! parseData(messagePackedBytes: bytes, specific_amount: count, dataLengthOutput: &length)
    return length
}

private func parsePackedMap(bytes: ByteArray, atIndex index: Int, count: Int) -> size_t
{
    var bytes = bytes
    bytes.removeFirst(index)
    var length: size_t = 0
    try! parseData(messagePackedBytes: bytes, specific_amount: count * 2, dataLengthOutput: &length)
    return length
}

func parseData(messagePackedBytes byte_array: ByteArray, specific_amount amount: Int? = nil, inout dataLengthOutput len: Int) throws -> [(Range<Int>, DataTypes)]
{
    var itemMarks             = [(Range<Int>, DataTypes)]()
    var i: Int                =     0
    let _singleByteSize       =     1
    let _8bitDataSize         =     1
    let _16bitDataSize        =     2
    let _32bitDataSize        =     4
    let _64bitDataSize        =     8
    
    
    while (i < byte_array.count)
    {
        var shift: size_t!, dataSize: size_t!
        var type: DataTypes = .fixstr
        
        let _fixStrDataMarkupSize    =  size_t(byte_array[i] ^ 0b101_00000)/sizeof(UInt8)
        let _fixArrayDataCount       =  size_t(byte_array[i] ^ 0b1001_0000)/sizeof(UInt8)
        let _fixMapCount             =  size_t(byte_array[i] ^ 0b1000_0000)/sizeof(UInt8)
        
        
        let _8bitMarkupDataSize      =  byte_array.count - (i+1) >= 1 ?
            size_t(byte_array[i + 1])  : 0// (i + 1) : the next byte of prefix byte, which is the size byte
        
        let _16bitMarkupDataSize     =  byte_array.count - (i+2) >= 2 ?
            byte_array[i+1]._16bitValue(jointWith: byte_array[i+2]) : 0
        
        let _32bitMarkupDataSize     =  byte_array.count - (i+3) >= 3 ?
            byte_array[i+1]._32bitValue(joinWith: byte_array[i+2],
                                        and: byte_array[i+3])       : 0
        
        switch byte_array[i] {
            
        //Nil
        case 0xc0:
            type = .Nil
            dataSize = _singleByteSize
        case 0xc2:
            type = .Bool
            dataSize = _singleByteSize
            
        case 0xc3:
            type = .Bool
            dataSize = _singleByteSize
            
        //bool
        case 0xc2, 0xc3:
            type = .Bool            ;    dataSize = _singleByteSize
            
        //bin
        case 0xc4:  type = .bin8    ;    dataSize = _8bitMarkupDataSize
        case 0xc5:  type = .bin16   ;    dataSize = _16bitMarkupDataSize
        case 0xc6:  type = .bin32   ;    dataSize = _32bitMarkupDataSize
            
        //float
        case 0xca:  type = .float32 ;    dataSize = _32bitDataSize
        case 0xcb:  type = .float64 ;    dataSize = _64bitDataSize
            
        //uint
        case 0xcc:  type = .UInt8   ;    dataSize = _8bitDataSize
        case 0xcd:  type = .UInt16  ;    dataSize = _16bitDataSize
        case 0xce:  type = .UInt32  ;    dataSize = _32bitDataSize
        case 0xcf:  type = .UInt64  ;    dataSize = _64bitDataSize
            
            //int
            
        case 0...0b01111111:
            type = .fixInt          ;    dataSize = _singleByteSize
        case 0b11100000..<0b11111111:
            type = .fixNegativeInt  ;    dataSize = _singleByteSize
        case 0xd0:  type = .Int8    ;    dataSize = _8bitDataSize
        case 0xd1:  type = .Int16   ;    dataSize = _16bitDataSize
        case 0xd2:  type = .Int32   ;    dataSize = _32bitDataSize
        case 0xd3:  type = .Int64   ;    dataSize = _64bitDataSize
            
            
        //String
        case 0b101_00000...0b101_11111:
            type = .fixstr  ;    dataSize = _fixStrDataMarkupSize
        case 0xd9:  type = .Str_8bit;    dataSize = _8bitMarkupDataSize
        case 0xda:  type = .Str_16bit;   dataSize = _16bitMarkupDataSize
        case 0xdb:  type = .Str_32bit;   dataSize = _32bitMarkupDataSize
            
        //array
        case 0b10010000...0b10011111:
            let count                  = _fixArrayDataCount
            dataSize = parsePackedArray(byte_array, atIndex: i + 1, count: count)
            type = .fixarray
            
        case 0xdc:
            let count                   = _16bitMarkupDataSize
            dataSize = parsePackedArray(byte_array, atIndex: i + 1 + 2, count: count)
            type = .array16
            
            
        case 0xdd:
            let count                   = _32bitMarkupDataSize
            dataSize = parsePackedArray(byte_array, atIndex: i + 1 + 4, count: count)
            type = .array32
            
        //map
        case 0b10000000...0b10001111:
            let count                   = _fixMapCount
            dataSize = parsePackedMap(byte_array, atIndex: i + 1, count: count)
            type = .fixmap
            
        case 0xde:
            let count                   = _16bitMarkupDataSize
            dataSize = parsePackedMap(byte_array, atIndex: i + 1 + 2, count: count)
            type = .map16
            
        case 0xdf:
            let count                   = _32bitMarkupDataSize
            dataSize = parsePackedMap(byte_array, atIndex: i + 1 + 4, count: count)
            type = .map32
            
        default: throw UnpackingError.UnknownDataType_undifined_prefix
        }
        
        shift = try type.getDataPrefixSize()
        
//        let rawDataRange = Range<Int>(start: i , end:i + shift + dataSize)
        let rawDataRange = Range<Int>(i..<i+shift+dataSize)
        itemMarks.append((rawDataRange, type))
        
        i += dataSize + shift
        
        //when `packedObject` stored enough values or entered an infinity loop because of bad data, break
        if (amount != nil && itemMarks.count == amount) || (dataSize + shift) == 0 {
            if (dataSize + shift == 0) {
                throw UnpackingError.InvaildDataFormat
            }
            break
        }
    }
    
    len = i
    return itemMarks
}
