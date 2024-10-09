//
//  BOImageReader.swift
//
//
//  Created by Raja on 27/09/23.
//

import UIKit

public enum BOImageReaderType {
    case creditCard
}

/// It will helps to fetch card information from card image.
/*
 ```
 #code
 let imageReader = BOImageReader(readerType: .creditCard)
 imageReader.readInformation(of: someCreidtCardImage) { result in
 switch result {
 case .success:
 /// You will get JSON of readed data
 case .failure:
 /// Any error while reading information from card.
 }
 }
 ```
 */

struct BOScanLogs {
    static let logPrefix = "[***BOScan***] -- "
}

public class BOImageReader {

    private lazy var textDetector: BOTextDetection = {
        return BOTextDetector()
    }()

    private let readerType: BOImageReaderType!

    /// - Parameters readerType: Type of the image
    public init(readerType: BOImageReaderType = .creditCard) {
        self.readerType = readerType
    }

    /// It will read all the texts on given image and send callback of required type of information in JSON format.
    /// - Parameter : image - on which information have to get.
    public func readInformation(of image: UIImage, info: @escaping (Result<[String: Any], Error>) -> Void ) {
        textDetector.detectText(uiImage: image) { result, error in
            if let error = error {
                info(.failure(error))
            } else {
                let texts = result.map({$0.text})
                let obj = self.parseInformation(texts: texts)
                info(.success(obj.parsedData))
            }
        }
    }

    /// It will read all the texts on given image and send callback of all information in JSON format.
    /// - Parameter : image - on which information have to get.
    public func readRawData(of image: UIImage, info: @escaping (Result<[BORecognizedText], Error>) -> Void ) {
        textDetector.detectText(uiImage: image) { result, error in
            if let error = error {
                info(.failure(error))
            } else {
                info(.success(result))
            }
        }
    }

    /// - Parameters: texts that has to be parsed and converted into dict format.
    /// - Returns parser object with parsed data.
    private func parseInformation(texts: [String]) -> BOImageParser {
        switch readerType {
        case .creditCard:
            return BOPaymentParser(detectedTexts: texts)
        case .none:
            return BOPaymentParser(detectedTexts: texts)
        }
    }
}
