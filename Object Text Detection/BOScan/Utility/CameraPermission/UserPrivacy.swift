//
//  UserPrivacy.swift
//
//
//  Created by Raja on 17/07/23.
//

import Foundation
import AVFoundation

public class UserPrivacy {

    // It's True when User Denied the permission
    public static var firstTimeDenied = false
    /**
     To check user allowed to use their personal data. At very first time it opens an alert for granting permission.
        - Returns: Completion Handler with acces permission allowed or not.
     */

    public class func allowedToRetrieveData(from type: DataPrivacy, completionHandler: @escaping ((Bool) -> Void)) {

        let resultHandler: ((Bool) -> Void) = { value in
            DispatchQueue.main.async {
                completionHandler(value)
            }
        }

        /**
         To show iOS permission alert to accept or reject of specific data.
            - Returns: Completion Handler with acces permission allowed or not.
         */
        func deterMinedAction(_ completionHandler: @escaping ((Bool) -> Void)) {
            if type == .camera {
                AVCaptureDevice.requestAccess(for: .video) { result in
                    resultHandler(result)
                }
            } else {
                resultHandler(false)
            }
        }

        /**
         Check the status of current permission of privacy types.
            - Returns: Completion Handler with acces permission allowed or not.
         */
        func checkPrivacy(status: AuthorizationStatus, _ completionHandler: @escaping ((Bool) -> Void)) {
            firstTimeDenied = false
            switch status {
            case .limited:
                resultHandler(true)
            case .authorized:
                resultHandler(true)
            case .notDetermined:
                firstTimeDenied = true
                deterMinedAction(resultHandler)
            case .denied:
                resultHandler(false)
            case .restricted:
                resultHandler(false)
            }
        }

        var status: AuthorizationStatus!

        /**
         Check the status of current permission of privacy types.
         */
        switch type {
        case .camera:
            let value = AVCaptureDevice.authorizationStatus(for: .video).rawValue
            status = AuthorizationStatus(rawValue: value) ?? .denied
        }

        /**
         Check permission allowed to use feature.
         */
        checkPrivacy(status: status) { (result) in
            resultHandler(result)
        }
    }

}

public extension UserPrivacy {

    /** Privacy type from which user can acces specific hardware or content of device.*/
    enum DataPrivacy {
        case camera
    }

    /** Types of authorization */
    fileprivate enum AuthorizationStatus: Int {
        case notDetermined = 0
        case restricted
        case denied
        case authorized
        case limited
    }
}
