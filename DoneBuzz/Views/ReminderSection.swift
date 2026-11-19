import SwiftUI
import UIKit

/// The daily reminder switch and time, shown in Settings.
struct ReminderSection: View {
    @Environment(\.strings) private var s
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("reminderEnabled") private var enabled = false
    @AppStorage("reminderMinutes") private var minutes = ReminderService.defaultMinutes
    /// True when the user said no (or later switched notifications off in the Settings app).
    @State private var denied = false

    private let service = ReminderService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(s.reminderTitle, systemImage: "bell.fill")
                .font(Theme.label)
                .foregroundStyle(Theme.muted)

            VStack(spacing: 0) {
                HStack {
                    Text(s.reminderTitle)
                        .font(Theme.button)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Toggle("", isOn: switchBinding)
                        .labelsHidden()
                        .tint(Theme.grass)
                }
                .padding(.horizontal, 18)
                .frame(height: 58)

                if enabled {
                    Divider().overlay(Theme.ink.opacity(0.15))
                    HStack {
                        Text(s.reminderTime)
                            .font(Theme.label)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                }
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2))

            Text(denied ? s.reminderDenied : s.reminderFootnote)
                .font(Theme.hint)
                .foregroundStyle(denied ? Theme.recording : Theme.muted)

            if denied {
                Button(s.openSystemSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
            }
        }
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private var switchBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { wanted in
                Task { await setEnabled(wanted) }
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now
                ) ?? .now
            },
            set: { picked in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: picked)
                minutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
                Task { _ = await service.sync(enabled: enabled, minutes: minutes, strings: s) }
            }
        )
    }

    private func setEnabled(_ wanted: Bool) async {
        if wanted {
            switch await service.enable(minutes: minutes, strings: s) {
            case .enabled:
                enabled = true
                denied = false
            case .denied:
                enabled = false
                denied = true
            }
        } else {
            service.disable()
            enabled = false
            denied = false
        }
    }

    /// Picks up changes made in the Settings app: permission taken away, or given back.
    private func refresh() async {
        let access = await service.center.accessStatus()
        if enabled {
            let stillOn = await service.sync(enabled: true, minutes: minutes, strings: s)
            if !stillOn {
                enabled = false
                denied = true
            }
        } else if access == .allowed {
            denied = false
        }
    }
}
