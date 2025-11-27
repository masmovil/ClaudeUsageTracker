//
//  UpdateManager.swift
//  Claude Usage Tracker
//
//  Copyright © 2025 Sergio Bañuls. All rights reserved.
//  Licensed under Personal Use License (Non-Commercial)
//

import Foundation
import AppKit

class UpdateManager: ObservableObject {
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var releaseURL: String = ""
    @Published var isChecking: Bool = false

    private let githubRepo = "masorange/ClaudeUsageTracker"
    private let currentVersion: String

    init() {
        // Get current version from bundle
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func checkForUpdates() async {
        await MainActor.run {
            self.isChecking = true
        }

        do {
            guard let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest") else {
                print("❌ Invalid GitHub API URL")
                await MainActor.run { self.isChecking = false }
                return
            }

            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ GitHub API request failed")
                await MainActor.run { self.isChecking = false }
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else {
                print("❌ Failed to parse GitHub API response")
                await MainActor.run { self.isChecking = false }
                return
            }

            // Remove 'v' prefix from tag (e.g., "v1.5.0" -> "1.5.0")
            let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

            print("🔍 [Update] Current: \(currentVersion), Latest: \(latestVersion)")

            // Compare versions
            let updateAvailable = self.isNewerVersion(latest: latestVersion, current: currentVersion)

            await MainActor.run {
                self.latestVersion = latestVersion
                self.releaseURL = htmlURL
                self.updateAvailable = updateAvailable
                self.isChecking = false

                if updateAvailable {
                    print("🆕 [Update] New version available: \(latestVersion)")
                } else {
                    print("✅ [Update] You're up to date!")
                }
            }

        } catch {
            print("❌ [Update] Error checking for updates: \(error.localizedDescription)")
            await MainActor.run {
                self.isChecking = false
            }
        }
    }

    private func isNewerVersion(latest: String, current: String) -> Bool {
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }

        // Ensure we have at least 3 components (major.minor.patch)
        guard latestComponents.count >= 3, currentComponents.count >= 3 else {
            return false
        }

        // Compare major version
        if latestComponents[0] > currentComponents[0] { return true }
        if latestComponents[0] < currentComponents[0] { return false }

        // Compare minor version
        if latestComponents[1] > currentComponents[1] { return true }
        if latestComponents[1] < currentComponents[1] { return false }

        // Compare patch version
        if latestComponents[2] > currentComponents[2] { return true }

        return false
    }

    func openReleaseURL() {
        guard let url = URL(string: releaseURL) else { return }
        NSWorkspace.shared.open(url)
    }
}
