import Foundation

/// File-only codec for `.appview` hierarchy exports (`AVJ2` + JSON via `WireAppViewFileCodec`).
/// Peertalk live wire uses `AVWireCodecV2` (JSON `AVJS` + screenshot `AVPG`) — not this type.
public enum AVWireCodec {
    public enum Error: Swift.Error {
        case unarchiveFailed
    }

    /// `.appview` v2 only (`AVJ2` + JSON). Legacy NSCoding documents are not supported.
    public static func loadHierarchyFile(from data: Data) throws -> AppViewHierarchyFile {
        guard WireAppViewFileCodec.isV2Format(data) else {
            throw NSError(
                domain: appviewErrorDomain,
                code: AppViewSharedErrCode.unsupportedFileType.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(
                        "This file uses an unsupported legacy format. Re-export the hierarchy from a current AppView app.",
                        comment: ""
                    ),
                ]
            )
        }
        return try WireAppViewFileCodec.appviewHierarchyFile(from: data)
    }

    /// Export `.appview` v2 (JSON + magic).
    public static func archive(hierarchyFile: AppViewHierarchyFile) throws -> Data {
        try WireAppViewFileCodec.data(from: hierarchyFile)
    }
}
