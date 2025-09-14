//
//  BlockType.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/4/1.
//  Copyright © 2019 Gogolook. All rights reserved.
//

/// this enumeration denotes all possible values for the field `type` of a blocked entry.
/// Note that iOS supports ONLY `phone`, which denotes to block a specific phone number.
/// However, iOS clients should keep all entries coming from both platforms for sync the numbers
/// back to server without lossing any of them.
///
/// - `default`: Android only
/// - dummy_history: Android only
/// - dummy_section: Android only
/// - dummy_exception: Android only
/// - phone: the only type that iOS supports.
/// - beginning: Android only
/// - keyword: Android only
/// - unknown: Android only
/// - international: Android only
/// - notContact: Android only
/// - smartBlock: Android only
/// - krDisclaimer: Android only
/// - telecom: Android only
/// - bank: Android only
/// - otherDD: Android only
/// - divider: Android only
/// - krDisclaimer2: Android only
enum BlockType: Int {
    case `default` = 0

    case dummy_history = -1
    case dummy_section = -2
    case dummy_exception = -3

    case phone = 1
    case beginning = 2
    case keyword = 3
    case unknown = 4
    case international = 5
    case notContact = 7
    case smartBlock = 8

    // NOTE: When I was defining this enumeration by reading Whoscall android source code,
    // there was an definition of `SIZE_BLOCKTYPE` in the source code
    /*
    this size represent the max acceptable value that should be save in db
    int SIZE_BLOCKTYPE = BLOCKTYPE_SMART_BLOCK;*/

    case krDisclaimer = 9
    case telecom = 11
    case bank = 12
    case otherDD = 13
    case divider = 14
    case krDisclaimer2 = 15
}
