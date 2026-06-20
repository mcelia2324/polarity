import SwiftUI
import Charts   // iOS 16+, fine for deployment target 18

/// "Consciousness Mirror" reflects the user's reflection journey back to them, built
/// entirely from on-device journal data. No backend, no per-user AI, nothing leaves the phone.
struct ConsciousnessMirrorView: View {
    @ObservedObject var journalStore: JournalStore

    private var stats: MirrorStats {
        MirrorStats.build(from: journalStore.entries)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Group {
                    if stats.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 16) {
                            headlineCard(stats).gentleAppear(0)
                            thisWeekCard(stats).gentleAppear(0.06)
                            heatmapCard(stats).gentleAppear(0.12)
                            higherWordsCard(stats).gentleAppear(0.18)
                            footnote.gentleAppear(0.24)
                        }
                        .padding(.horizontal, 20)
                        .readableWidth()
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Mirror")
        }
    }

    // MARK: - Headline stats

    private func headlineCard(_ s: MirrorStats) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your Reflection", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.accentDark)

            HStack(spacing: 12) {
                statTile(value: "\(s.totalReflections)", label: "Reflections", systemImage: "checkmark.seal.fill")
                statTile(value: "\(s.currentStreak)", label: "Current streak", systemImage: "flame.fill", tint: Theme.accent)
            }
            HStack(spacing: 12) {
                statTile(value: "\(s.longestStreak)", label: "Longest streak", systemImage: "trophy.fill")
                statTile(value: "\(s.wordsThisMonth)", label: "Words this month", systemImage: "text.alignleft")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func statTile(value: String, label: String, systemImage: String, tint: Color = Theme.accent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundColor(tint)
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.ink)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.background.opacity(0.5))
        .cornerRadius(14)
    }

    // MARK: - This week

    private func thisWeekCard(_ s: MirrorStats) -> some View {
        let week = Array(s.heatmap.suffix(7))
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("This Week", systemImage: "calendar")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.accentDark)
                Spacer()
                Text("\(s.reflectionsThisWeek) of 7 days")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.muted)
            }

            HStack(spacing: 8) {
                ForEach(week) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(day.hasEntry ? AnyShapeStyle(Theme.accent.gradient) : AnyShapeStyle(Theme.muted.opacity(0.12)))
                            .frame(height: 40)
                            .overlay {
                                if day.hasEntry {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.white)
                                }
                            }
                        Text(weekdayLetter(day.date))
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func weekdayLetter(_ date: Date) -> String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return symbols.indices.contains(idx) ? symbols[idx] : ""
    }

    // MARK: - GitHub-style heatmap (plain SwiftUI)

    private func heatmapCard(_ s: MirrorStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Reflection Days", systemImage: "square.grid.3x3.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.accentDark)
                Spacer()
                legend
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    let rows = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 7)
                    LazyHGrid(rows: rows, spacing: 4) {
                        ForEach(s.heatmap) { day in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(color(for: day.level(maxIntensity: s.maxIntensity)))
                                .frame(width: 14, height: 14)
                                .id(day.id)
                                .accessibilityLabel(accessibilityLabel(for: day))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear {
                    if let last = s.heatmap.last { proxy.scrollTo(last.id, anchor: .trailing) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less").font(.caption2).foregroundColor(Theme.muted)
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: level))
                    .frame(width: 10, height: 10)
            }
            Text("More").font(.caption2).foregroundColor(Theme.muted)
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0:  return Theme.muted.opacity(0.12)
        case 1:  return Theme.accent.opacity(0.30)
        case 2:  return Theme.accent.opacity(0.50)
        case 3:  return Theme.accent.opacity(0.72)
        default: return Theme.accent
        }
    }

    private func accessibilityLabel(for day: HeatmapDay) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        let dateStr = f.string(from: day.date)
        return day.hasEntry ? "\(dateStr): reflected, \(day.wordCount) words" : "\(dateStr): no reflection"
    }

    // MARK: - Higher words bar (Swift Charts)

    private func higherWordsCard(_ s: MirrorStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Words You've Leaned Toward", systemImage: "arrow.up.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.accentDark)

            Text("The higher-calibrating word from each reflection.")
                .font(.caption)
                .foregroundColor(Theme.muted)

            Chart(s.topHigherWords) { item in
                BarMark(
                    x: .value("Times", item.count),
                    y: .value("Word", item.word)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .foregroundStyle(Theme.accent.gradient)
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(item.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Theme.muted)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(height: max(CGFloat(s.topHigherWords.count) * 32, 60))

            if let top = s.topHigherWords.first {
                Text("You've leaned toward \(top.word) most often.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Footnote / empty

    private var footnote: some View {
        Text("Built entirely from your on-device journal. Nothing here leaves your phone.")
            .font(.caption2)
            .foregroundColor(Theme.muted.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            Image(systemName: "circle.hexagongrid")
                .font(.system(size: 48))
                .foregroundColor(Theme.muted.opacity(0.4))
            Text("Nothing to Reflect Yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.ink)
            Text("Journal a few reflections and your\nConsciousness Mirror will take shape here.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .readableWidth()
        .padding(.horizontal, 32)
    }
}
