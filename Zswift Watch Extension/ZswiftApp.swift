//
//  ZswiftApp.swift
//  Zswift Watch Extension
//
//  Created by Hung Truong on 4/17/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import SwiftUI
import WatchConnectivity

@main
struct ZswiftApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate
    init() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.default
        session.delegate = WorkoutHandler.shared
        session.activate()
    }
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
