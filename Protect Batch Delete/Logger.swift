//
//  Logger.swift
//  Jamf Protect Batch Delete
//
//  Created by Richard Mallion on 23/02/2023.
//

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let protect = Logger(subsystem: subsystem, category: "protect")
    static let csv = Logger(subsystem: subsystem, category: "csv")
    static let general = Logger(subsystem: subsystem, category: "general")
}
