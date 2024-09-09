import os.log

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    static let auth = os.Logger(subsystem: subsystem, category: "Authentication")
    static let network = os.Logger(subsystem: subsystem, category: "Network")
    static let database = os.Logger(subsystem: subsystem, category: "Database")
}