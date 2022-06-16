//
//  ContentView.swift
//  Zswift Watch Extension
//
//  Created by Hung Truong on 4/17/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @ObservedObject var workoutHandler = WorkoutHandler.shared
    var body: some View {
        TabView {
            VStack {
//                if workoutHandler.workoutName != "" {
//                    Text(workoutHandler.workoutName)
//                        .bold()
//                    Spacer()
//                }
                Text(workoutHandler.heartRate)
                    .font(.title)
                    .foregroundColor(.red)
                Text("Heart Rate")
            }
            NowPlayingView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
