//
//  StringExtension.swift
//  Symbol Selector
//
//  Created by Joseph Cestone on 4/3/22.
//

import Foundation

extension String {
    
    // MARK: Unneeded - Finding Words
    
//    var isRealWord: Bool {
//        let check = checker.checkSpelling(of: self, startingAt: 0)
//        return check.location == NSNotFound
//    }
//
//    var lastWord: String {
//        for length in stride(from: min(count, 45), through: 1, by: -1) { //45 letters is longest word
//            let testString:String = String(suffix(length))
//            if testString.isRealWord {
//                return testString
//            }
//        }
//        return self
//    }
//
//    var englishWords: [String] {
//        var unspaced = self
//        var words = [String]()
//        while unspaced != "" {
//            let nextWord = unspaced.lastWord
//            words.append(nextWord)
//            unspaced.removeLast(nextWord.count)
//        }
//        words.reverse()
//        return words
//    }

    /// Stem of a SF Symbol name string -- everything before the first '.' or whole string if no '.'
    /// Ex: "info.circle.fill" has stem "info"
    var symbolNameStem: String {
        components(separatedBy: ".").first!
    }
    
    /// Ten closest words to `self` sorted by relavence -- NL distance.
    /// Ex: "Text" returns ["textual", "writing", "translation", "transcribing", "bible", "transcription",
    /// "exegesis", "transcribe", "correspondence", "emoticon"]
    var neighbors: [String] {
        embedding
            .neighbors(for: lowercased(), maximumCount: 10)
            .sorted { lhs, rhs in
                lhs.1 < rhs.1
            }
            .map { (synonym, distance) in
                synonym
            }
    }
    
    /// Closest 10 words to `self`, filtered to only include words that are stems of symbol names
    /// Ex: "info.circle.fill" has stem "info"
    var neighborSymbolStems: [String] {
        ([self] + neighbors).filter { symbolStem in
            symbolsByStems[symbolStem] != nil
        }
    }
    
    /// Stems of symbols that have a stem or leaf starting with the first 4 characters of `self`
    /// Ex: "info.circle.fill" has stem "info"  and leaves "circle" and "fill"
    /// Ex: `self` is "textual" -- search for symbols names with leaves or stems starting with "text"
    /// - returns: stems of relavent symbol names
    var symbolStemsByPartStemOrLeaf: [String] {
        guard count > 3 else { return [] }
        let search = lowercased().prefix(4)
        return symbolNamesForShortLeaves[search] ?? []
    }
    
    
    /// Combines natural language neighbor suggestions and first 4 character searches
    /// - returns: stems of symbol names relavent to `self` sorted by relavence - NL distance
    var relatedSymbolStems: [String] {
        Array(Set(neighborSymbolStems + symbolStemsByPartStemOrLeaf))
            .sortedByRelance(to: self)
    }
}

// MARK: Array Extension

/// Sorts by NL distance to `term`, prioritizing elements that contain `term`.
extension Array where Element == String {
    func sortedByRelance(to term: String) -> [String] {
        return sorted { lhs, rhs in
            
            let leftContainsSelf = lhs.contains(term)
            let rightContainsSelf = rhs.contains(term)
            
            if leftContainsSelf && !rightContainsSelf {
                return true
            } else if !leftContainsSelf && rightContainsSelf {
                return false
            }
            
            let leftDistance = embedding.distance(between: term, and: lhs)
            let rightDistance = embedding.distance(between: term, and: rhs)
            return leftDistance < rightDistance // Bool - should left go first
        }
    }
}

// MARK: Dictionary Extension

/// Sorts by NL distance to Key`term`, prioritizing keys that contain `term`.
extension Dictionary where Key == String {
    func sortedByRelance(to term: String) -> [Self.Element] {
        return sorted { lhs, rhs in
            
            let leftContainsSelf = lhs.key.contains(term)
            let rightContainsSelf = rhs.key.contains(term)
            
            if leftContainsSelf && !rightContainsSelf {
                return true
            } else if !leftContainsSelf && rightContainsSelf {
                return false
            }
            
            let leftDistance = embedding.distance(between: term, and: lhs.key)
            let rightDistance = embedding.distance(between: term, and: rhs.key)
            return leftDistance < rightDistance // Bool - should left go first
        }
    }
}
