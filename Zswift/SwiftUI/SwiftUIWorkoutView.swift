//
//  SwiftUIWorkoutView.swift
//  Zswift
//
//  Created by Hung Truong on 4/8/21.
//  Copyright © 2021 Hung Truong. All rights reserved.
//

import SwiftUI

struct SwiftUIWorkoutView: View {
    struct WorkoutSegmentViewModel: Hashable, Identifiable {
        var id = UUID()
        let durationPercentage: Double
        let startPercentage: Double
        let endPercentage: Double
        let displayColor: Color
    }
    
    struct WorkoutBackgroundView: View {
        private let workoutViewModels: [WorkoutSegmentViewModel]
        init(workoutViewModels: [WorkoutSegmentViewModel]) {
            self.workoutViewModels = workoutViewModels
        }
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width - CGFloat(workoutViewModels.count)
                HStack(spacing: 1) {
                    ForEach(workoutViewModels, id: \.self) { viewModel in
                        path(in: CGSize(width:
                                            CGFloat(viewModel.durationPercentage) * width,
                                        height: geometry.size.height),
                             startHeight: CGFloat(viewModel.startPercentage),
                             endHeight: CGFloat(viewModel.endPercentage)
                        )
                        .fill()
                        .foregroundColor(viewModel.displayColor)
                        .frame(width: CGFloat(viewModel.durationPercentage) * width)
                    }
                }
            }
        }
        
        func path(in size: CGSize, startHeight: CGFloat, endHeight: CGFloat) -> Path {
            var path = Path()
            let radius: CGFloat = 3
            let bottomLeft = CGPoint(x:0, y: size.height)
            let upperLeft = CGPoint(x: 0, y: size.height * ((-startHeight + 100) / 100))
            let upperRight = CGPoint(x: size.width, y: size.height * ((-endHeight + 100) / 100))
            let bottomRight = CGPoint(x: size.width, y: size.height)
            path.move(to: bottomLeft)
            path.addArc(tangent1End: upperLeft, tangent2End: upperRight, radius: radius)
            path.addArc(tangent1End: upperRight, tangent2End: bottomRight, radius: radius)
            path.addLine(to: bottomRight)
            return path
        }
    }
    
    private let workoutViewModels: [WorkoutSegmentViewModel]
    private let workout: Workout
    private let workoutManager: WorkoutManager?
    
    init(workout: Workout, workoutManager: WorkoutManager? = nil) {
        self.workout = workout
        self.workoutViewModels = workout.workoutSegments.map { segment in
            WorkoutSegmentViewModel(durationPercentage: segment.duration / workout.totalTime,
                                    startPercentage: segment.startPower() / workout.maximumPower() * 100,
                                    endPercentage: segment.endPower() / workout.maximumPower() * 100,
                                    displayColor: Color(segment.color()))
        }
        
        self.workoutManager = workoutManager
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                Color(.label)
                    .frame(width: 1.0)
                    .offset(x: CGFloat(workoutManager?.workoutProgress ?? -1) * geometry.size.width)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(WorkoutBackgroundView(workoutViewModels: workoutViewModels))
        }
        .clipped()
    }
    

}

struct SwiftUIWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let workout = Workout.mockWorkout()
        
        Group {
            SwiftUIWorkoutView(workout: workout)
                .previewLayout(.fixed(width: 320, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.dark)
            SwiftUIWorkoutView(workout: workout)
                .previewLayout(.fixed(width: 320, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.light)
        }
    }
}
