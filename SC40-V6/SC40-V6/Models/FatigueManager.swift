//  FatigueManager.swift
//  SC40
//
//  Updates fatigueScore based on feedback and regenerates program
//  Author: Copilot

import Foundation

// Ensure only canonical SessionFeedback is used everywhere in this file.

class FatigueManager {
    static func updatedFatigueScore(from feedback: [SessionFeedback]) -> Double {
        // Simple average of last 3 RPEs (or use more advanced logic)
        let recent = feedback.suffix(3).compactMap { $0.rpe }
        guard !recent.isEmpty else { return 0.0 }
        // Normalize RPE (0-10) to fatigue (0.0-1.0)
        let avgRPE = recent.reduce(0, +) / Double(recent.count)
        return min(max(avgRPE / 10.0, 0.0), 1.0)
    }
}
