import SwiftUI

/// The language picked in Settings, stored with `@AppStorage(AppLanguage.storageKey)`.
enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"
    case system

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// The language actually shown. `.system` follows the phone's first preferred language
    /// (Chinese if it is any kind of Chinese, otherwise English).
    var resolved: AppLanguage {
        guard self == .system else { return self }
        let preferred = Locale.preferredLanguages.first ?? "zh-Hans"
        return preferred.hasPrefix("zh") ? .chinese : .english
    }
}

/// Every piece of on-screen text, in Chinese and English.
/// Views read it from the environment: `@Environment(\.strings) private var s`.
struct Strings {
    /// Always `.chinese` or `.english` (already resolved).
    let language: AppLanguage

    var isChinese: Bool { language != .english }
    /// Used for dates and times.
    var locale: Locale { Locale(identifier: isChinese ? "zh-Hans" : "en") }
    /// Used for voice input.
    var speechLocale: Locale { Locale(identifier: isChinese ? "zh-CN" : "en-US") }

    private func pick(_ zh: String, _ en: String) -> String { isChinese ? zh : en }

    // MARK: Tabs and screens

    var todoTab: String { pick("待办", "To do") }
    var doneTab: String { pick("已完成", "Done") }
    var addItem: String { pick("添加待办", "Add item") }
    var settings: String { pick("设置", "Settings") }

    func progress(done: Int, left: Int) -> String {
        if done == 0 {
            return pick("今天还有 \(left) 项要做", "\(left) to do today")
        }
        if left == 0 {
            return pick("今天的 \(done) 项全部完成 🎉", "All \(done) done for today 🎉")
        }
        return pick("今天已完成 \(done) 项，还剩 \(left) 项", "\(done) done, \(left) to go")
    }

    func stageCaption(done: Int, total: Int) -> String {
        if total == 0 {
            return pick("加一项待办，出发！", "Add an item to get going!")
        }
        return pick("进度 \(done) / \(total) · 跑到终点就收工", "\(done) / \(total) · Reach the flag to finish")
    }

    func coins(_ count: Int) -> String {
        pick("今天的金币 \(count) 枚", count == 1 ? "1 coin today" : "\(count) coins today")
    }

    var catName: String { pick("像素橘猫", "Pixel cat") }

    var emptyTitle: String { pick("暂无待办", "Nothing to do") }
    var emptyHint: String { pick("点右下角的 + 添加第一条待办。", "Tap + at the bottom right to add your first item.") }

    var markDone: String { pick("标记为完成", "Mark as done") }
    var markNotDone: String { pick("标记为未完成", "Mark as not done") }
    var delete: String { pick("删除", "Delete") }
    var edit: String { pick("编辑", "Edit") }
    var undoDone: String { pick("撤销完成", "Not done") }

    // MARK: History

    var noneFinishedTitle: String { pick("还没有已完成的事项", "Nothing finished yet") }
    var noneFinishedHint: String { pick("完成的事项会保存在这里。", "Items you finish are kept here.") }

    /// "今天" / "Today" etc. for the last few days, nil for older days.
    func dayPrefix(daysAgo: Int?) -> String? {
        switch daysAgo {
        case 0: return pick("今天", "Today")
        case 1: return pick("昨天", "Yesterday")
        case 2: return isChinese ? "前天" : nil
        default: return nil
        }
    }

    /// "3 项 · 共 50 分钟" / "3 items · 50 min total"
    func daySummary(count: Int, minutes: Int) -> String {
        let items = pick("\(count) 项", count == 1 ? "1 item" : "\(count) items")
        guard minutes > 0 else { return items }
        return pick("\(items) · 共 \(duration(minutes))", "\(items) · \(duration(minutes)) total")
    }

    // MARK: Durations

    func duration(_ minutes: Int) -> String {
        if minutes < 60 {
            return pick("\(minutes) 分钟", "\(minutes) min")
        }
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = pick("\(hours) 小时", "\(hours) hr")
        return rest == 0 ? hourText : "\(hourText) \(duration(rest))"
    }

    /// Label for the quick-pick chips; the pomodoro length gets a tomato.
    func chipDuration(_ minutes: Int) -> String {
        minutes == DurationOption.pomodoro ? "🍅 " + duration(minutes) : duration(minutes)
    }

    // MARK: Add / edit sheet

    var newItem: String { pick("新建待办", "New item") }
    var editItem: String { pick("编辑待办", "Edit item") }
    var titlePlaceholder: String { pick("要做什么？", "What do you need to do?") }
    var listening: String { pick("正在聆听… 说完后再点一下麦克风", "Listening… tap the mic again when you're done") }
    var howLong: String { pick("需要多久？（可选）", "How long? (optional)") }
    var save: String { pick("保存", "Save") }
    var add: String { pick("添加", "Add") }
    var voiceInput: String { pick("语音输入", "Voice input") }
    var stopVoiceInput: String { pick("停止语音输入", "Stop voice input") }

    func message(for problem: SpeechInput.Problem) -> String {
        switch problem {
        case .speechDenied: return pick("请在“设置”中允许语音识别", "Allow Speech Recognition in the Settings app")
        case .microphoneDenied: return pick("请在“设置”中允许使用麦克风", "Allow microphone access in the Settings app")
        case .unavailable: return pick("语音识别暂时不可用", "Speech recognition isn't available right now")
        case .cannotRecord: return pick("无法开始录音", "Couldn't start recording")
        }
    }

    // MARK: Streaks

    func streakDays(_ days: Int) -> String {
        pick("连续 \(days) 天", days == 1 ? "1-day streak" : "\(days)-day streak")
    }
    func bestStreak(_ days: Int) -> String {
        pick("最长 \(days) 天", "Best \(days)")
    }
    var streakRestHint: String { pick("休息一天不会断。", "One rest day won't break it.") }
    var streakStart: String { pick("今天完成一项，开始你的连续记录。", "Finish one thing today to start a streak.") }

    // MARK: Reminders

    var reminderTitle: String { pick("每日提醒", "Daily reminder") }
    var reminderTime: String { pick("提醒时间", "Time") }
    var reminderFootnote: String {
        pick("每天在这个时间轻轻提醒你挑一件小事。", "A gentle nudge each day to pick one small thing.")
    }
    var reminderDenied: String {
        pick("通知已关闭。请在“设置”中打开通知。", "Notifications are off. Turn them on in the Settings app.")
    }
    var openSystemSettings: String { pick("打开设置", "Open Settings") }

    /// Wording for each weekday's notification (1 = Sunday ... 7 = Saturday).
    func reminderMessage(forWeekday weekday: Int) -> String {
        let zh = [
            "新的一周，先挑一件最小的事开始吧。",
            "只做一件小事就好，小猫在等你。",
            "5 分钟也算数，现在就开始吧。",
            "今天想先完成哪一件？",
            "挑一件小事，让小猫拿到今天的金币。",
            "快到周末了，再完成一件小事吧。",
            "周末也可以很轻松，只做一件就好。",
        ]
        let en = [
            "A new week. Start with the smallest thing.",
            "Just one small thing. The cat is waiting.",
            "Five minutes counts. Start now.",
            "Which one do you want to finish first today?",
            "Pick one small thing and earn today's coin.",
            "Almost the weekend. One more small thing?",
            "Weekends can be easy. Just do one.",
        ]
        let index = min(max(weekday, 1), 7) - 1
        return pick(zh[index], en[index])
    }

    // MARK: Focus timer

    var focusStart: String { pick("开始", "Start") }
    var focusStop: String { pick("停止", "Stop") }
    var focusing: String { pick("专注中", "Focusing") }
    var timesUp: String { pick("时间到", "Time's up") }
    func focusEnded(_ title: String) -> String { pick("“\(title)”的专注时间结束了。", "Your focus time for \"\(title)\" is over.") }
    func startFocus(_ title: String) -> String { pick("开始专注：\(title)", "Start focus timer for \(title)") }
    func stopFocus(_ title: String) -> String { pick("停止专注：\(title)", "Stop focus timer for \(title)") }

    // MARK: What's new

    var whatsNewTitle: String { pick("新功能", "What's new") }
    var whatsNewSubtitle: String { pick("这次更新带来了这些变化。", "Here's what changed in this update.") }
    var whatsNewSettingsRow: String { pick("新功能介绍", "What's new") }
    var gotIt: String { pick("知道了", "Got it") }

    /// The features announced for `WhatsNew.currentRelease`. Replace this list when you bump the release.
    var whatsNewItems: [WhatsNewItem] {
        [
            WhatsNewItem(
                icon: "square.grid.2x2.fill",
                title: pick("主屏幕和锁屏小组件", "Home Screen and Lock Screen widgets"),
                body: pick(
                    "把小猫放到主屏幕或锁屏上，随时看到今天的进度和连续记录。",
                    "Put the cat on your Home Screen or Lock Screen to see today's progress and your streak at a glance."
                )
            ),
            WhatsNewItem(
                icon: "cat.fill",
                title: pick("更可爱的小猫", "A cuter cat"),
                body: pick(
                    "小猫会轻轻摇尾巴，偶尔眨眨眼。开启“减少动态效果”时它会安静待着。",
                    "The cat now wags its tail and blinks now and then. With Reduce Motion on, it stays still."
                )
            ),
            WhatsNewItem(
                icon: "app.fill",
                title: pick("全新图标", "New app icon"),
                body: pick(
                    "应用图标换成了橙色小猫。",
                    "The app icon is now the orange cat."
                )
            ),
        ]
    }

    // MARK: Settings

    var languageTitle: String { pick("语言", "Language") }
    var languageFootnote: String { pick("语音输入也会跟着切换语言。", "Voice input switches language too.") }
    var close: String { pick("完成", "Done") }

    func name(of option: AppLanguage) -> String {
        switch option {
        case .chinese: return "中文"
        case .english: return "English"
        case .system: return pick("跟随系统", "Same as iPhone")
        }
    }
}

struct WhatsNewItem: Identifiable {
    var id: String { icon }
    let icon: String
    let title: String
    let body: String
}

private struct StringsKey: EnvironmentKey {
    static let defaultValue = Strings(language: .chinese)
}

extension EnvironmentValues {
    var strings: Strings {
        get { self[StringsKey.self] }
        set { self[StringsKey.self] = newValue }
    }
}
