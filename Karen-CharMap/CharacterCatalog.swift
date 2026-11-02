import Foundation
import CoreText

enum UnicodeSet: String, CaseIterable, Identifiable {
    case myanmar = "Myanmar"
    case extendedB = "Myanmar Extended-B"
    case extendedA = "Myanmar Extended-A"
    case english = "English"
    case special = "Special characters"

    var id: String { rawValue }
    var ranges: [ClosedRange<UInt32>] {
        switch self {
        case .myanmar: [0x1000...0x109F]
        case .extendedB: [0xA9E0...0xA9FF]
        case .extendedA: [0xAA60...0xAA7F]
        case .english: [0x30...0x39, 0x41...0x5A, 0x61...0x7A]
        case .special: [0x20...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E,
                       0xA0...0xBF, 0x2000...0x206F, 0x20A0...0x20CF,
                       0x2190...0x21FF, 0x2200...0x22FF]
        }
    }
}

struct MapCharacter: Identifiable {
    let scalar: Unicode.Scalar
    let set: UnicodeSet
    var id: UInt32 { scalar.value }
    var text: String { String(scalar) }
    var name: String { scalar.properties.name ?? "Unnamed character" }
    var hex: String { String(format: "%04X", scalar.value) }
    var decimal: String { String(scalar.value) }
    var display: String {
        switch scalar.properties.generalCategory {
        case .nonspacingMark, .spacingMark, .enclosingMark:
            return "\u{25CC}" + text
        case .spaceSeparator:
            return "␣"
        default:
            return text
        }
    }

    static let all: [MapCharacter] = UnicodeSet.allCases.flatMap { set in
        set.ranges.flatMap { range in
            range.compactMap { value -> MapCharacter? in
                guard let scalar = Unicode.Scalar(value),
                      scalar.properties.generalCategory != .unassigned,
                      scalar.properties.generalCategory != .format else { return nil }
                return MapCharacter(scalar: scalar, set: set)
            }
        }
    }
}

struct CharacterGroup: Identifiable {
    let set: UnicodeSet
    let characters: [MapCharacter]
    var id: UnicodeSet { self.set }
}

enum PadaukFont {
    static let name: String = {
        guard let url = Bundle.main.url(forResource: "Padauk-Regular", withExtension: "ttf") else {
            return "Padauk"
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor]
        guard let descriptor = descriptors?.first else { return "Padauk" }
        return CTFontCopyPostScriptName(CTFontCreateWithFontDescriptor(descriptor, 16, nil)) as String
    }()
}
