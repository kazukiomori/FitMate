import SwiftUI

struct TrainerProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let trainer: PersonalTrainer

    private let galleryImageNames = ["first", "second", "smile", "angry", "sad"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    imageGallerySection
                    profileContentSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(trainer.resolvedDisplayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                trainerPrimaryAvatar

                VStack(alignment: .leading, spacing: 8) {
                    Text(trainer.resolvedDisplayName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)

                    if let profile = trainer.profile {
                        Text(profile.name.reading)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        ProfileChip(text: trainer.resolvedAgeText, icon: "calendar")
                        ProfileChip(text: trainer.resolvedGenderText, icon: "person.fill")

                        if let profile = trainer.profile {
                            ProfileChip(text: "\(profile.heightCm)cm", icon: "ruler")
                            ProfileChip(text: "\(profile.weightKg)kg", icon: "scalemass")
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            if let summary = trainer.profile?.otherInfo.summary {
                ProfileSectionCard(title: "プロフィール概要", systemImage: "text.alignleft") {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                }
            }
        }
    }

    private var imageGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("トレーナー画像")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(galleryImageNames, id: \.self) { imageName in
                    TrainerProfileImageCard(
                        title: imageName,
                        image: trainer.profileImage(named: imageName)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var profileContentSection: some View {
        if let profile = trainer.profile {
            VStack(alignment: .leading, spacing: 16) {
                ProfileSectionCard(title: "基本情報", systemImage: "person.text.rectangle") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "名前", value: profile.name.full)
                        ProfileInfoRow(label: "読み", value: profile.name.reading)
                        ProfileInfoRow(label: "一人称", value: profile.firstPersonPronoun.default)
                        ProfileInfoRow(label: "一人称メモ", value: profile.firstPersonPronoun.casualNote)
                    }
                }

                ProfileSectionCard(title: "性格", systemImage: "heart.text.square") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(profile.personality.overview)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(5)

                        ForEach(Array(profile.personality.traits.enumerated()), id: \.offset) { _, trait in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trait.trait)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)

                                Text(trait.detail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }

                ProfileSectionCard(title: "対人スタイル", systemImage: "person.2") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "第一印象", value: profile.personality.interpersonalStyle.firstImpression)
                        ProfileInfoRow(label: "仲良くなると", value: profile.personality.interpersonalStyle.afterGettingClose)
                        ProfileInfoRow(label: "信頼した相手に", value: profile.personality.interpersonalStyle.withTrustedPerson)
                        ProfileInfoRow(label: "恋愛時", value: profile.personality.interpersonalStyle.whenInLove)
                    }
                }

                ProfileSectionCard(title: "感情の癖", systemImage: "sparkles") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "怒った時", value: profile.personality.emotionalHabits.whenAngry)
                        ProfileInfoRow(label: "悲しい時", value: profile.personality.emotionalHabits.whenSad)
                        ProfileInfoRow(label: "嬉しい時", value: profile.personality.emotionalHabits.whenHappy)
                        ProfileInfoRow(label: "照れた時", value: profile.personality.emotionalHabits.whenEmbarrassed)
                        ProfileInfoRow(label: "感情の核", value: profile.personality.coreEmotionalHook)
                    }
                }

                ProfileSectionCard(title: "好きなもの", systemImage: "hand.thumbsup") {
                    ProfileTagList(items: profile.likes)
                }

                ProfileSectionCard(title: "苦手なもの", systemImage: "hand.thumbsdown") {
                    ProfileTagList(items: profile.dislikes)
                }

                ProfileSectionCard(title: "外見", systemImage: "camera.macro") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "髪", value: profile.appearance.hair)
                        ProfileInfoRow(label: "目", value: profile.appearance.eyes)
                        ProfileInfoRow(label: "顔", value: profile.appearance.face)
                        ProfileInfoRow(label: "肌", value: profile.appearance.skin)
                        ProfileInfoRow(label: "体型", value: profile.appearance.body)
                        ProfileInfoRow(label: "姿勢", value: profile.appearance.posture)
                        ProfileInfoRow(label: "ファッション", value: profile.appearance.fashion)
                        ProfileInfoRow(label: "香り", value: profile.appearance.fragrance)
                    }
                }

                ProfileSectionCard(title: "背景", systemImage: "book.closed") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "幼少期", value: profile.otherInfo.background.childhood)
                        ProfileInfoRow(label: "転機", value: profile.otherInfo.background.turningPoint)
                        ProfileInfoRow(label: "成長", value: profile.otherInfo.background.growth)
                    }
                }

                ProfileSectionCard(title: "仕事観", systemImage: "briefcase") {
                    ProfileTagList(items: profile.otherInfo.workValues)
                }

                ProfileSectionCard(title: "恋愛傾向", systemImage: "heart") {
                    ProfileTagList(items: profile.otherInfo.romanceTendency)
                }

                ProfileSectionCard(title: "話し方", systemImage: "bubble.left.and.bubble.right") {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileInfoRow(label: "基本", value: profile.otherInfo.speechStyle.default)
                        ProfileInfoRow(label: "親しい時", value: profile.otherInfo.speechStyle.casual)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("励まし例")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            ForEach(profile.otherInfo.speechStyle.encouragingExamples, id: \.self) { example in
                                Text("・\(example)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }

                ProfileSectionCard(title: "弱み", systemImage: "exclamationmark.triangle") {
                    ProfileTagList(items: profile.otherInfo.weaknesses)
                }

                ProfileSectionCard(title: "ユーザーとの関係性", systemImage: "person.2.wave.2") {
                    Text(profile.otherInfo.userRelationshipConcept)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                }
            }
        } else {
            ProfileSectionCard(title: "プロフィール情報", systemImage: "info.circle") {
                VStack(alignment: .leading, spacing: 10) {
                    ProfileInfoRow(label: "名前", value: trainer.resolvedDisplayName)
                    ProfileInfoRow(label: "年齢", value: trainer.resolvedAgeText)
                    ProfileInfoRow(label: "性別", value: trainer.resolvedGenderText)
                    ProfileInfoRow(label: "性格", value: trainer.preferences.personality.rawValue)
                    ProfileInfoRow(label: "スタイル", value: trainer.preferences.style.rawValue)
                    ProfileInfoRow(label: "専門", value: trainer.preferences.specialization.rawValue)

                    Text("このトレーナーの詳細JSONプロフィールはまだ登録されていません。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var trainerPrimaryAvatar: some View {
        if let image = trainer.profileImage(named: "smile") ?? trainer.profileImage(named: "first") {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        } else {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 88, height: 88)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.gray)
                )
        }
    }
}

private struct TrainerProfileImageCard: View {
    let title: String
    let image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("画像なし")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct ProfileSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProfileInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
    }
}

private struct ProfileTagList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text("・\(item)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileChip: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.blue.opacity(0.10), in: Capsule())
    }
}
