//
//  errors.swift
//  messagePack
//
//  Created by 悠二 on 11/3/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation

struct unpackOptions: OptionSetType {
    var rawValue: UInt8
    static let keepRemainingBytes = unpackOptions(rawValue: 1 << 1)
}

struct packOptions: OptionSetType {
    var rawValue: UInt8
    static let PackWithASCIIStringEncoding  = packOptions(rawValue: 1 << 1)
    static let PackWithUTF8StringEncoding   = packOptions(rawValue: 1 << 2)
    static let PackIntegersAsUInt           = packOptions(rawValue: 1 << 3)
    static let PackAllPossitiveIntAsUInt    = packOptions(rawValue: 1 << 4)
}

enum control_flow {
    case Continue
    case Break
    case None
}

enum PackingError: ErrorType
{
    case dataEncodingError
    case packingError
}

enum UnpackingError: ErrorType
{
    case cannotUnpackMap_bad_map_data
    case UnknownDataType_undifined_prefix
    case UnknownDataType_cannot_find_type_to_match_prefix
    case InvaildDataFormat
}

public enum DataType: Int {
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
        case .fixstr:       shift = 1
        case .Str_8bit,
        .bin8:         shift = 2
        case .Str_16bit,
        .bin16:        shift = 3
        case .Str_32bit,
        .bin32:        shift = 5
        case .UInt8,
        .UInt16,
        .UInt32,
        .UInt64,
        .Int8,
        .Int16,
        .Int32,
        .Int64:        shift = 1
        default:
            throw UnpackingError.UnknownDataType_cannot_find_type_to_match_prefix
        }
        return shift
    }
}