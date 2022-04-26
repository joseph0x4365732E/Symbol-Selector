//
//  ContentView.swift
//  Symbol Selector
//
//  Created by Joseph Cestone on 4/3/22.
//

import Cocoa
import NaturalLanguage
import SwiftUI

let embedding = NLEmbedding.wordEmbedding(for: .english)!
let checker = NSSpellChecker()
var symbolFullNames:[String] = []
var symbolStems = Set<String>()
var symbolNamesForShortLeaves = [Substring: [String]]()
var hasNames: Bool = false
var symbolsByStems = [String:[String]]()
var symbolsByName = [String:String]()

/// Read and arrange SF Symbol Names from SFSymbolNames.txt, for efficient searching.
/// - parameter hasNames Bool to report back and update UI once the SF Symbol names are loaded.
///
func loadSymbolNamesStringFromFile(hasNames: Binding<Bool>) {
    guard let fileURL =
            Bundle.main.url(forResource: "SFSymbolNames", withExtension: "txt") else {
        fatalError("Couldn't get SFSymbolNames file url from Bundle.")
    }
        
    guard let tempNames = try? String(contentsOf: fileURL) else {
        fatalError("Couln't read SFSymbolNames string from file url in bundle.")
    }
    let lines = tempNames.split(separator: "\n", omittingEmptySubsequences: true)
    let fullNameAndSymbolTuples:[(String, String)] = lines.map { (line) -> (String, String) in
        let seperated = line.components(separatedBy: "_")
        return (seperated.first!, seperated.last!)
    }
    symbolFullNames = fullNameAndSymbolTuples.map { $0.0 }
    symbolStems = Set(symbolFullNames.map { $0.symbolNameStem })
    let shortLeavesAndNameTuples:[(Substring, [String])] = symbolFullNames.flatMap { (symbolName) -> [(Substring, [String])] in
        symbolName.components(separatedBy: ".").map { nameLeaf in
            (nameLeaf.prefix(4), [symbolName.symbolNameStem])
        }
    }
    symbolNamesForShortLeaves = Dictionary(shortLeavesAndNameTuples, uniquingKeysWith: { (lhs, rhs) in
        lhs + rhs
    })
    symbolNamesForShortLeaves = symbolNamesForShortLeaves.mapValues { stemsWithDuplicates in
        Array(Set(stemsWithDuplicates))
    }
    symbolsByName = Dictionary(uniqueKeysWithValues: fullNameAndSymbolTuples)
    hasNames.wrappedValue = true
    symbolsByStems = Dictionary(grouping: symbolFullNames) { name in
       name.symbolNameStem
   }
}

struct SymbolPickerView: View {
    @State var hasNames = false
    @State var searchText = ""
    @State var selected = ""
    @State var quitOnSelect = true
    @State var expanded = Set<String>()
    @State var results = [String]()

    /// Top horizontally scrolling bar showing NL suggestions similar to `searchText`
    struct SuggestionsView: View {
        @Binding var currentText: String
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(currentText.neighbors, id: \.self) { neighbor in
                        Button {
                            currentText = neighbor
                        } label: {
                            Text(neighbor)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    /// Disclosure View containing all SF symbols with the same stem
    /// Ex: "info.circle.fill" has stem "info"
    struct StemDisclosureView: View {
        @Binding var selectedSymbol: String
        @Binding var expandedGroups: Set<String>
        @Binding var quitOnSelect: Bool
        var stem: String

        /// Quit the app or deselect the selected symbol, .125 seconds after it's selected
        private func delayedQuitOrDeselect() async {
            try? await Task.sleep(nanoseconds: 125_000_000)
            
            if quitOnSelect {
                exit(0)
            }
            selectedSymbol = ""
        }
        
        var body: some View {
            let bindingExpanded = Binding {
                expandedGroups.contains(stem)
            } set: { newValue in
                expandedGroups.remove(stem)
                if newValue {
                    expandedGroups.insert(stem)
                }
            }
            
            DisclosureGroup(isExpanded: bindingExpanded) {
                ForEach(symbolsByStems[stem]!.sortedByRelance(to: stem), id: \.self) { symbol in
                    HStack {
                        Image(systemName: symbol)
                            .frame(width: 20)
                        Text(symbol)
                        Spacer()
                    }
                    .background(RoundedRectangle(cornerRadius: 5).fill(symbol == selectedSymbol ? Color.blue : Color.clear))
                    .onTapGesture {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(symbolsByName[symbol]!, forType: .string)
                        selectedSymbol = symbol
                        Task {
                            await delayedQuitOrDeselect()
                        }
                    }
                    
                }
            } label: {
                Label {
                    Text(stem.capitalized)
                } icon: {
                    Image(systemName: symbolsByStems[stem]!.first!)
                }
                .onTapGesture {
                    bindingExpanded.wrappedValue.toggle()
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            //Search Field
            HStack(spacing: 10) {
                TextField("Symbol", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("", selection: $quitOnSelect) {
                    Image(systemName: "1.square")
                        .tag(true)
                    Image(systemName: "square.stack")
                        .tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .fixedSize()
            }
            .padding(.trailing)
            .padding(.vertical, 5)

            //Suggestions
            SuggestionsView(currentText: $searchText)
                .padding(.bottom, 5)

            //Symbols
            ScrollView {
                Group {
                    if !hasNames {
                        Text("Missing ~/Library/Application Support/SFSymbolPicker/SFSymbolNames.txt")
                    }
                }

                //Stem (group of symbols with same first name) Views
                LazyVStack {
                    ForEach(searchText.relatedSymbolStems, id: \.self) { stem in
                        // Individual Stem View
                        StemDisclosureView(selectedSymbol: $selected, expandedGroups: $expanded, quitOnSelect: $quitOnSelect, stem: stem)
                    }
                }
            }
            EmptyView()
        }
        .edgesIgnoringSafeArea(.leading)
        .padding(.leading)
        .frame(width: 350, height: 300)
        .cornerRadius(20)
        .onAppear {
            checker.setLanguage("en")
            loadSymbolNamesStringFromFile(hasNames: $hasNames)
        }
    }
}

/// Debug only Preview Provider
struct SymbolPickerView_Previews: PreviewProvider {
    static var previews: some View {
        SymbolPickerView()
    }
}
