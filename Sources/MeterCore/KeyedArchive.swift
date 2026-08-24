import Foundation

public enum KeyedArchive {
    public static func root(from data: Data) throws -> Any? {
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard
            let dict = nsDictionary(plist),
            let objects = nsArray(dict["$objects"]),
            let top = nsDictionary(dict["$top"]),
            let rootUID = top["root"]
        else {
            return nil
        }
        return Decoder(objects: objects).decode(rootUID)
    }

    fileprivate static func nsDictionary(_ value: Any?) -> [String: Any]? {
        guard let value else { return nil }
        if let dict = value as? [String: Any] { return dict }
        guard let dict = value as? NSDictionary else { return nil }
        var out: [String: Any] = [:]
        dict.forEach { key, val in
            if let k = key as? String {
                out[k] = val
            }
        }
        return out
    }

    fileprivate static func nsArray(_ value: Any?) -> [Any]? {
        guard let value else { return nil }
        if let array = value as? [Any] { return array }
        if let array = value as? NSArray { return array.map { $0 as Any } }
        return nil
    }

    private struct Decoder {
        let objects: [Any]

        func decode(_ value: Any, seen: Set<Int> = []) -> Any? {
            if let uid = uidIndex(value) {
                if seen.contains(uid) { return nil }
                guard objects.indices.contains(uid) else { return nil }
                var next = seen
                next.insert(uid)
                return decode(objects[uid], seen: next)
            }

            if let string = value as? String {
                return string == "$null" ? nil : string
            }

            if let dict = KeyedArchive.nsDictionary(value) {
                if dict["$classes"] != nil || dict["$classname"] != nil,
                   dict["NS.time"] == nil,
                   dict["NS.keys"] == nil,
                   dict["NS.objects"] == nil,
                   dict["In"] == nil {
                    return dict["$classname"]
                }
                if let time = number(dict["NS.time"]) {
                    return Date(timeIntervalSinceReferenceDate: time)
                }
                if dict["NS.keys"] != nil, dict["NS.objects"] != nil {
                    let keys = decode(dict["NS.keys"]!, seen: seen) as? [Any] ?? []
                    let vals = decode(dict["NS.objects"]!, seen: seen) as? [Any] ?? []
                    var mapped: [String: Any] = [:]
                    for (index, key) in keys.enumerated() {
                        let name = stringify(key)
                        if index < vals.count {
                            mapped[name] = vals[index]
                        }
                    }
                    return mapped
                }
                if let objectsRaw = dict["NS.objects"], dict["NS.keys"] == nil {
                    return decode(objectsRaw, seen: seen)
                }

                var mapped: [String: Any] = [:]
                for (key, raw) in dict where key != "$class" {
                    if let decoded = decode(raw, seen: seen) {
                        mapped[key] = decoded
                    }
                }
                return mapped
            }

            if let array = KeyedArchive.nsArray(value) {
                return array.compactMap { decode($0, seen: seen) }
            }

            return value
        }

        private func uidIndex(_ value: Any) -> Int? {
            if let dict = KeyedArchive.nsDictionary(value) {
                if let n = dict["CF$UID"] as? Int { return n }
                if let n = dict["CF$UID"] as? Int64 { return Int(n) }
                if let n = dict["CF$UID"] as? NSNumber { return n.intValue }
            }
            let desc = String(describing: value)
            // NSDictionary descriptions embed nested UIDs; only match the UID object itself.
            guard desc.hasPrefix("<CFKeyedArchiverUID") else { return nil }
            guard let start = desc.range(of: "value = ") else { return nil }
            let digits = desc[start.upperBound...].prefix(while: \.isNumber)
            return Int(digits)
        }

        private func number(_ value: Any?) -> Double? {
            switch value {
            case let n as Double: n
            case let n as Int: Double(n)
            case let n as Int64: Double(n)
            case let n as NSNumber: n.doubleValue
            default: nil
            }
        }

        private func stringify(_ value: Any) -> String {
            if let string = value as? String { return string }
            return String(describing: value)
        }
    }
}
