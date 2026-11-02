//
//  File.swift
//  Secure-Box
//
//  Created by Dzmitry Letko on 09/10/2025.
//

public import Foundation
public import SecureBoxTypes

import CryptoKit

public extension File {
    func open() throws -> Data {
        guard let filePath = path.filePath else { throw cocoaError(.fileNoSuchFile) }
        guard let key = SymmetricKey(base64: key) else { throw CryptoKitError.incorrectKeySize }

        return try Algorithm().open(Data(contentsOfFile: filePath), using: key)
    }
}

// MARK: - Data
private extension Data {
    /**
     Reads the file with POSIX calls, as `Data(contentsOf:)` costs more on every open. There is no `F_NOCACHE`: it would keep the
     file out of the page cache, so every open would read the storage again. `failure` stays out of line to keep the code small.
     */
    init(contentsOfFile path: String) throws {
        @inline(never)
        func failure(_ code: Int32) -> any Error {
            let reason: CocoaError.Code = switch code {
            case ENOENT: .fileReadNoSuchFile
            case EACCES, EPERM: .fileReadNoPermission
            default: .fileReadUnknown
            }

            return cocoaError(reason)
        }

        var descriptor: Int32

        repeat {
            descriptor = unsafe open(path, O_RDONLY | O_CLOEXEC)
        } while descriptor < 0 && errno == EINTR
        guard descriptor >= 0 else {
            throw failure(errno)
        }

        defer { close(descriptor) }

        var info = stat()

        guard unsafe fstat(descriptor, &info) == 0 else { throw failure(errno) }

        let size = Int(info.st_size)
        var data = Data(count: size)
        var span = data.mutableBytes
        var offset = 0

        while offset < size {
            // `read` fails on a count above `INT_MAX` instead of reading less.
            let count = span.withUnsafeMutableBytes { buffer in
                guard let base = buffer.baseAddress else { return 0 }

                return unsafe read(descriptor, base + offset, Swift.min(size - offset, Int(Int32.max)))
            }
            let code = count < 0 ? errno : 0

            if count > 0 {
                offset += count
            } else if code != EINTR {
                throw failure(code)
            }
        }

        self = data
    }
}
