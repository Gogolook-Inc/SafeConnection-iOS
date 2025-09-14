//
//  Delta.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/5/14.
//  Copyright © 2019 Gogolook. All rights reserved.
//

/// A delta denotes the action requires to be applied to a identification or blocking entry so that
/// the entries in a call dir extension will be as same as the entries in the DB.
///
/// - noAction: do nothing
/// - add: add the entry
/// - remove: remove the entry
/// - updateLabel: update the label/name of the entry
enum Delta: Int32 {
    case noAction = 0b00
    case add = 0b01
    case remove = 0b10
    case updateLabel = 0b11
}
