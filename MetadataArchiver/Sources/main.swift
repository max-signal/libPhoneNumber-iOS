import Foundation
import JavaScriptCore

func printErr(_ value: String) {
    try! FileHandle.standardError.write(contentsOf: Data(value.utf8) + Data("\n".utf8))
}

if CommandLine.arguments.count < 2 {
    printErr("You must specify a path to libphonenumber.")
    exit(1)
}
let libPhoneNumberPath = CommandLine.arguments[1]
let libPhoneNumberURL = URL(filePath: libPhoneNumberPath, relativeTo: URL.currentDirectory())

let outputUrl = URL(filePath: "libPhoneNumber/NBPhoneNumberMetaData.plist", relativeTo: URL.currentDirectory())
// Dump JSON as well to make diffs easier to review.
let jsonOutputUrl = URL(filePath: "libPhoneNumber/NBPhoneNumberMetaData.json", relativeTo: URL.currentDirectory())

func archiveObject(_ object: Any) -> Data {
    class Deduplicator: NSObject, NSKeyedArchiverDelegate {
        var objects: Set<NSObject> = []

        func archiver(_ archiver: NSKeyedArchiver, willEncode object: Any) -> Any? {
            guard let nsObject = object as? NSObject else {
                return object
            }
            return objects.insert(nsObject).memberAfterInsert
        }
    }

    let coder = NSKeyedArchiver(requiringSecureCoding: false)
    let delegate = Deduplicator()
    coder.delegate = delegate
    coder.encode(object, forKey: NSKeyedArchiveRootObjectKey)
    _ = delegate
    return coder.encodedData
}

func parseMetadata3() throws {
    let context = JSContext()!
    context.exceptionHandler = { _, exception in
        printErr("\(exception!)")
        exit(1)
    }
    context.evaluateScript("""
    var goog = {"provide": function() {}};
    var i18n = {"phonenumbers": {"metadata": {}}};
    """)
    let metadataFileUrl = libPhoneNumberURL.appending(path: "javascript/i18n/phonenumbers/metadata.js")
    let metadataContent = String(data: try Data(contentsOf: metadataFileUrl), encoding: .utf8)!
    context.evaluateScript(metadataContent)
    let metadataEncoded = context.evaluateScript("JSON.stringify(i18n.phonenumbers.metadata)").toString()!
    let metadataObject = try JSONSerialization.jsonObject(with: Data(metadataEncoded.utf8))
    try JSONSerialization.data(withJSONObject: metadataObject, options: [.sortedKeys, .prettyPrinted]).write(to: jsonOutputUrl)
    try archiveObject(metadataObject).write(to: outputUrl)
}

do {
    try parseMetadata3()
} catch {
    printErr("\(error)")
    exit(1)
}

