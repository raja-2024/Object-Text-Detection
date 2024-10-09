//
//  BOPaymentParser.swift
//
//
//  Created by Raja on 25/09/23.
//

import Foundation

protocol BOImageParser {
    init(detectedTexts: [String])
    var parsedData: [String: Any] {get}
}

/// This will doing OCR validation and generate actual information of the card.
class BOPaymentParser: BOImageParser {

    private let detectedTexts: [String]

    required init(detectedTexts: [String]) {
        debugPrint("\(BOScanLogs.logPrefix) detectedTexts \(detectedTexts)")
        self.detectedTexts = detectedTexts
    }

    /// This will remove speical characters, white space and any punctuation from strings.
    private lazy var trimmedTexts: [String] = {
        let texts = detectedTexts
        let punctuationRemoved = texts.map({$0.trimmingCharacters(in: .punctuationCharacters)})
        let symbolsRemoved = punctuationRemoved.map({$0.trimmingCharacters(in: .symbols)})
        let whiteSpacesRemoved = symbolsRemoved.map({$0.trimmingCharacters(in: .whitespaces)})
        return whiteSpacesRemoved
    }()

    /// - Returns: Return **Card number** , in case of failure it will return blank value.
    private lazy var cardNumber: String = {
        var numbers = trimmedTexts.map({$0.replaceOuccring(of: cardNumberManupulationMap).removeWhitespace()})
        var result = numbers.filter({ BOOCRValidation.isValidCardNumber($0)})
        var digits = result.isEmpty ? numbers.filter({ BOOCRValidation.isNumeric($0)}).joined() : result.joined()
        /// Removing duplicate occurance
        digits = BOOCRValidation.isValidCardNumber(digits) ? digits : digits.split(of: 4).uniqued().joined()
        digits = String(digits.prefix(19)) // Picking first 19 if exist
        if isAmericanExpressCard {
            let memberSinceYear = trimmedTexts.map({$0.removeWhitespace()}).filter({$0.count == 2 && Int($0) != nil }).first
            if let memberSinceYear = memberSinceYear {
                let americanCardNumber = digits.replacingOccurrences(of: memberSinceYear, with: "")
                return americanCardNumber
            }
            return digits
        } else {
            return digits
        }
    }()

    /// - Returns: Return **Card holder name** , in case of failure it will return blank value.
    private lazy var name: String = {
        let wordsToAvoid = [cardNumber, expiryDate]
        let result = trimmedTexts.filter({
            let isIgnorableText = $0.contains(in: ignoreList)
            return !isIgnorableText && !wordsToAvoid.contains($0) && BOOCRValidation.isValidName($0)
        })
        debugPrint("\(BOScanLogs.logPrefix) Detected Name list : \(result)")
        return result.last ?? ""
    }()

    /// - Returns: Return **Card Expiry date** , in case of failure it will return blank value.
    private lazy var expiryDate: String = {
        let result = trimmedTexts.filter({$0.count > 4 && $0.contains("/")}).map({$0.removeWhitespace()})
        let dateString = result.last
        if let dateString = dateString, let range = dateString.range(of: "/") {
            let slashIndex = dateString.distance(from: dateString.startIndex, to: range.lowerBound)
            let month = dateString.substring(from: slashIndex - 2, to: slashIndex - 1)
            let year = dateString.substring(from: slashIndex + 1, to: slashIndex + 2)
            let isvalidMonth = BOOCRValidation.isNumeric(month)
            let isvalidYear = BOOCRValidation.isNumeric(year)
            let expiryDate = dateString.substring(from: slashIndex - 2, to: slashIndex + 2)
            return isvalidMonth && isvalidYear ? "\(month)/\(year)" : ""
        } else {
            return ""
        }
    }()

    /// Check whether card is of America express or not
    private var isAmericanExpressCard: Bool {
        let americanCardIgnoreList = ["AMERICAN", "EXPRESS", "AmericanExpress", "American Express"]
        let result = trimmedTexts.filter({
            return $0.lowercased().contains(in: americanCardIgnoreList.map({$0.lowercased()}))
        })
        return !result.isEmpty
    }

    var parsedData: [String: Any] {
        var result = [String: String]()
        result["cardNumber"] = cardNumber.split(of: 4).joined(separator: " ")
        result["name"] = name
        result["expiryDate"] = expiryDate
        return result
    }
}

extension BOPaymentParser {

    var ignoreList: [String] {
        return ["VISA", "MasterCard", "Amex", "AMERICAN", "EXPRESS", "Slice",
                "Platinum", "Gold", "Credit", "Debit", "Card", "Bank", "Pay",
                "Month", "Year", "Master", "Maestro", "Expresss", "AmericanExpress",
                "Amazon", "Amazon Pay", "Amazonpay", "Bank of america", "Chase",
                "Wells Fargo", "Capital One", "Citi", "Citibank", "Discover", "Synchrony",
                "U.S. Bank", "Rewards", "Gold", "Advantage", "DBS", "Standard Chartered",
                "Deutche", "Security", "BLACK EDITION", "MM", "YY", "Valid", "Thru", "Signature",
                "Coral", "Rupay", "Date", "Code", "Security", "SBI", "SBI Card", "SimplySave",
                "SimplyClick", "LEAGUE", "ICICI", "ICICI Bank", "Synchrony", "Discover it® Cash Back",
                "Sam's Club Mastercard", "Sam's Club", "U.S. Bank", "U.S. Bank Visa® Platinum Card",
                "U.S. Bank Visa", "Wells Fargo", "Wells Fargo Reflect", "Wells Fargo Reflect Card",
                "Bank of America", "Barclays", "Capital One", "Navy FCU", "USSA", "Goldman Sachs", "PNC Bank",
                "Credit One Bank", "TD Bank", "First National", "From", "Octane", "CRN", "Corporate",
                "Kotak", "Kotak Mahindra Bank", "J.P. Morgan", "J P Morgan", "JP Morgan"]
    }

    var cardNumberManupulationMap: [String: String] {
        [
            "b" : "6",
            "B" : "8",
            "e" : "2",
            "I" : "1",
            "l" : "1",
            "L" : "1",
            "J" : "1",
            "j" : "1",
            "g" : "9",
            "D" : "0",
            "S" : "5",
            "s" : "5",
            "T" : "7",
            "O" : "0",
            "o" : "0",
            "q" : "9",
            "Q" : "0"
        ]
    }
}
