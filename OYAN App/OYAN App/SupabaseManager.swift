//
//  SupabaseManager.swift
//  OYAN App
//
//  Created by Tair on 26.01.2026.
//

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    public let client: SupabaseClient
    /// Base URL for the project (e.g. for Edge Functions).
    public let supabaseURL: URL
    public let anonKey: String

    private init() {
        let url = URL(string: "https://porfjjvcnixghoxnbbdt.supabase.co")!
        let apiKey = "sb_publishable_W3c5_zb0g3uFl1IejkBKKQ_f3wJMOhf"
        self.supabaseURL = url
        self.anonKey = apiKey
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: apiKey
        )
    }
}

