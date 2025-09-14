protocol APIAuthRequestBodyEncrypting {
    func encrypt(key: Data, input: Data) throws -> Data
}
