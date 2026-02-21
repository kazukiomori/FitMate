//
//  ProfileSetupView.swift
//  FitMate
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var user: User
    @State private var animateCard = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                OnboardingHeader(
                    title: "まずは、ざっくりでOK",
                    subtitle: "迷ったら直感で。\nあとでいつでも変えられます。"
                )
                OnboardingHintPill(text: "ここは“正解”じゃなくて大丈夫")
                
                // 設定カード
                LazyVStack(spacing: 20) {
                    // 年齢設定
                    ModernSettingCard(
                        icon: "calendar",
                        title: "年齢",
                        value: "\(user.age)歳"
                    ) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("18歳")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                                Spacer()
                                Text("80歳")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(user.age) },
                                    set: { user.age = Int($0) }
                                ),
                                in: 18...80,
                                step: 1
                            )
                            .tint(AoiOnboardingTheme.accent)
                        }
                    }
                    
                    // 性別設定
                    ModernSettingCard(
                        icon: "person.2",
                        title: "性別",
                        value: user.gender.rawValue
                    ) {
                        Picker("性別", selection: $user.gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(AoiOnboardingTheme.accent)
                    }
                    
                    // 身長設定
                    ModernSettingCard(
                        icon: "ruler",
                        title: "身長",
                        value: "\(Int(user.height))cm"
                    ) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("140cm")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                                Spacer()
                                Text("200cm")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                            }
                            
                            Slider(value: $user.height, in: 140...200, step: 1)
                                .tint(AoiOnboardingTheme.accent)
                        }
                    }
                    
                    // 体重設定
                    ModernSettingCard(
                        icon: "scalemass",
                        title: "現在の体重",
                        value: String(format: "%.1fkg", user.currentWeight)
                    ) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("40kg")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                                Spacer()
                                Text("120kg")
                                    .font(.caption)
                                    .foregroundColor(AoiOnboardingTheme.textSecondary)
                            }
                            
                            Slider(value: $user.currentWeight, in: 40...120, step: 0.1)
                                .tint(AoiOnboardingTheme.accent)
                        }
                    }

                    // 活動レベル設定
                    ModernSettingCard(
                        icon: "figure.run",
                        title: "活動レベル",
                        value: user.activityLevel.rawValue
                    ) {
                        VStack(spacing: 12) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        user.activityLevel = level
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: user.activityLevel == level ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(user.activityLevel == level ? AoiOnboardingTheme.accent : AoiOnboardingTheme.textSecondary)
                                            .font(.title3)

                                        Text(level.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(AoiOnboardingTheme.textPrimary)

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .opacity(animateCard ? 1 : 0)
                .offset(y: animateCard ? 0 : 50)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateCard)
                
                Spacer(minLength: 100)
            }
            .onboardingPagePadding()
        }
        .onAppear {
            animateCard = true
        }
    }
}

struct ModernSettingCard<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    let content: Content
    
    @State private var isExpanded = false
    
    init(icon: String, title: String, value: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.value = value
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 15) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(AoiOnboardingTheme.accent)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(AoiOnboardingTheme.textPrimary)
                        Text(value)
                            .font(.subheadline)
                            .foregroundColor(AoiOnboardingTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AoiOnboardingTheme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(20)
            }
            
            // コンテンツ
            if isExpanded {
                VStack {
                    content
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AoiOnboardingTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AoiOnboardingTheme.border, lineWidth: 1)
                )
        )
        .shadow(color: AoiOnboardingTheme.shadow, radius: 12, x: 0, y: 6)
    }
}
