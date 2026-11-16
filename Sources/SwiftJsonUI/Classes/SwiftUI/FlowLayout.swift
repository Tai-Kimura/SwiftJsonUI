import SwiftUI

@available(iOS 16.0, *)
public struct FlowLayout: Layout {
    public var alignment: HorizontalAlignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(alignment: HorizontalAlignment = .leading, horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    // MARK: - Cache

    public struct CacheData {
        var rows: [Row] = []
        var proposalWidth: CGFloat?
        var subviewCount: Int = 0
    }

    public func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }

    // MARK: - Layout

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let rows = cachedRows(proposal: proposal, subviews: subviews, cache: &cache)
        guard !rows.isEmpty else { return .zero }

        let height = rows.reduce(CGFloat(0)) { sum, row in
            sum + row.height
        } + CGFloat(rows.count - 1) * verticalSpacing

        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        let rows = cachedRows(proposal: proposal, subviews: subviews, cache: &cache)
        var y = bounds.minY

        for row in rows {
            let xOffset: CGFloat
            switch alignment {
            case .center:
                xOffset = (bounds.width - row.width) / 2
            case .trailing:
                xOffset = bounds.width - row.width
            default:
                xOffset = 0
            }

            var x = bounds.minX + xOffset
            for item in row.items {
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    // MARK: - Internal

    struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Return cached rows if proposal width and subview count haven't changed.
    private func cachedRows(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> [Row] {
        let proposalWidth = proposal.width
        if cache.proposalWidth == proposalWidth && cache.subviewCount == subviews.count && !cache.rows.isEmpty {
            return cache.rows
        }

        let rows = computeRows(proposal: proposal, subviews: subviews)
        cache.rows = rows
        cache.proposalWidth = proposalWidth
        cache.subviewCount = subviews.count
        return rows
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var currentRow = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let newWidth = currentRow.width + (currentRow.items.isEmpty ? 0 : horizontalSpacing) + size.width

            if !currentRow.items.isEmpty && newWidth > maxWidth {
                rows.append(currentRow)
                currentRow = Row()
            }

            currentRow.items.append(RowItem(subview: subview, size: size))
            currentRow.width += (currentRow.items.count > 1 ? horizontalSpacing : 0) + size.width
            currentRow.height = max(currentRow.height, size.height)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
