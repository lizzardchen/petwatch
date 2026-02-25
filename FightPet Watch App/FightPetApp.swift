//
//  FightPetApp.swift
//  FightPet Watch App
//
//  Created by lizzardchen on 11/27/25.
//

import SwiftUI
import FirebaseCore

@main
struct FightPet_Watch_AppApp: App {
    
    init() {
        FirebaseManager.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
