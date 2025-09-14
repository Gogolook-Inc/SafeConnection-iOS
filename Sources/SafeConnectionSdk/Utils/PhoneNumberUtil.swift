//
//  PhoneNumberUtil.swift
//  Merli
//
//  Created by Luis Wu on 4/15/19.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit
internal import PhoneNumberKit

class PhoneNumberUtil {
    private let number: String  // e164 or short code
    private let impl: PhoneNumberUtility
    static let defaultRegionCode = PhoneNumberUtility.defaultRegionCode().lowercased()

    fileprivate static let invalidPhoneNumber: UInt64 = 0  // invalid number when `shouldReturnFailedEmptyNumbers` sets to true
    /// The enumaration denoting the output format of the method `parse(_:, region:, format:, ignoreType:, shouldReturnFailedEmptyNumbers:) `
    enum OutputFormat {
        case e164
        case national

        /// The method converts `OutputFormat` to `PhoneNumberKit`'s `PhoneNumberFormat`
        fileprivate func convert() -> PhoneNumberFormat {
            switch self {
            case .e164:
                return .e164
            case .national:
                return .national
            }
        }
    }

    /// Initializer
    ///
    /// - Parameter number: a number could be a valid e164 or short code. Note that all numbers that are not a valid e164 are considered as short codes
    init(number: String) throws {
        guard !number.isEmpty else {
            throw Error(with: .invalidInitParam)
        }
        impl = PhoneNumberUtility()
        self.number = number
    }

    /// Initializer
    ///
    /// - Parameter number: a number could be a valid e164 or short code. Note that all numbers that are not a valid e164 are considered as short codes
    init(number: CXCallDirectoryPhoneNumber) {
        impl = PhoneNumberUtility()
        self.number = "\(number)"
    }

    var e164: String? {
        do {
            let regionCode = impl.parse([number, "+\(number)"]).compactMap { $0.regionID }.first ?? PhoneNumberUtility.defaultRegionCode()
            return impl.format(try impl.parse(number, withRegion: regionCode), toType: .e164)
        } catch {
            //logger.warn("Cannot parse number as e164: \(error)")
            return nil
        }
    }

    var national: String? {
        if let e164 = self.e164, let phone = try? impl.parse(e164) {
            return impl.format(phone, toType: .national)
        } else {
            return nil
        }
    }

    var nationalNumbericsOnly: String? {
        if let e164 = self.e164, let phone = try? impl.parse(e164) {
            return impl.format(phone, toType: .national).removePhoneNumberSignCharacters()
        } else {
            return nil
        }
    }

    var regionCode: String? {
        if let e164 = self.e164, let phone = try? impl.parse(e164) {
            return phone.regionID?.lowercased()
        } else {
            return nil
        }
    }

    func getE164WithRegion(_ region: String) -> String? {
        do {
            let phone = try impl.parse(self.number, withRegion: region, ignoreType: true)
            return impl.format(phone, toType: .e164, withPrefix: true)
        } catch {
            return nil
        }
    }

    /// This class method parses a list of phone numbers (e164, with + prefix) and outputs a list of tuples include phone numbers and region ids in the format specified
    /// - Parameters:
    ///   - e164PhoneNumbers: e164 phone numbers with `+` prefix. An invalid e164 number will be treated as short code
    ///   - regionCode: The region code used for parsing. It doesn't affect valid e164 numbers
    ///   - format: currently supports `e164` and `national`
    ///   - ignoreType: whether ignore type (PhoneNumberKit's parameter). Default `true`
    ///   - shouldReturnFailedEmptyNumbers: whether return failed empty numbers (PhoneNumberKit's parameter). Default `true`
    class func parse(_ e164PhoneNumbers: [String],
                     regionCode: String,
                     format: OutputFormat,
                     ignoreType: Bool = true,
                     shouldReturnFailedEmptyNumbers: Bool = true) -> [(formattedNumber: String?, regionID: String?)] {
        let impl = PhoneNumberUtility()
        let parsedNumbers = impl.parse(e164PhoneNumbers, withRegion: regionCode, ignoreType: ignoreType, shouldReturnFailedEmptyNumbers: shouldReturnFailedEmptyNumbers)
        let formattedNumbers = parsedNumbers.map { phoneNumber -> (formattedNumber: String?, regionID: String?) in
            let result = impl.format(phoneNumber, toType: format.convert())
            if phoneNumber.nationalNumber == invalidPhoneNumber {
                return (formattedNumber: nil, regionID: nil)
            } else {
                return (formattedNumber: result, regionID: phoneNumber.regionID)
            }
        }
        return formattedNumbers
    }
}
