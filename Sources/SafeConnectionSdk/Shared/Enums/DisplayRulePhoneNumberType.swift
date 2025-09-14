//
//  DisplayRulePhoneNumberType.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/6/26.
//  Copyright © 2019 Gogolook. All rights reserved.
//

// swiftlint:disable line_length
/// This enumeration is defined for dealing with
/// * [Whoscall 3.0 display rule](https://docs.google.com/spreadsheets/d/1BKIBEUT-WdndxaEnj6Zw112yVFRkpwMRCNJlIok_Seo/edit#gid=1008455171)
/// * [Caller ID display rule](https://docs.google.com/spreadsheets/d/1BKIBEUT-WdndxaEnj6Zw112yVFRkpwMRCNJlIok_Seo/edit#gid=1617618233)
/// * [Num search API](http://apidocs.whoscall.com/swagger/index.html?url=http://apidocs.whoscall.com/specs/phonenumberapi/number_search.yaml#/Number%20Search/get_search_v9__region___number_)
///
/// For caller id display rule
/// `spam`: ⚠️ before the number's label
/// `whoscallNumber`: ✅ before the number's label
/// the other types of numbers shows only their own correspoding label.
///
/// For API result
/// set a number to `spam` if the number is marked as spam, or map to a suitable type.
/// NOTE THAT: the service whoscall number is available ONLY in TW. Caller id shows a green check mark before a label if the number is of type `whoscallNumber` (a supplement from Henry)
///
/// - cs: for cs purpose
/// - spam: spam.
/// - whoscallCard: whoscall card
/// - whoscallNumber: whoscall card and the number is a TW phone number.
/// - masses: masses (regular number)
/// - SPF: Singapore Police Force

enum DisplayRulePhoneNumberType: Int, CaseIterable {
    case cs = 0
    case spam = 1
    case whoscallCard = 2
    case whoscallNumber = 3
    case masses = 4
    case noInfo = 5
    case singaporePoliceForce = 6
}
// swiftlint:enable line_length
