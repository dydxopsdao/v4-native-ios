import Foundation

internal func getFailedEventStorageKey(_ sdkKey: String) -> String {
    return "\(EventLogger.failedLogsKey):\(sdkKey.djb2())"
}

class EventLogger {
    internal static let failedLogsKey = "com.Statsig.EventLogger.loggingRequestUserDefaultsKey"

    private static let eventQueueLabel = "com.Statsig.eventQueue"
    private static let nonExposedChecksEvent = "non_exposed_checks"

    let networkService: NetworkService
    let userDefaults: DefaultsLike

    let logQueue = DispatchQueue(label: eventQueueLabel, qos: .userInitiated)
    let failedRequestLock = NSLock()
    let storageKey: String

    var maxEventQueueSize: Int = 50
    var events: [Event]
    var failedRequestQueue: [Data]
    var loggedErrorMessage: Set<String>
    var flushTimer: Timer?
    var user: StatsigUser
    var nonExposedChecks: [String: Int]

#if os(tvOS)
    let MAX_SAVED_LOG_REQUEST_SIZE = 100_000 //100 KB
#else
    let MAX_SAVED_LOG_REQUEST_SIZE = 1_000_000 //1 MB
#endif

    init(
        sdkKey: String,
        user: StatsigUser,
        networkService: NetworkService,
        userDefaults: DefaultsLike = StatsigUserDefaults.defaults
    ) {
        self.events = [Event]()
        self.failedRequestQueue = [Data]()
        self.user = user
        self.networkService = networkService
        self.loggedErrorMessage = Set<String>()
        self.userDefaults = userDefaults
        self.storageKey = getFailedEventStorageKey(sdkKey)
        self.nonExposedChecks = [String: Int]()

        if let failedRequestsCache = userDefaults.array(forKey: storageKey) as? [Data], !failedRequestsCache.isEmpty {
            userDefaults.removeObject(forKey: storageKey)
            
            networkService.sendRequestsWithData(failedRequestsCache) { [weak self] failedRequestsData in
                guard let failedRequestsData = failedRequestsData else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.addFailedLogRequest(failedRequestsData)
                    self?.saveFailedLogRequestsToDisk()
                }
            }
        }
    }

    func log(_ event: Event) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            self.events.append(event)

            if (self.events.count >= self.maxEventQueueSize) {
                self.flush()
            }
        }
    }

    func start(flushInterval: TimeInterval = 60) {
        DispatchQueue.main.async { [weak self] in
            self?.flushTimer?.invalidate()
            self?.flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    func stop() {
        flushTimer?.invalidate()
        logQueue.sync {
            self.addNonExposedChecksEvent()
            self.flushInternal(isShuttingDown: true)
        }
    }

    func flush() {
        logQueue.async { [weak self] in
            self?.addNonExposedChecksEvent()
            self?.flushInternal()
        }
    }

    private func flushInternal(isShuttingDown: Bool = false) {
        if events.isEmpty {
            return
        }

        let oldEvents = events
        events = []

        let capturedSelf = isShuttingDown ? self : nil
        networkService.sendEvents(forUser: user, events: oldEvents) {
            [weak self, capturedSelf] errorMessage, requestData in
            guard let self = self ?? capturedSelf else { return }

            if errorMessage == nil {
                return
            }

            self.addSingleFailedLogRequest(requestData)
            self.saveFailedLogRequestsToDisk()

            if let errorMessage = errorMessage, !self.loggedErrorMessage.contains(errorMessage) {
                self.loggedErrorMessage.insert(errorMessage)
                self.log(Event.statsigInternalEvent(
                    user: self.user,
                    name: "log_event_failed",
                    value: nil,
                    metadata: ["error": errorMessage])
                )
            }
        }
    }

    func incrementNonExposedCheck(_ configName: String) {
        logQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            let count = self.nonExposedChecks[configName] ?? 0
            self.nonExposedChecks[configName] = count + 1
        }
    }

    func addNonExposedChecksEvent() {
        if (self.nonExposedChecks.isEmpty) {
            return
        }

        guard JSONSerialization.isValidJSONObject(nonExposedChecks),
              let data = try? JSONSerialization.data(withJSONObject: nonExposedChecks),
              let json = String(data: data, encoding: .ascii)
        else {
            self.nonExposedChecks = [String: Int]()
            return
        }

        let event = Event.statsigInternalEvent(
            user: nil,
            name: EventLogger.nonExposedChecksEvent,
            value: nil,
            metadata: [
                "checks": json
            ]
        )
        self.events.append(event)
        self.nonExposedChecks = [String: Int]()
    }

    private func addSingleFailedLogRequest(_ requestData: Data?) {
        guard let data = requestData else { return }

        addFailedLogRequest([data])
    }

    internal func addFailedLogRequest(_ requestData: [Data]) {
        failedRequestLock.lock()
        defer { failedRequestLock.unlock() }

        failedRequestQueue += requestData

        while (failedRequestQueue.count > 0
               && failedRequestQueue.reduce(0,{ $0 + $1.count }) > MAX_SAVED_LOG_REQUEST_SIZE) {
            failedRequestQueue.removeFirst()
        }
    }

    internal func saveFailedLogRequestsToDisk() {
        guard Thread.isMainThread else {
            // `self` is strongly captured to ensure we save to disk
            DispatchQueue.main.async { [self] in
                self.saveFailedLogRequestsToDisk()
            }
            return
        }

        failedRequestLock.lock()
        defer { failedRequestLock.unlock() }

        userDefaults.setValue(
            failedRequestQueue,
            forKey: storageKey
        )
    }

    static func deleteLocalStorage(sdkKey: String) {
        StatsigUserDefaults.defaults.removeObject(forKey: getFailedEventStorageKey(sdkKey))
    }
}
