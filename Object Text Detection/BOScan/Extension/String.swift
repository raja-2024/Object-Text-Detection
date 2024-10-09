//
//  String.swift
//
//
//  Created by Raja on 05/12/23.
//

import Foundation

extension String {

    func removeWhitespace() -> String {
        let stringWithoutWhitespace = self.replacingOccurrences(of: " ", with: "")
        return stringWithoutWhitespace
    }

    /// - Returns: Check current string exist in ignoredList.
    func contains(in ignoredList: [String]) -> Bool {
        var result = false
        outerloop: for text in self.components(separatedBy: " ") {
            for list in ignoredList {
                result = list.lowercased().contains(text.lowercased())
                if result {
                    break outerloop
                }
            }
        }
        return result
    }

    /// Extract substring from a string
    ///  - Parameters from : Start Index of substring
    ///               to : End Index of substring
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        return String(self[startIndex ..< endIndex])
    }
    /// Replace some wrong readed alpha character with value you passed
    /// - Parameters - Map to replace readed card number from vision.
    /// - Returns - Updated value after key replaced with matches value that was passed.
    func replaceOuccring(of with: [String: String]) -> String {
        var result = self
        with.forEach { key, value in
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result
    }

    /// - Returns Splited string in group
    /// - Parameter group size of each string
    func split(of group: Int) -> [String] {
        var result = [String]()
        for i in stride(from: 0, to: count, by: group) {
            let startIndex = self.index(self.startIndex, offsetBy: i)
            let endIndex = self.index(startIndex, offsetBy: group, limitedBy: endIndex) ?? endIndex
            result.append(String(self[startIndex..<endIndex]))
        }
        return result
    }
}
/// Filter duplicate number maintaing its order.
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter{ seen.insert($0).inserted }
    }
}
