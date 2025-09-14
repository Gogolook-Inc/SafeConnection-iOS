//
//  WCNumberObject+Convert.swift
//  Merli
//
//  Created by Henry Tseng on 2019/6/24.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import Foundation

typealias WebResult = WCNumberObject.WebResult
typealias ContactInfo = WCNumberObject.ContactInfo
typealias NumberObject = WCNumberObject

protocol NumberObjectConvertible {
    var geocoding: String { get }
    var name: String { get }
    var telecom: String { get }
    var type: String { get }
    var spam: String { get }
    var bizcate: String { get }
    var warning: Int { get }
    var address: String { get }
    var webresults: [WebResult] { get }
    var lnglat: [Double] { get }
    var contactInfo: [ContactInfo] { get }
    var nameCandidates: [String] { get }
    var profileImageUrl: URL? { get }
    var descr: String { get }
}

extension WCNumberObject: NumberObjectConvertible {
    /// Get url of profile image of `Whoscall Number`
    var profileImageUrl: URL? {
        var prefix: String!

        // NOTE: This rule only support profile images of whoscall number
        // Begin to combine url path of profile image for Whoscall Number *ONLY*
        if let p = images.meta.p {
            prefix = p
        } else {
            prefix = "https://s3-ap-northeast-1.amazonaws.com/whoscallcard-image-resize"
        }
        guard var url = URL(string: prefix) else {
            assertionFailure("Non-support url prefix")
            return nil
        }
        guard let meta = images.meta.r0 else {
            return nil
        }

        guard let filenames = images.profile.r0, !filenames.isEmpty else {
            return nil
        }
        let filename: String = filenames.first(where: { $0.contains("_l") }) ?? filenames.last!
        url.appendPathComponent(meta)
        // End to combine url path of profile image for Whoscall Number

        url.appendPathComponent("profile")
        url.appendPathComponent(filename)
        return url
    }
}

extension PhoneNumberInfo {
    enum ConvertError: Error {
        case invalidNumber
    }

    convenience init(number: String, region: String, numberObject: NumberObjectConvertible) throws {
        self.init()
        let cleanedUpText = number.removePhoneNumberSignCharacters()
        guard let e164 = Int64(cleanedUpText) else {
            throw ConvertError.invalidNumber
        }
        self.e164 = e164
        self.regionCode = region
        self.label = numberObject.name
        self.geocoding = numberObject.geocoding.isEmpty ? nil : numberObject.geocoding
        self.telecom = numberObject.telecom.isEmpty ? nil : numberObject.telecom
        switch numberObject.type {
        case "MASSES", "V1", "V2": // V1, V2 has been deprecated, falls back to "hasInfo" metaphor
            if !numberObject.spam.isEmpty {
                self.type = DisplayRulePhoneNumberType.spam.rawValue
            } else {
                self.type = DisplayRulePhoneNumberType.masses.rawValue
            }
        case "CS":
            if !numberObject.spam.isEmpty {
                self.type = DisplayRulePhoneNumberType.spam.rawValue
            } else {
                self.type = DisplayRulePhoneNumberType.cs.rawValue
            }
        case "V3":    // num API v9 may return "V3" in case of whoscall card type.
            self.type = DisplayRulePhoneNumberType.whoscallNumber.rawValue
        case "SPF":
            self.type = DisplayRulePhoneNumberType.singaporePoliceForce.rawValue
        default:    // empty string: no info
            if !numberObject.spam.isEmpty {
                self.type = DisplayRulePhoneNumberType.spam.rawValue
            } else {
                self.type = DisplayRulePhoneNumberType.noInfo.rawValue
            }
        }
        self.timestamp = Date().timeIntervalSince1970
    }
}
