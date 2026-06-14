//
//  ParentAccountService.swift
//  LearnLock
//
//  Lightweight parent-account + cross-device sync client. Talks to Supabase
//  SECURITY DEFINER RPCs over REST (no SDK dependency). A parent creates an
//  account on their phone and shares a 6-character sync code; the child's
//  device links with that code. Progress and controls then sync between them.
//

import Foundation
import Observation

@MainActor
@Observable
final class ParentAccountService {
    enum Role: String { case none, parent, child }

    private(set) var householdId: String?
    private(set) var email: String?
    private(set) var syncCode: String?
    private(set) var role: Role = .none
    private(set) var lastSyncedAt: Date?
    var isSyncing: Bool = false
    var errorMessage: String?

    private var token: String?

    var isLinked: Bool { householdId != nil && token != nil }

    // Persistence keys
    private let dHouseholdId = "pa.householdId"
    private let dEmail = "pa.email"
    private let dSyncCode = "pa.syncCode"
    private let dRole = "pa.role"
    private let kToken = "pa.token"

    private let defaults = UserDefaults.standard

    init() {
        householdId = defaults.string(forKey: dHouseholdId)
        email = defaults.string(forKey: dEmail)
        syncCode = defaults.string(forKey: dSyncCode)
        role = Role(rawValue: defaults.string(forKey: dRole) ?? "") ?? .none
        token = Keychain.get(kToken)
    }

    // MARK: - Auth

    func signUp(email rawEmail: String, password: String) async -> Bool {
        await perform {
            let json = try await self.rpc("parent_signup", payload: [
                "p_email": rawEmail, "p_password": password
            ])
            try self.store(json, role: .parent)
        }
    }

    func signIn(email rawEmail: String, password: String) async -> Bool {
        await perform {
            let json = try await self.rpc("parent_login", payload: [
                "p_email": rawEmail, "p_password": password
            ])
            try self.store(json, role: .parent)
        }
    }

    func linkDevice(code: String) async -> Bool {
        await perform {
            let json = try await self.rpc("parent_link", payload: [
                "p_sync_code": code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ])
            try self.store(json, role: .child)
        }
    }

    func signOut() {
        householdId = nil
        email = nil
        syncCode = nil
        role = .none
        token = nil
        lastSyncedAt = nil
        defaults.removeObject(forKey: dHouseholdId)
        defaults.removeObject(forKey: dEmail)
        defaults.removeObject(forKey: dSyncCode)
        defaults.removeObject(forKey: dRole)
        Keychain.delete(kToken)
    }

    // MARK: - Sync

    /// Pulls the latest household snapshot. Returns nil if not linked or empty.
    func pull() async -> SyncSnapshot? {
        guard let householdId, let token else { return nil }
        do {
            isSyncing = true
            defer { isSyncing = false }
            let json = try await rpc("parent_pull_state", payload: [
                "p_id": householdId, "p_token": token
            ])
            lastSyncedAt = Date()
            errorMessage = nil
            guard let dict = json as? [String: Any],
                  let stateObj = dict["state"], !(stateObj is NSNull) else { return nil }
            let data = try JSONSerialization.data(withJSONObject: stateObj)
            return try JSONDecoder().decode(SyncSnapshot.self, from: data)
        } catch {
            errorMessage = friendly(error)
            return nil
        }
    }

    /// Pushes the local snapshot to the household.
    @discardableResult
    func push(_ snapshot: SyncSnapshot) async -> Bool {
        guard let householdId, let token else { return false }
        do {
            isSyncing = true
            defer { isSyncing = false }
            let data = try JSONEncoder().encode(snapshot)
            let stateObj = try JSONSerialization.jsonObject(with: data)
            _ = try await rpc("parent_push_state", payload: [
                "p_id": householdId, "p_token": token, "p_state": stateObj
            ])
            lastSyncedAt = Date()
            errorMessage = nil
            return true
        } catch {
            errorMessage = friendly(error)
            return false
        }
    }

    // MARK: - Internals

    private func perform(_ work: @escaping () async throws -> Void) async -> Bool {
        isSyncing = true
        errorMessage = nil
        defer { isSyncing = false }
        do {
            try await work()
            return true
        } catch {
            errorMessage = friendly(error)
            return false
        }
    }

    private func store(_ json: Any, role newRole: Role) throws {
        guard let dict = json as? [String: Any],
              let id = dict["id"] as? String,
              let tok = dict["token"] as? String else {
            throw SyncError.server("Unexpected response")
        }
        householdId = id
        token = tok
        email = dict["email"] as? String
        syncCode = dict["sync_code"] as? String
        role = newRole
        lastSyncedAt = Date()

        defaults.set(id, forKey: dHouseholdId)
        defaults.set(email, forKey: dEmail)
        defaults.set(syncCode, forKey: dSyncCode)
        defaults.set(newRole.rawValue, forKey: dRole)
        Keychain.set(tok, for: kToken)
    }

    private func rpc(_ function: String, payload: [String: Any]) async throws -> Any {
        guard let base = URL(string: Config.EXPO_PUBLIC_SUPABASE_URL),
              !Config.EXPO_PUBLIC_SUPABASE_URL.isEmpty else {
            throw SyncError.server("Sync is not configured")
        }
        let url = base.appendingPathComponent("rest/v1/rpc/\(function)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.EXPO_PUBLIC_SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Config.EXPO_PUBLIC_SUPABASE_ANON_KEY)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let json = try? JSONSerialization.jsonObject(with: data)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let message = (json as? [String: Any])?["message"] as? String
            throw SyncError.code(message ?? "Request failed (\(http.statusCode))")
        }
        guard let json else { throw SyncError.server("Empty response") }
        return json
    }

    private func friendly(_ error: Error) -> String {
        if case let SyncError.code(message) = error {
            switch message {
            case "email_taken": return "That email already has an account."
            case "invalid_credentials": return "Email or password is incorrect."
            case "invalid_code": return "That sync code wasn't found."
            case "invalid_input": return "Enter a valid email and a 6+ character password."
            case "unauthorized": return "Session expired. Please sign in again."
            default: return message
            }
        }
        return "Network error. Check your connection and try again."
    }
}

nonisolated enum SyncError: Error, Sendable {
    case server(String)
    case code(String)
}
