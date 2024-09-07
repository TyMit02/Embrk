class MiscellaneousVerificationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var verifications: [String: [MiscellaneousVerification]] = [:]
    private var locationManager: CLLocationManager?
    private var locationCompletion: ((Bool, Error?) -> Void)?
    private var currentLocationEvidence: String?
    private var currentChallenge: Challenge?
    private var currentUserId: String?
    
    struct MiscellaneousVerification: Identifiable, Codable {
        let id: String
        let challengeId: String
        let userId: String
        let date: Date
        let verificationMethod: VerificationMethod
        let evidence: String?
        var isVerified: Bool
    }
    
    enum VerificationMethod: String, Codable, CaseIterable {
        case photo = "Photo"
        case textInput = "Text Input"
        case checkbox = "Checkbox"
        case numericInput = "Numeric Input"
        case locationCheck = "Location Check"
        case timerBased = "Timer Based"
        case socialMediaPost = "Social Media Post"
        case fileUpload = "File Upload"
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    func verifyChallenge(_ challenge: Challenge, userId: String, method: VerificationMethod, evidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        switch method {
        case .photo:
            verifyWithPhoto(challenge, userId: userId, photoEvidence: evidence, completion: completion)
        case .textInput:
            verifyWithTextInput(challenge, userId: userId, textEvidence: evidence, completion: completion)
        case .checkbox:
            verifyWithCheckbox(challenge, userId: userId, completion: completion)
        case .numericInput:
            verifyWithNumericInput(challenge, userId: userId, numericEvidence: evidence, completion: completion)
        case .locationCheck:
            verifyWithLocationCheck(challenge, userId: userId, locationEvidence: evidence, completion: completion)
        case .timerBased:
            verifyWithTimer(challenge, userId: userId, timerEvidence: evidence, completion: completion)
        case .socialMediaPost:
            verifyWithSocialMediaPost(challenge, userId: userId, postEvidence: evidence, completion: completion)
        case .fileUpload:
            verifyWithFileUpload(challenge, userId: userId, fileEvidence: evidence, completion: completion)
        }
    }
    
    private func verifyWithPhoto(_ challenge: Challenge, userId: String, photoEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        let isVerified = photoEvidence != nil
        addVerification(for: challenge, userId: userId, method: .photo, evidence: photoEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    private func verifyWithTextInput(_ challenge: Challenge, userId: String, textEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        let isVerified = !(textEvidence?.isEmpty ?? true)
        addVerification(for: challenge, userId: userId, method: .textInput, evidence: textEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    private func verifyWithCheckbox(_ challenge: Challenge, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        addVerification(for: challenge, userId: userId, method: .checkbox, evidence: "checked", isVerified: true)
        completion(true, nil)
    }
    
    private func verifyWithNumericInput(_ challenge: Challenge, userId: String, numericEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard let numericValue = Double(numericEvidence ?? "") else {
            completion(false, NSError(domain: "com.yourapp", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid numeric input"]))
            return
        }
        
        let isVerified = challenge.verificationGoal != nil ? numericValue >= challenge.verificationGoal! : true
        addVerification(for: challenge, userId: userId, method: .numericInput, evidence: numericEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    private func verifyWithLocationCheck(_ challenge: Challenge, userId: String, locationEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(false, NSError(domain: "com.yourapp", code: 4, userInfo: [NSLocalizedDescriptionKey: "Location services are disabled"]))
            return
        }
        
        locationManager?.requestWhenInUseAuthorization()
        
        self.currentLocationEvidence = locationEvidence
        self.currentChallenge = challenge
        self.currentUserId = userId
        self.locationCompletion = completion
        
        locationManager?.requestLocation()
    }
    
    private func verifyWithTimer(_ challenge: Challenge, userId: String, timerEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard let duration = Double(timerEvidence ?? "") else {
            completion(false, NSError(domain: "com.yourapp", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid timer duration"]))
            return
        }
        
        let isVerified = challenge.verificationGoal != nil ? duration >= challenge.verificationGoal! : true
        addVerification(for: challenge, userId: userId, method: .timerBased, evidence: timerEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    private func verifyWithSocialMediaPost(_ challenge: Challenge, userId: String, postEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        let isVerified = !(postEvidence?.isEmpty ?? true)
        addVerification(for: challenge, userId: userId, method: .socialMediaPost, evidence: postEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    private func verifyWithFileUpload(_ challenge: Challenge, userId: String, fileEvidence: String?, completion: @escaping (Bool, Error?) -> Void) {
        let isVerified = fileEvidence != nil
        addVerification(for: challenge, userId: userId, method: .fileUpload, evidence: fileEvidence, isVerified: isVerified)
        completion(isVerified, nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let challengeLocation = CLLocationCoordinate2D(latLongString: currentLocationEvidence),
              let challenge = currentChallenge,
              let userId = currentUserId else {
            locationCompletion?(false, NSError(domain: "com.yourapp", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid location data"]))
            return
        }
        
        let distance = location.distance(from: CLLocation(latitude: challengeLocation.latitude, longitude: challengeLocation.longitude))
        let isWithinRange = distance <= 100 // Within 100 meters
        
        addVerification(for: challenge, userId: userId, method: .locationCheck, evidence: currentLocationEvidence, isVerified: isWithinRange)
        
        locationCompletion?(isWithinRange, nil)
        locationCompletion = nil
        currentLocationEvidence = nil
        currentChallenge = nil
        currentUserId = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(false, error)
        locationCompletion = nil
        currentLocationEvidence = nil
        currentChallenge = nil
        currentUserId = nil
    }
    
    private func addVerification(for challenge: Challenge, userId: String, method: VerificationMethod, evidence: String?, isVerified: Bool) {
        let verification = MiscellaneousVerification(
            id: UUID().uuidString,
            challengeId: challenge.id ?? "",
            userId: userId,
            date: Date(),
            verificationMethod: method,
            evidence: evidence,
            isVerified: isVerified
        )
        
        if verifications[challenge.id ?? ""] != nil {
            verifications[challenge.id ?? ""]?.append(verification)
        } else {
            verifications[challenge.id ?? ""] = [verification]
        }
    }
    
    func getVerifications(for challengeId: String) -> [MiscellaneousVerification] {
        return verifications[challengeId] ?? []
    }
    
    func getTotalProgress(for challengeId: String, userId: String) -> Int {
        return getVerifications(for: challengeId)
            .filter { $0.userId == userId && $0.isVerified }
            .count
    }
}

extension CLLocationCoordinate2D {
    init?(latLongString: String?) {
        guard let latLongString = latLongString else { return nil }
        let components = latLongString.components(separatedBy: ",")
        guard components.count == 2,
              let latitude = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        self.init(latitude: latitude, longitude: longitude)
    }
}
