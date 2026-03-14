import UIKit
import Foundation

struct GeneratedAvatarCandidate: Identifiable, Hashable {
    let id: String
    let image: UIImage
}

@MainActor
final class TrainerAvatarGenerationService {
    func generateCandidates(preferences: TrainerPreferences, count: Int = 6) async -> (generationId: String, candidates: [GeneratedAvatarCandidate]) {
        let spec = TrainerAvatarSpec(preferences: preferences)

        do {
            let response = try await TrainerAvatarAPI.fetchCandidates(spec: spec, count: count)
            let decoded: [GeneratedAvatarCandidate] = response.candidates.compactMap { candidate in
                if let base64 = candidate.image_base64,
                   let data = Data(base64Encoded: base64),
                   let image = UIImage(data: data) {
                    return GeneratedAvatarCandidate(id: candidate.id, image: image)
                }

                if let urlString = candidate.image_url,
                   let url = URL(string: urlString),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    return GeneratedAvatarCandidate(id: candidate.id, image: image)
                }

                return nil
            }

            if decoded.isEmpty {
                return (generationId: response.generation_id, candidates: demoCandidates(count: count, preferences: preferences))
            }

            return (generationId: response.generation_id, candidates: decoded)
        } catch {
            // エンドポイント未実装/ネットワーク不調時も UI を進められるようデモ候補を返す
            return (generationId: UUID().uuidString, candidates: demoCandidates(count: count, preferences: preferences))
        }
    }

    func finalize(generationId: String, selectedCandidateId: String, preferences: TrainerPreferences) async -> UIImage {
        let spec = TrainerAvatarSpec(preferences: preferences)

        do {
            let response = try await TrainerAvatarAPI.finalize(
                generationId: generationId,
                selectedCandidateId: selectedCandidateId,
                spec: spec
            )

            if let base64 = response.image_base64,
               let data = Data(base64Encoded: base64),
               let image = UIImage(data: data) {
                return image
            }

            if let urlString = response.image_url,
               let url = URL(string: urlString),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return image
            }

            return demoFinal(preferences: preferences)
        } catch {
            return demoFinal(preferences: preferences)
        }
    }

    private func demoCandidates(count: Int, preferences: TrainerPreferences) -> [GeneratedAvatarCandidate] {
        (0..<count).map { idx in
            let id = "demo-\(idx)"
            return GeneratedAvatarCandidate(id: id, image: createDemoAvatar(index: idx, preferences: preferences))
        }
    }

    private func demoFinal(preferences: TrainerPreferences) -> UIImage {
        createDemoAvatar(index: 99, preferences: preferences)
    }

    private func createDemoAvatar(index: Int, preferences: TrainerPreferences) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        let bg: UIColor = {
            switch preferences.personality {
            case .motivational: return UIColor.systemOrange
            case .supportive: return UIColor.systemTeal
            case .strict: return UIColor.systemIndigo
            case .encouraging: return UIColor.systemPink
            }
        }()

        return renderer.image { ctx in
            bg.withAlphaComponent(0.18).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // シンプルなシルエット＋テキスト（デモ用）
            UIColor.white.setFill()
            let circleRect = CGRect(x: 96, y: 80, width: 320, height: 320)
            ctx.cgContext.fillEllipse(in: circleRect)

            let label = "Trainer \(index)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let textSize = (label as NSString).size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height - textSize.height - 54,
                width: textSize.width,
                height: textSize.height
            )
            (label as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
}
