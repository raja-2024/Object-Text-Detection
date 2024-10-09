//
//  BOOCRValidation.swift
//
//
//  Created by Raja on 25/09/23.
//

import Foundation

/// OCR Validation
class BOOCRValidation {

    /// To check whether card number is in valid format.
    /// - Parameters : number on which validation would be done.
    /// - Returns : whether card number is in valid format.
    class func isValidCardNumber(_ number: String) -> Bool {
        return number.count > 14 && number.count <= 19 && isNumeric(number)
    }

    /// To check whether string is in number format only.
    /// - Parameters : number on which validation would be done.
    /// - Returns : whether string contains only number.
    class func isNumeric(_ number: String) -> Bool {
        let digits = number.filter({!$0.isWhitespace})
        return !(digits.isEmpty) && digits.allSatisfy { $0.isNumber }
    }

    /// To check whether string is in in valid name format.
    /// - Parameters : number on which validation would be done.
    /// - Returns : whether string has in proper name format.
    class func isValidName(_ name: String) -> Bool {
        let regex = "[A-Za-z. ]+"
        let test = NSPredicate(format:"SELF MATCHES %@",  regex)
        let regexResult = test.evaluate(with: name)
        // Check name not start with small case
        let firstCharCapital = name.first?.isUppercase ?? false
        return regexResult && firstCharCapital
    }
}
