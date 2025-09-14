//
//  Kind.swift
//  Merli
//
//  Created by Dong-Yi Wu on 2019/4/1.
//  Copyright © 2019 Gogolook. All rights reserved.
//

/// For blocked list: specifying what to block
///
/// - delete: reserved to remove a blocked number. Not an actual block type
/// - phone: to block a phone call (iOS only supports this)
/// - sms: to block an SMS
/// - all: to block both phone call and SMS
enum Kind: Int {
    // `delete` is defined in [user sync api wiki](http://wiki.whoscall.com/index.php?title=User_sync_API)
    //
    // 進階情況
    // ======
    // 假設使用者 A 在 a、b 兩手機上的資料一樣，時間設定也一樣，當 A 將 a 手機上刪除某筆 block (whoscall Android 會標記 status 為 delete)，
    // 則其 kind 會被標注為 -1，並且 sync 上去，假設 update_time 設為 t0，之後 b 手機進行 sync，因為 b 手機的 sync_time 理論上是小於 t0，
    // 所以此筆 kind 為 -1 的情況會被 b 手機 sync 下來，於是 b 手機的某筆 block 也會被刪除。(whoscall Android 會刪除此項目)
    case delete = -1    // this should not be considered as an valid `Kind`.

    case phone = 1
    case sms = 2
    case all = 3    // phone + SMS
}
