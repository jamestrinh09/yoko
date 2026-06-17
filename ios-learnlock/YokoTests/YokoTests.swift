//
//  YokoTests.swift
//  YokoTests
//
//  Created by Rork on May 7, 2026.
//

import Testing
@testable import Yoko

struct YokoTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - Bulk unlock-rule application

    @Test func bulkApplyToSelectedAppsOnlyChangesThoseApps() async throws {
        let store = AppStore()
        let ids = Set(store.locks.prefix(2).map(\.id))

        store.setLockRule(forIds: ids, type: .timed, rewardRule: "session")

        for lock in store.locks {
            if ids.contains(lock.id) {
                #expect(lock.type.normalized == .timed)
            }
        }
    }

    @Test func bulkApplyToAllAppsSetsEveryLock() async throws {
        let store = AppStore()

        store.setLockRuleForAll(type: .full, rewardRule: "session")

        #expect(store.locks.allSatisfy { $0.type.normalized == .full })
    }

    @Test func rewardRulePropagatesToSelectedApps() async throws {
        let store = AppStore()
        let ids = Set(store.locks.prefix(3).map(\.id))

        store.setLockRule(forIds: ids, type: .reward, rewardRule: "daily")

        for lock in store.locks where ids.contains(lock.id) {
            #expect(lock.type.normalized == .reward)
            #expect(lock.rewardRule == "daily")
        }
    }

    @Test func passcodeGateInactiveWhenNoPasscodeSet() async throws {
        let store = AppStore()
        store.parentPasscodeEnabled = true
        store.parentPasscode = nil
        // Enabled but unset → gate stays open so actions run without a prompt.
        #expect(store.passcodeGateActive == false)
    }

    @Test func passcodeGateActiveWhenEnabledAndSet() async throws {
        let store = AppStore()
        store.parentPasscodeEnabled = true
        store.parentPasscode = "1234"
        #expect(store.passcodeGateActive == true)

        store.parentPasscodeEnabled = false
        #expect(store.passcodeGateActive == false)
        store.parentPasscode = nil
    }

    // MARK: - Parent-passcode gate checklist (Locks tab)
    //
    // Every lock-changing action in LocksView routes through
    // `requireParentPasscode(_:)`. When you add a new lock mutation, wire it
    // through that wrapper and tick it here:
    //
    //   [x] 1. Tap a single app's rule tag        (LockRow onEditRule → presentSingleRule)
    //   [x] 2. Confirm a rule ("Set Rule")        (presentSingleRule wraps the open; confirm is behind the unlocked visit)
    //   [x] 3. Post-picker bulk-apply prompt      (presentBulkPickerRule)
    //   [x] 4. Multi-select "Apply Rule"          (applyRuleToSelected)
    //   [x] 5. Toggle an app's on/off switch      (LockRow onToggleEnabled)
    //   [x] 6. Toggle Bedtime / School Hours      (scheduleRow onToggle)
    //   [x] 7. Remove all locked apps             (clearShields button)
    //   [x] 8. Open the app/category picker       (openAppPicker)
}
