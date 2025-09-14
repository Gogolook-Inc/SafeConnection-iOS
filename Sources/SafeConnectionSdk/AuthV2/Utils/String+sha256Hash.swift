extension String {
    func sha256Hash() throws -> String {
        guard let message = self.data(using: .utf8) else {
            throw AuthCryptoHelper.CryptoError.cannotConvertToData
        }
        let hashed = SHA256.hash(data: message)

        return hashed.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
