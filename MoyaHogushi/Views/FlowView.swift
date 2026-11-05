import SwiftUI
import StoreKit

/// 書く → 感じる → 考える → 手放す の4ステップ。完了後は step == 5。
struct FlowView: View {
    @EnvironmentObject private var store: MoyaStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onClose: () -> Void

    @State private var step = 1
    @State private var draft = MoyaEntry()
    @State private var fogLevel = 1.0
    @State private var orbOpacity = 1.0
    @State private var orbOffset: CGFloat = 0
    @State private var isReleasing = false

    private static let fogByStep: [Int: Double] = [1: 1.0, 2: 0.72, 3: 0.46, 4: 0.24, 5: 0.0]

    private var trimmedText: String { draft.text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            FogView()
                .opacity(fogLevel)
                .animation(.easeInOut(duration: 1.2), value: fogLevel)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                ScrollView {
                    content
                        .padding(.bottom, 24)
                        .id(step)
                        .transition(.opacity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(Theme.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.line, lineWidth: 1))
            }
            .accessibilityLabel("閉じる")

            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= min(step, 4) ? Theme.accent : Theme.line)
                        .frame(height: 4)
                }
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case 1: writeStep
        case 2: feelStep
        case 3: reflectStep
        case 4: releaseStep
        default: doneStep
        }
    }

    private func stepHeader(_ label: String, _ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(Theme.accentInk)
            Text(prompt)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var writeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader("1 / 4・書く", "いま、何にもやもやしてる?")
            PlaceholderEditor(
                text: $draft.text,
                placeholder: "起きたこと、誰かに言われたこと、なんとなく引っかかること。そのまま書いてみて",
                minHeight: 170
            )
        }
        .padding(22)
        .cardStyle()
    }

    private var feelStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader("2 / 4・感じる", "それはどんな感じ?")

            FlowLayout(spacing: 8) {
                ForEach(Emotion.all, id: \.self) { emotion in
                    let isOn = draft.emotions.contains(emotion)
                    Button {
                        if isOn {
                            draft.emotions.removeAll { $0 == emotion }
                        } else {
                            draft.emotions.append(emotion)
                        }
                    } label: {
                        Text(emotion)
                            .font(.system(.subheadline, design: .rounded).weight(isOn ? .semibold : .regular))
                            .foregroundColor(isOn ? Theme.accentInk : Theme.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(isOn ? Theme.accentSoft : Theme.cardSoft)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isOn ? Theme.accent : Theme.line, lineWidth: 1))
                    }
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("もやもやの濃さ")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Theme.secondaryText)
                    Spacer()
                    Text("\(draft.intensity)")
                        .font(.system(.headline, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.accentInk)
                }
                Slider(
                    value: Binding(
                        get: { Double(draft.intensity) },
                        set: { draft.intensity = Int($0.rounded()) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(Theme.accent)
                HStack {
                    Text("薄い").font(.caption2)
                    Spacer()
                    Text("濃い").font(.caption2)
                }
                .foregroundColor(Theme.tertiaryText)
            }
        }
        .padding(22)
        .cardStyle()
    }

    private var reflectStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader("3 / 4・考える", "何が引っかかってるんだと思う?")

            PlaceholderEditor(
                text: $draft.reflection,
                placeholder: "本当はこうしたかった、ここが嫌だった、など。わからなければ空欄で大丈夫",
                minHeight: 100
            )

            Text("これ、自分の行動で変えられること?")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundColor(Theme.text)

            HStack(spacing: 10) {
                choiceButton(title: "変えられる", subtitle: "自分の次の一歩がある", value: true)
                choiceButton(title: "変えられない", subtitle: "相手や状況次第", value: false)
            }
        }
        .padding(22)
        .cardStyle()
    }

    private func choiceButton(title: String, subtitle: String, value: Bool) -> some View {
        let isOn = draft.controllable == value
        return Button {
            draft.controllable = value
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(isOn ? Theme.accentInk : Theme.text)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Theme.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isOn ? Theme.accentSoft : Theme.cardSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isOn ? Theme.accent : Theme.line, lineWidth: 1)
            )
        }
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var releaseStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if draft.controllable == true {
                stepHeader("4 / 4・手放す", "じゃあ、最初の一歩だけ決めよう")
                TextField("例: 明日の朝一で確認のメッセージを送る", text: $draft.action)
                    .font(.system(.body, design: .rounded))
                    .padding(14)
                    .background(Theme.cardSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
                note("一歩が決まったら、残りは今日のあなたが考えなくていい。手に持ったまま手放してしまおう。")
            } else {
                stepHeader("4 / 4・手放す", "これは相手や状況が決めること")
                note("自分では変えられないことに、エネルギーを使いすぎていたのかもしれない。ちゃんと考えたなら、今日はここまでで十分。")
            }

            Text(trimmedText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Theme.secondaryText)
                .lineLimit(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.cardSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(orbOpacity)
                .offset(y: orbOffset)
        }
        .padding(22)
        .cardStyle()
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, design: .rounded))
            .foregroundColor(Theme.secondaryText)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.cardSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var doneStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.max")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.accent)
            Text(draft.hasAction
                 ? "一歩は決まった。あとは手を動かすだけ。もやもやは預かっておくね。"
                 : "今日はちゃんと向き合えた。それでじゅうぶん。")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 22)
        .cardStyle()
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 10) {
            switch step {
            case 1:
                Button("次へ") { go(to: 2) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(trimmedText.isEmpty)
            case 2:
                navButtons(back: 1, next: 3, nextEnabled: true)
            case 3:
                navButtons(back: 2, next: 4, nextEnabled: draft.controllable != nil)
            case 4:
                HStack(spacing: 10) {
                    Button("戻る") { go(to: 3) }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(width: 110)
                    Button("手放す") { release() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .disabled(isReleasing)
            default:
                Button("ホームへ戻る") { onClose() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("もう一度書く") { restart() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.background.opacity(0.92))
    }

    private func navButtons(back: Int, next: Int, nextEnabled: Bool) -> some View {
        HStack(spacing: 10) {
            Button("戻る") { go(to: back) }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 110)
            Button("次へ") { go(to: next) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!nextEnabled)
        }
    }

    // MARK: - Actions

    private func go(to newStep: Int) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.easeInOut(duration: 0.3)) {
            step = newStep
            fogLevel = Self.fogByStep[newStep] ?? 1.0
        }
    }

    private func release() {
        guard !isReleasing else { return }
        isReleasing = true
        draft.text = trimmedText
        draft.action = draft.controllable == true
            ? draft.action.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        draft.createdAt = Date()
        store.add(draft)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeIn(duration: reduceMotion ? 0.4 : 1.0)) {
            orbOpacity = 0
            orbOffset = reduceMotion ? 0 : -160
            fogLevel = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.5 : 1.1)) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.4)) { step = 5 }
            requestReviewIfMilestoneReached()
        }
    }

    private func restart() {
        draft = MoyaEntry()
        orbOpacity = 1
        orbOffset = 0
        isReleasing = false
        go(to: 1)
    }

    /// 手放す儀式を数回終えた、満足度の高いタイミングでレビューを依頼する。表示頻度は iOS 側が制限する。
    private func requestReviewIfMilestoneReached() {
        let key = "releaseCompletionCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)

        guard [3, 10, 30].contains(count) else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        AppStore.requestReview(in: scene)
    }
}

// MARK: - PlaceholderEditor

private struct PlaceholderEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Theme.tertiaryText)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(10)
        .background(Theme.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}
