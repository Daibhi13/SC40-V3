//  SprintProgramViewModel.swift
//  SC40
//
//  ViewModel for loading, saving, and refreshing sprint program
//  Author: Copilot

import Foundation

// Ensure only canonical SessionFeedback is used everywhere in this file.

class SprintProgramViewModel: ObservableObject {
    @Published var sessions: [TrainingSession] = []
    @Published var feedback: [SessionFeedback] = []
    @Published var fatigueScore: Double = 0.0
    
    var params: ProgramParameters
    
    init(level: Level, daysPerWeek: Int, recentPB40: Double?) {
        let loadedFeedback = ProgramPersistence.loadFeedback()
        let initialFatigue = FatigueManager.updatedFatigueScore(from: loadedFeedback)
        self.feedback = loadedFeedback
        self.fatigueScore = initialFatigue
        self.params = ProgramParameters(level: level, daysPerWeek: daysPerWeek, recentPB40: recentPB40, fatigueScore: initialFatigue)
        self.sessions = ProgramPersistence.loadSessions()
        if sessions.isEmpty {
            refreshProgram()
        }
    }
    
    func refreshProgram() {
        fatigueScore = FatigueManager.updatedFatigueScore(from: feedback)
        params = ProgramParameters(level: params.level, daysPerWeek: params.daysPerWeek, recentPB40: params.recentPB40, fatigueScore: fatigueScore)
        sessions = generate12WeekProgram(params: params, recentFeedback: feedback)
        ProgramPersistence.saveSessions(sessions)
    }
    
    func addFeedback(_ newFeedback: SessionFeedback) {
        feedback.append(newFeedback)
        ProgramPersistence.saveFeedback(feedback)
        refreshProgram()
    }
    
    func reload() {
        feedback = ProgramPersistence.loadFeedback()
        sessions = ProgramPersistence.loadSessions()
        fatigueScore = FatigueManager.updatedFatigueScore(from: feedback)
    }
}
