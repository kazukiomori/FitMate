import Foundation

struct TrainerProfileCatalogEntry: Decodable {
    let id: String
    let profile: TrainerProfile?
}

struct TrainerProfile: Decodable {
    let name: TrainerProfileName
    let age: Int
    let heightCm: Int
    let weightKg: Int
    let firstPersonPronoun: TrainerProfileFirstPersonPronoun
    let likes: [String]
    let dislikes: [String]
    let personality: TrainerProfilePersonality
    let appearance: TrainerProfileAppearance
    let otherInfo: TrainerProfileOtherInfo
}

struct TrainerProfileName: Decodable {
    let full: String
    let reading: String
}

struct TrainerProfileFirstPersonPronoun: Decodable {
    let `default`: String
    let casualNote: String
}

struct TrainerProfilePersonality: Decodable {
    let overview: String
    let traits: [TrainerProfileTrait]
    let interpersonalStyle: TrainerProfileInterpersonalStyle
    let emotionalHabits: TrainerProfileEmotionalHabits
    let coreEmotionalHook: String
}

struct TrainerProfileTrait: Decodable {
    let trait: String
    let detail: String
}

struct TrainerProfileInterpersonalStyle: Decodable {
    let firstImpression: String
    let afterGettingClose: String
    let withTrustedPerson: String
    let whenInLove: String
}

struct TrainerProfileEmotionalHabits: Decodable {
    let whenAngry: String
    let whenSad: String
    let whenHappy: String
    let whenEmbarrassed: String
}

struct TrainerProfileAppearance: Decodable {
    let hair: String
    let eyes: String
    let face: String
    let skin: String
    let body: String
    let posture: String
    let fashion: String
    let fragrance: String
}

struct TrainerProfileOtherInfo: Decodable {
    let background: TrainerProfileBackground
    let workValues: [String]
    let romanceTendency: [String]
    let speechStyle: TrainerProfileSpeechStyle
    let weaknesses: [String]
    let userRelationshipConcept: String
    let summary: String
}

struct TrainerProfileBackground: Decodable {
    let childhood: String
    let turningPoint: String
    let growth: String
}

struct TrainerProfileSpeechStyle: Decodable {
    let `default`: String
    let casual: String
    let encouragingExamples: [String]
}

enum TrainerProfileCatalog {
    private static let resourceName = "trainer_profiles"

    static func profile(for trainerID: String, in bundle: Bundle = .main) -> TrainerProfile? {
        loadCatalog(in: bundle)[trainerID] ?? nil
    }

    static func loadCatalog(in bundle: Bundle = .main) -> [String: TrainerProfile?] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let entries = try? decoder.decode([TrainerProfileCatalogEntry].self, from: data) {
            return Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0.profile) })
        }

        guard let rawEntries = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
            return [:]
        }

        var catalog: [String: TrainerProfile?] = [:]

        for rawEntry in rawEntries {
            guard let id = rawEntry["id"] as? String else { continue }

            guard let entryData = try? JSONSerialization.data(withJSONObject: rawEntry),
                  let entry = try? decoder.decode(TrainerProfileCatalogEntry.self, from: entryData) else {
                catalog[id] = nil
                continue
            }

            catalog[entry.id] = entry.profile
        }

        return catalog
    }
}

extension PersonalTrainer {
    var profile: TrainerProfile? {
        guard let assetNamespace else { return nil }
        return TrainerProfileCatalog.profile(for: assetNamespace)
    }
}
