//
//  SwiftUIWorkoutViewController.swift
//  Zswift
//
//  Created by Hung Truong on 4/9/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import SwiftUI
import Combine

struct SwiftUIWorkoutViewController: View {
    private var subscriptions = Set<AnyCancellable>()
    
    @State private var showingCancelConfirmationAlert = false
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var workoutManager: WorkoutManager
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }
    
    var body: some View {
        if verticalSizeClass == .compact
        {
            VStack {
                SwiftUIWorkoutView(workout: workoutManager.workout, workoutManager: workoutManager)
                    .frame(height: 110)
                HStack {
                    GroupBox(label: Text(workoutManager.workout.name), content: {
                        Text(workoutManager.currentSegmentDescription)
                            .font(.largeTitle)
                        if let description = workoutManager.nextSegmentDescription {
                            Text("Next: " + description)
                                .foregroundColor(.gray)
                        }
                    })
                }
                HStack {
                    GroupBox(label: Text("Segment Time"), content: {
                        HStack {
                            Text(workoutManager.currentSegmentTimeElapsedString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            Text("/")
                            Text(workoutManager.currentSegmentTimeString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }.font(.title3)
                        ProgressView(value: workoutManager.segmentProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: workoutManager.currentSegmentColor))
                    })
                    GroupBox(label: Text("Elapsed Time"), content: {
                        HStack {
                            Text(workoutManager.timeElapsedString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            Text("/")
                            Text(workoutManager.totalWorkoutTimeString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }.font(.title3)
                        ProgressView(value: workoutManager.workoutProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: workoutManager.currentSegmentColor))
                    })
                    
                }
                GroupBox(label: Label("Watts", systemImage: "bolt.fill")
                    .foregroundColor(.blue), content: {
                        HStack {
                            Text(workoutManager.currentWattage)
                            Text("/")
                            Text(workoutManager.targetWattage)
                        }
                        .font(.system(size: 40))
                        
                    })
                HStack {
                    GroupBox(label: Label("Heart Rate", systemImage: "heart.fill" )
                        .foregroundColor(.red),
                             content: {
                        Text(workoutManager.heartRateString)
                    })
                    GroupBox(label: Label("Calories", systemImage: "flame.fill")
                        .foregroundColor(Color("Orange")),
                             content: {
                        Text(workoutManager.caloriesString)
                    })
                    
                }
                .font(.largeTitle)
                HStack {
                    GroupBox(label: Label("Miles", systemImage: "ruler")
                        .foregroundColor(.purple), content: {
                            Text(workoutManager.milesString)
                        })
                    GroupBox(label: Label("Cadence", systemImage: "metronome")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/), content: {
                            Text(workoutManager.cadenceString)
                        })
                }
                .font(.largeTitle)
                Button("Cancel") {
                    showingCancelConfirmationAlert = true
                }
                .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 40, maxHeight: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .background(Color(.systemRed))
                .foregroundColor(.white)
                .cornerRadius(6.0)
                .alert(isPresented: $showingCancelConfirmationAlert, content: {
                    Alert(title: Text("Are you sure?"),
                          primaryButton: .destructive(Text("Yeah")) {
                        endWorkout()
                    }, secondaryButton: .cancel())
                })
            }
            .padding(.horizontal)
            .onReceive(workoutManager.$workoutIsOver, perform: { workoutIsOver in
                if workoutIsOver {
                    self.endWorkout()
                }
            })
        } else {
            VStack(spacing: 2) {
                Spacer()
                HStack {
                    
                    SwiftUIWorkoutView(workout: workoutManager.workout, workoutManager: workoutManager)
                        .frame(height: 110)

                }
                HStack {
                    GroupBox(label: Label("Watts", systemImage: "bolt.fill")
                        .foregroundColor(.blue), content: {
                            HStack {
                                Text(workoutManager.currentWattage)
                                Text("/")
                                Text(workoutManager.targetWattage)
                            }
                            .font(.system(size: 40))
                        })
                    GroupBox(label: Text(workoutManager.workout.name), content: {
                            Text(workoutManager.currentSegmentDescription)
                                .font(.largeTitle)
                            if let description = workoutManager.nextSegmentDescription {
                                Text("Next: " + description)
                                    .foregroundColor(.gray)
                            }
                        })
                }
                HStack {
                    GroupBox(label: Text("Segment Time"), content: {
                        HStack {
                            Text(workoutManager.currentSegmentTimeElapsedString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            Text("/")
                            Text(workoutManager.currentSegmentTimeString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }.font(.title3)
                        ProgressView(value: workoutManager.segmentProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: workoutManager.currentSegmentColor))
                    })
                    GroupBox(label: Text("Elapsed Time"), content: {
                        HStack {
                            Text(workoutManager.timeElapsedString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            Text("/")
                            Text(workoutManager.totalWorkoutTimeString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                        }.font(.title3)
                        ProgressView(value: workoutManager.workoutProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: workoutManager.currentSegmentColor))
                    })
                    GroupBox(label: Label("Heart Rate", systemImage: "heart.fill" )
                        .foregroundColor(.red),
                             content: {
                        Text(workoutManager.heartRateString)
                    })
                    GroupBox(label: Label("Calories", systemImage: "flame.fill")
                        .foregroundColor(Color("Orange")),
                             content: {
                        Text(workoutManager.caloriesString)
                    })

                }
                .font(.largeTitle)
                HStack {

                }
                .font(.largeTitle)
                Button("Cancel") {
                    showingCancelConfirmationAlert = true
                }
                .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxWidth: .infinity, minHeight: 40, idealHeight: 50, maxHeight: 60, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .background(Color(.systemRed))
                .foregroundColor(.white)
                .cornerRadius(6.0)
                .alert(isPresented: $showingCancelConfirmationAlert, content: {
                    Alert(title: Text("Are you sure?"),
                          primaryButton: .destructive(Text("Yeah")) {
                        endWorkout()
                    }, secondaryButton: .cancel())
                })
            }
            .padding(.horizontal)
            .onReceive(workoutManager.$workoutIsOver, perform: { workoutIsOver in
                if workoutIsOver {
                    self.endWorkout()
                }
            })
        }
    }
    
    func endWorkout() {
        workoutManager.endWorkout()
        presentationMode.wrappedValue.dismiss()
    }
}

struct SwiftUIWorkoutViewController_Previews: PreviewProvider {
    static var previews: some View {
        let workout = Workout.mockWorkout()
        let workoutManager = WorkoutManager(workout: workout)
        SwiftUIWorkoutViewController(workoutManager: workoutManager)
            .previewDevice("iPhone 14 Pro")
        
    }
}
