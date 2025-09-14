//
//  PhoneNumberBlocking.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/7/4.
//  Copyright © 2019 Gogolook. All rights reserved.
//

import CallKit

protocol PhoneNumberBlocking {
    func block(_ e164OrShortCode: CXCallDirectoryPhoneNumber, regionCode: String, onComplete: @escaping (Error?) -> Void)
    func unblock(_ e164OrShortCode: CXCallDirectoryPhoneNumber, onComplete: @escaping (Error?) -> Void)
    func isBlocked(_ e164OrShortCode: CXCallDirectoryPhoneNumber) -> Bool

    func block(_ e164OrShortCode: CXCallDirectoryPhoneNumber, regionCode: String) async throws
    func unblock(_ e164OrShortCode: CXCallDirectoryPhoneNumber) async throws
}
