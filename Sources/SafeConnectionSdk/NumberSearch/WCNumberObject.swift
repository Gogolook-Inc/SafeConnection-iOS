//
//  WCNumberObject.swift
//  CentralPark
//
//  Created by willsbor Kang on 2018/11/23.
//  Copyright © 2018年 gogolook. All rights reserved.
//

import Foundation

protocol InvalidKeysRecording {
    var invalidKeys: [String] { get set }
}

fileprivate extension KeyedDecodingContainer {
    func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key, default defaultValue: T, saving invalidKeys: inout [String]) throws -> T where T : Decodable {
        if let value = try decodeIfPresent(type, forKey: key) {
            return value
        } else {
            invalidKeys.append("\(key.stringValue)")
            return defaultValue
        }
    }

    func decode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key, default defaultValue: T, saving invalidKeys: inout [String]) throws -> T where T : Decodable & InvalidKeysRecording {
        if let value = try decodeIfPresent(type, forKey: key) {
            invalidKeys.append(contentsOf: value.invalidKeys.map { "\(key.stringValue):\($0)" })
            return value
        } else {
            invalidKeys.append("\(key.stringValue)")
            return defaultValue
        }
    }
}

/// Number Object 的物件結構
///
/// 預期 server 給的 JSON 不會漏掉 key
/// 所以盡量不用 option 來避免使用上的麻煩 (Images 的物件內還是有用 option)
///
/// 但如果有漏掉，為了避免 crash 或是 物件無法正常 parse 出來。
/// 則會在對應的變數，填上 `emptyStringValue` `emptyIntValue` `emptyBoolValue` or [] (empty array)
/// 並且會在 invalidKeys 內被記錄 ex: ["name", "ask:name"]。 前面的例子則表示 -- 沒有 [root 的 name]，且沒有 [Ask 下的 name]
///
/// - Note: 目前的方法無法區分「漏掉 Key」或是「Value 是 null」的狀況，ex: {"aa": null, "b": ""} vs {"b": ""}, key "aa" 在上面兩種狀況應該都會被帶入 emptyXXXValue
///
public struct WCNumberObject: Codable, Equatable, InvalidKeysRecording {
    static let emptyStringValue = ""
    static let emptyIntValue = Int(Int32.min)
    static let emptyBoolValue = false
    
    public struct Ask: Codable, Equatable, InvalidKeysRecording {
        public let name: [String]
        public let spam: [String]
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case name
            case spam
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode([String].self, forKey: .name, default: [], saving: &invalidKeys)
            spam = try container.decode([String].self, forKey: .spam, default: [], saving: &invalidKeys)
        }
        
        init() {
            name = []
            spam = []
        }
    }
    public struct ContactInfo: Codable, Equatable, InvalidKeysRecording {
        public let type: String
        public let info: String
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case type
            case info
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            type = try container.decode(String.self, forKey: .type, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
            info = try container.decode(String.self, forKey: .info, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        }
        
        init() {
            type = WCNumberObject.emptyStringValue
            info = WCNumberObject.emptyStringValue
        }
    }
    public struct Hit: Codable, Equatable, InvalidKeysRecording {
        public let name: Bool
        public let nameSource: String
        public let spam: Bool
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case name
            case nameSource = "name_source"
            case spam
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode(Bool.self, forKey: .name, default: WCNumberObject.emptyBoolValue, saving: &invalidKeys)
            nameSource = try container.decode(String.self, forKey: .nameSource, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
            spam = try container.decode(Bool.self, forKey: .spam, default: WCNumberObject.emptyBoolValue, saving: &invalidKeys)
        }
        
        init() {
            name = WCNumberObject.emptyBoolValue
            nameSource = WCNumberObject.emptyStringValue
            spam = WCNumberObject.emptyBoolValue
        }
    }
    public struct Hourj: Codable, Equatable, InvalidKeysRecording {
        public let r0: Int
        public let r1: Int
        public let r2: Int
        public let r3: Int
        public let r4: Int
        public let r5: Int
        public let r6: Int
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case r0 = "0"
            case r1 = "1"
            case r2 = "2"
            case r3 = "3"
            case r4 = "4"
            case r5 = "5"
            case r6 = "6"
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            r0 = try container.decode(Int.self, forKey: .r0, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r1 = try container.decode(Int.self, forKey: .r1, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r2 = try container.decode(Int.self, forKey: .r2, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r3 = try container.decode(Int.self, forKey: .r3, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r4 = try container.decode(Int.self, forKey: .r4, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r5 = try container.decode(Int.self, forKey: .r5, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            r6 = try container.decode(Int.self, forKey: .r6, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
        }
        
        init() {
            r0 = WCNumberObject.emptyIntValue
            r1 = WCNumberObject.emptyIntValue
            r2 = WCNumberObject.emptyIntValue
            r3 = WCNumberObject.emptyIntValue
            r4 = WCNumberObject.emptyIntValue
            r5 = WCNumberObject.emptyIntValue
            r6 = WCNumberObject.emptyIntValue
        }
    }
    public struct Images: Codable, Equatable, InvalidKeysRecording {
        public struct Cover: Codable, Equatable {
            enum CodingKeys: String, CodingKey {
                case r0 = "0"
            }
            
            public let r0: [String]?
            
            init() {
                self.r0 = nil
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(r0, forKey: .r0)
            }
        }
        public struct Meta: Codable, Equatable {
            enum CodingKeys: String, CodingKey {
                case r0 = "0"
                case r1 = "1"
                case r2 = "2"
                case r3 = "3"
                case p
            }
            
            public let r0: String?
            public let r1: String?
            public let r2: String?
            public let r3: String?
            public let p: String?
            
            init() {
                self.r0 = nil
                self.r1 = nil
                self.r2 = nil
                self.r3 = nil
                self.p = nil
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(r0, forKey: .r0)
                try container.encode(r1, forKey: .r1)
                try container.encode(r2, forKey: .r2)
                try container.encode(r3, forKey: .r3)
                try container.encode(p, forKey: .p)
            }
        }
        public struct Photos: Codable, Equatable {
            enum CodingKeys: String, CodingKey {
                case r1 = "1"
                case r2 = "2"
            }
            
            public let r1: [[String]]?
            public let r2: [[String]]?
            
            init() {
                self.r1 = nil
                self.r2 = nil
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(r1, forKey: .r1)
                try container.encode(r2, forKey: .r2)
            }
        }
        public struct Profile: Codable, Equatable {
            enum CodingKeys: String, CodingKey {
                case r0 = "0"
            }
            
            public let r0: [String]?
            
            init() {
                self.r0 = nil
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(r0, forKey: .r0)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case cover
            case meta
            case photos
            case profile
        }
        
        public let cover: Cover
        public let meta: Meta
        public let photos: Photos
        public let profile: Profile
        public internal(set) var invalidKeys: [String] = []
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            cover = try container.decode(Cover.self, forKey: .cover, default: Cover(), saving: &invalidKeys)
            meta = try container.decode(Meta.self, forKey: .meta, default: Meta(), saving: &invalidKeys)
            photos = try container.decode(Photos.self, forKey: .photos, default: Photos(), saving: &invalidKeys)
            profile = try container.decode(Profile.self, forKey: .profile, default: Profile(), saving: &invalidKeys)
        }
        
        init() {
            cover = Cover()
            meta = Meta()
            photos = Photos()
            profile = Profile()
        }
    }
    public struct Stats: Codable, Equatable, InvalidKeysRecording {
        public let callin: Int
        public let contact: Int
        public let favor: Int
        public let offhook: Int
        public let spam: Int
        public let tag: Int
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case callin
            case contact
            case favor
            case offhook
            case spam
            case tag
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            callin = try container.decode(Int.self, forKey: .callin, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            contact = try container.decode(Int.self, forKey: .contact, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            favor = try container.decode(Int.self, forKey: .favor, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            offhook = try container.decode(Int.self, forKey: .offhook, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            spam = try container.decode(Int.self, forKey: .spam, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
            tag = try container.decode(Int.self, forKey: .tag, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
        }
        
        init() {
            callin = WCNumberObject.emptyIntValue
            contact = WCNumberObject.emptyIntValue
            favor = WCNumberObject.emptyIntValue
            offhook = WCNumberObject.emptyIntValue
            spam = WCNumberObject.emptyIntValue
            tag = WCNumberObject.emptyIntValue
        }
    }
    public struct WebResult: Codable, Equatable, InvalidKeysRecording {
        public let title: String
        public let descr: String
        public let url: String
        public internal(set) var invalidKeys: [String] = []
        
        enum CodingKeys: String, CodingKey {
            case title
            case descr
            case url
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            title = try container.decode(String.self, forKey: .title, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
            descr = try container.decode(String.self, forKey: .descr, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
            url = try container.decode(String.self, forKey: .url, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        }
        
        init() {
            title = WCNumberObject.emptyStringValue
            descr = WCNumberObject.emptyStringValue
            url = WCNumberObject.emptyStringValue
        }
    }
    
    public let address: String
    public let ask: Ask
    public let bizcate: String
    public let contactInfo: [ContactInfo]
    public let descr: String
    public let geocoding: String
    public let hit: Hit
    public let hourd: String
    public let hourj: Hourj
    public let images: Images
    public let intro: String
    public let keywords: [String]
    public let lnglat: [Double]
    public let name: String
    public let nameCandidates: [String]
    public let rating: Int
    public let serviceAreas: [String]
    public let spam: String
    public let spamlevel: Int
    public let stats: Stats
    public let telecom: String
    public let type: String
    public let warning: Int
    public let webresults: [WebResult]
    public internal(set) var invalidKeys: [String] = []
    
    enum CodingKeys: String, CodingKey {
        case address
        case ask
        case bizcate
        case contactInfo = "contact_info"
        case descr
        case geocoding
        case hit
        case hourd
        case hourj
        case images
        case intro
        case keywords
        case lnglat
        case name
        case nameCandidates = "name_candidates"
        case rating
        case serviceAreas = "service_areas"
        case spam
        case spamlevel
        case stats
        case telecom
        case type
        case warning
        case webresults
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        address = try container.decode(String.self, forKey: .address, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        ask = try container.decode(Ask.self, forKey: .ask, default: Ask(), saving: &invalidKeys)
        bizcate = try container.decode(String.self, forKey: .bizcate, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        contactInfo = try container.decode([ContactInfo].self, forKey: .contactInfo, default: [], saving: &invalidKeys)
        descr = try container.decode(String.self, forKey: .descr, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        geocoding = try container.decode(String.self, forKey: .geocoding, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        hit = try container.decode(Hit.self, forKey: .hit, default: Hit(), saving: &invalidKeys)
        hourd = try container.decode(String.self, forKey: .hourd, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        hourj = try container.decode(Hourj.self, forKey: .hourj, default: Hourj(), saving: &invalidKeys)
        images = try container.decode(Images.self, forKey: .images, default: Images(), saving: &invalidKeys)
        intro = try container.decode(String.self, forKey: .intro, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        keywords = try container.decode([String].self, forKey: .keywords, default: [], saving: &invalidKeys)
        lnglat = try container.decode([Double].self, forKey: .lnglat, default: [], saving: &invalidKeys)
        name = try container.decode(String.self, forKey: .name, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        nameCandidates = try container.decode([String].self, forKey: .nameCandidates, default: [], saving: &invalidKeys)
        rating = try container.decode(Int.self, forKey: .rating, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
        serviceAreas = try container.decode([String].self, forKey: .serviceAreas, default: [], saving: &invalidKeys)
        spam = try container.decode(String.self, forKey: .spam, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        spamlevel = try container.decode(Int.self, forKey: .spamlevel, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
        stats = try container.decode(Stats.self, forKey: .stats, default: Stats(), saving: &invalidKeys)
        telecom = try container.decode(String.self, forKey: .telecom, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        type = try container.decode(String.self, forKey: .type, default: WCNumberObject.emptyStringValue, saving: &invalidKeys)
        warning = try container.decode(Int.self, forKey: .warning, default: WCNumberObject.emptyIntValue, saving: &invalidKeys)
        webresults = try container.decode([WebResult].self, forKey: .webresults, default: [], saving: &invalidKeys)
    }
}
