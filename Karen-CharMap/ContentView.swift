import SwiftUI
import AppKit

struct ContentView: View {
    @State private var search = ""
    @State private var activeSet: UnicodeSet?
    @State private var scrollTarget: UInt32?
    @State private var selected: MapCharacter?
    @State private var composedText = ""
    @State private var hexInput = ""
    @State private var decimalInput = ""
    @State private var message = ""
    @State private var groups: [CharacterGroup] = UnicodeSet.allCases.map { set in
        CharacterGroup(set: set, characters: MapCharacter.all.filter { $0.set == set })
    }

    var body: some View {
        VStack(spacing: 0) {
            PickerHeader(search: $search)
            SetNavigation(activeSet: $activeSet)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            Divider()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 4)],
                                  spacing: 8, pinnedViews: [.sectionHeaders]) {
                            ForEach(groups) { group in
                                Section {
                                    ForEach(group.characters) { character in
                                        CharacterCell(character: character,
                                                      isSelected: selected?.id == character.id,
                                                      select: { select(character) },
                                                      insert: { select(character); composedText += character.text })
                                            .id(character.id)
                                    }
                                } header: {
                                    HStack {
                                        Text(group.set.rawValue).font(.headline)
                                        Spacer()
                                        Text("\(group.characters.count) characters")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 10)
                                    .background(Color(nsColor: .windowBackgroundColor))
                                    .id(group.set)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                    .overlay {
                        if groups.isEmpty {
                            ContentUnavailableView.search(text: search)
                        }
                    }
                    .onChange(of: scrollTarget) { _, id in
                        if let id {
                            withAnimation { proxy.scrollTo(id, anchor: .center) }
                        }
                    }
                    Divider()
                    HStack {
                        Image(systemName: "cursorarrow")
                        Text("Click to inspect · Double-click to insert")
                        Spacer()
                        Text("Padauk Regular")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    ComposeField(text: $composedText, copy: { copy(composedText) })
                    CodeLookupRow(title: "Hex", value: $hexInput,
                                  canFind: lookup(hexInput, radix: 16) != nil,
                                  find: { find(hexInput, radix: 16) },
                                  copyValue: { copy(hexInput) })
                    CodeLookupRow(title: "Dec", value: $decimalInput,
                                  canFind: lookup(decimalInput, radix: 10) != nil,
                                  find: { find(decimalInput, radix: 10) },
                                  copyValue: { copy(decimalInput) })
                    Text(message.isEmpty ? "Enter a code point from the available character sets." : message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                CharacterInspector(character: selected,
                                   insert: { if let selected { composedText += selected.text } },
                                   copy: { if let selected { copy(selected.text) } })
                    .padding(12)
                    .frame(width: 230)
                    .background(Color(nsColor: .controlBackgroundColor),
                                in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(12)
        }
        .frame(minWidth: 720, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: search) { _, _ in refresh() }
        .onChange(of: activeSet) { _, _ in refresh() }
    }

    private func refresh() {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        groups = UnicodeSet.allCases.compactMap { set in
            let characters = MapCharacter.all.filter {
                $0.set == set && (activeSet == nil || activeSet == set) && (query.isEmpty || $0.text == query ||
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    ("U+" + $0.hex).localizedCaseInsensitiveContains(query))
            }
            return characters.isEmpty ? nil : CharacterGroup(set: set, characters: characters)
        }
    }

    private func select(_ character: MapCharacter) {
        selected = character
        hexInput = character.hex
        decimalInput = character.decimal
        message = ""
    }

    private func lookup(_ input: String, radix: Int) -> MapCharacter? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if radix == 16 {
            if value.lowercased().hasPrefix("u+") || value.lowercased().hasPrefix("0x") {
                value = String(value.dropFirst(2))
            }
        }
        guard let code = UInt32(value, radix: radix) else { return nil }
        return MapCharacter.all.first { $0.id == code }
    }

    private func find(_ input: String, radix: Int) {
        guard let character = lookup(input, radix: radix) else { return }
        search = ""
        activeSet = nil
        refresh()
        select(character)
        scrollTarget = nil
        Task { @MainActor in
            await Task.yield()
            scrollTarget = character.id
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        message = "Copied to clipboard"
    }
}

private struct CharacterCell: View {
    let character: MapCharacter
    let isSelected: Bool
    let select: () -> Void
    let insert: () -> Void
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        CharacterGlyph(character: character, isSelected: isSelected || isFocused, isHovered: isHovered)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .focusable()
            .focused($isFocused)
            .onKeyPress(.return) { insert(); return .handled }
            .onKeyPress(.space) { select(); return .handled }
            .onTapGesture(count: 2) { insert() }
            .onTapGesture { select() }
            .help(character.name + " · U+" + character.hex)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(character.name + ", U+" + character.hex)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { select() }
            .accessibilityAction(named: "Insert character") { insert() }

    }
}

private struct CharacterGlyph: View {
    let character: MapCharacter
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(character.display)
                .font(.custom(PadaukFont.name, size: 30))
                .frame(height: 52)
            Text("U+" + character.hex)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(isHovered ? 0.25 : 0.06), lineWidth: 2)
        }
    }
}

private struct PickerHeader: View {
    @Binding var search: String
    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Karen-CharMap").font(.headline)
                Text("Browse. Compose. Copy.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search characters or U+ code", text: $search)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .accessibilityLabel("Search characters")
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(9)
            .frame(maxWidth: 300)
            .background(Color(nsColor: .controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 9))
            Button("Search") { searchFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .hidden()
                .frame(width: 0, height: 0)
        }
        .padding(12)
    }
}

private struct SetNavigation: View {
    @Binding var activeSet: UnicodeSet?

    var body: some View {
        HStack(spacing: 6) {
            SetChip(title: "All", isSelected: activeSet == nil) { activeSet = nil }
            ForEach(UnicodeSet.allCases) { set in
                SetChip(title: set.rawValue, isSelected: activeSet == set) {
                    activeSet = set
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct SetChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.05),
                            in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct ComposeField: View {
    @Binding var text: String
    let copy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Compose", systemImage: "text.cursor").font(.headline)
                Spacer()
                Text("\(text.count) characters").font(.caption).foregroundStyle(.secondary)
                Button("Clear") { text = "" }
                    .buttonStyle(.borderless)
                    .disabled(text.isEmpty)
            }
            HStack(alignment: .center, spacing: 8) {
                TextField("Double-click characters to compose", text: $text, axis: .vertical)
                    .font(.custom(PadaukFont.name, size: 20))
                    .lineLimit(1...2)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor),
                                in: RoundedRectangle(cornerRadius: 9))
                    .accessibilityLabel("Composed text")
                Button(action: copy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty)
            }
        }
    }
}

private struct CodeLookupRow: View {
    let title: String
    @Binding var value: String
    let canFind: Bool
    let find: () -> Void
    let copyValue: () -> Void

    var body: some View {
        HStack {
            Text(title + ":").frame(width: 36, alignment: .leading)
            TextField(title == "Hex" ? "e.g. 1000" : "e.g. 4096", text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(width: 120)
                .accessibilityLabel(title == "Hex" ? "Hexadecimal code point" : "Decimal code point")
                .onSubmit { if canFind { find() } }
            Button("Find", action: find).disabled(!canFind)
            Button("Copy", action: copyValue).disabled(value.isEmpty)
        }
    }
}

private struct CharacterInspector: View {
    let character: MapCharacter?
    let insert: () -> Void
    let copy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Character", systemImage: "info.circle").font(.headline)
            if let character {
                HStack(spacing: 16) {
                    Text(character.display)
                        .font(.custom(PadaukFont.name, size: 36))
                        .frame(width: 60, height: 64)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("U+" + character.hex).monospaced()
                        Text("Decimal " + character.decimal).foregroundStyle(.secondary)
                    }
                }
                Text(character.name)
                    .font(.caption)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Insert", action: insert)
                        .buttonStyle(.borderedProminent)
                    Button("Copy character", action: copy)
                }
            } else {
                Text("Select a character to see its Unicode name and code point.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            }
        }
    }
}

#Preview {
    ContentView()
}
