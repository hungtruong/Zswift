//
//  WorkoutSelectionView.swift
//  Zswift
//
//  Created by Hung Truong on 4/9/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import SwiftUI

struct WorkoutSelectionView: View {
    let workouts = WorkoutLoader.shared.workouts
    @AppStorage(ftpKey) var ftp: Int = 160
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkout: Workout?
    var body: some View {
        List {
            ForEach(workouts, id: \.self) { workout in
                ZStack {
                    GroupBox(label:
                                HStack {
                                    Text(workout.name)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(Color(.systemGray)).imageScale(.small)
                                },
                             content: {
                                VStack {
                                    Text(workout.workoutDescription)
                                        .font(.caption)
                                        .lineLimit(3)
                                    SwiftUIWorkoutView(workout: workout)
                                        .frame(height: 80, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                }
                             })
                        .listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                }
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                SwiftUIWorkoutViewController(workoutManager: WorkoutManager(workout: workout))
            }
        }
    
    }
}

struct WorkoutSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutSelectionView()
    }
}
