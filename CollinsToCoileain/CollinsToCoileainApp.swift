//
//  CollinsToCoileainApp.swift
//  CollinsToCoileain
//
//  Created by Jónótdón Ó Coileáin on 5/21/23.
//

import SwiftUI

@main
struct CollinsToCoileainApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
