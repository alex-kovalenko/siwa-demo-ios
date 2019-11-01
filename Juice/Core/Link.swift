//
//  Link.swift
//  Master
//
//  Created by Aleksandr Kovalenko on 10/31/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

enum Link {
    static func create(with code: Data, andBundleID bundleID: String) -> String {
        guard
            let codeString = String(data: code, encoding: .utf8),
            let requestURL = URL(string: "https://siwa-demo.com/link?code=\(codeString)&client_id=\(bundleID)")
        else {
            return "Unable to create request for code: \(code)"
        }

        do {
            let data = try Data(contentsOf: requestURL)
            return String(data: data, encoding: .utf8)!
        } catch {
            return "Unable to make a request due to an error: \(error)"
        }
    }
}
