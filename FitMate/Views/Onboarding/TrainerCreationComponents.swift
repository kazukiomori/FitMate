import SwiftUI

struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FlexibleTagLayout<Data: View>: View {
    let spacing: CGFloat
    let runSpacing: CGFloat
    @ViewBuilder let content: Data

    init(
        spacing: CGFloat = 8,
        runSpacing: CGFloat = 8,
        @ViewBuilder content: () -> Data
    ) {
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            flowLayout
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    content
                }
            }
        }
    }

    private var flowLayout: some View {
        _FlowLayout(spacing: spacing, runSpacing: runSpacing) {
            content
        }
    }
}

struct _FlowLayout: Layout {
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8

    func makeCache(subviews: Subviews) -> [CGSize] {
        subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func updateCache(_ cache: inout [CGSize], subviews: Subviews) {
        cache = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width - 40
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in cache {
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + runSpacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for index in subviews.indices {
            let size = cache[index]

            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + runSpacing
                rowHeight = 0
            }

            subviews[index].place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
