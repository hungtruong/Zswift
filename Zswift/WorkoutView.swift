//
//  WorkoutView.swift
//  Zswift
//
//  Created by Hung Truong on 4/7/19.
//  Copyright © 2019 Hung Truong. All rights reserved.
//

import UIKit

class WorkoutView: UIView {
    let stackView = UIStackView()
    var progressView: UIView?
    var progressViewTrailingConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupViews()
    }
    
    private func setupViews() {
        self.addSubview(stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    func setupWorkout(_ workout: Workout) {
        stackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
            stackView.removeArrangedSubview(view)
        }
        
        workout.workoutSegments.forEach { workoutSegment in
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            let barView = UIView()
            barView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(barView)
            let heightMultiplier = workoutSegment.highPower() / workout.maximumPower()

            barView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: CGFloat(heightMultiplier)).isActive = true
            stackView.addArrangedSubview(view)
            let multiplier = workoutSegment.duration / workout.totalTime
            view.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: CGFloat(multiplier)).isActive = true
            barView.backgroundColor = workoutSegment.color()

            
            barView.bottomAnchor.constraint(equalTo: barView.superview!.bottomAnchor).isActive = true
            barView.leadingAnchor.constraint(equalTo: barView.superview!.leadingAnchor).isActive = true
            barView.trailingAnchor.constraint(equalTo: barView.superview!.trailingAnchor, constant: -1).isActive = true
        }
    }
    
    func updateProgress(_ progress: Float) {
        if self.progressView == nil {
            let progressView = UIView()
            progressView.backgroundColor = .label
            progressView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(progressView)
            let trailingConstraint =
            progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            NSLayoutConstraint.activate([
                progressView.topAnchor.constraint(equalTo: self.topAnchor),
                progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                progressView.widthAnchor.constraint(equalToConstant: 1.0),
                trailingConstraint
            ])

            self.progressView = progressView
            self.progressViewTrailingConstraint = trailingConstraint
        } else if let trailingConstraint = self.progressViewTrailingConstraint {
            let offset = self.bounds.width * CGFloat(progress)
            trailingConstraint.constant = offset
        }
    }
}
