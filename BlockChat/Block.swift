//  Created by Edvinas Kruminis on 31/10/2018.
//  Copyright © 2018 Edvinas Kruminis. All rights reserved.
//

import Foundation
import CommonCrypto

struct Block: Codable {
	let index : Int
	let date : Double
	let previousHash : String
	var nonce : Int
	var difficultyLevel : Int
	let sender : String
	let recipient : String
	let data : String
	let key : String
	let sessionID : String
	let signature : String
	
	func encryptSHA256() -> String {
		let d: String = String(describing: self)
		var hash = d.data(using: .utf8)?.hashSHA256().map { String(format: "%02hhx", $0) }.joined()
		return hash!
	}
}

extension Data {
	func hashSHA256() -> Data {
		var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
		(self as Data).withUnsafeBytes {
			_ = CC_SHA256($0, CC_LONG((self as Data).count), &hash)
		}
		return Data(bytes: hash)
	}
}

