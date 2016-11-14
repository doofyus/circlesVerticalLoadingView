//
//  CirclesVerticalLoadingView.swift
//
//  Created by Mikk Rätsep on 11/11/2016.
//  Copyright © 2016 Mikk Rätsep. All rights reserved.
//

import UIKit


@IBDesignable class CirclesVerticalLoadingView: UIView {

    fileprivate typealias Circle = UIView


    // MARK: IBInspectables

    @IBInspectable var circleRadius: CGFloat = 5.0              { didSet { configureCircles(colour: circleColour, radius: circleRadius) } }
    @IBInspectable var circleColour: UIColor = UIColor.black    { didSet { configureCircles(colour: circleColour, radius: circleRadius) } }

    @IBInspectable var circlesCount: Int = 8                    { didSet { configureCircles(newCount: circlesCount) } }

    @IBInspectable var gapPercentage: CGFloat   = 30.0          { didSet { setNeedsLayout() } }
    @IBInspectable var gapLocation: Int         = 3             { didSet { setNeedsLayout() } }


    // MARK: Vars

    private(set) var isAnimating: Bool  = false

    fileprivate var animForward = false
    fileprivate var animIndex   = 0
    fileprivate var animDura    = 1.0

    // Let's not calculate them on every change, cheaper to store the latest value in a var
    fileprivate var gapSize: CGFloat    = 0.0
    fileprivate var stepSize: CGFloat   = 0.0

    fileprivate var circles: [Circle]   = []


    // MARK: Methods

    func slowDown() { animDura *= 3.0 }

    func speedUp() { animDura /= 3.0 }

    func startAnimating() {
        guard !isAnimating else { return }

        isAnimating = true
        animIndex   = gapLocation

        animate()
    }

    func stopAnimating() {
        guard isAnimating else { return }

        isAnimating = false
        gapLocation = animIndex
        animDura    = 1.0
    }


    // MARK: UIView

    override init(frame: CGRect) {
        super.init(frame: frame)

        createCircles()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        createCircles()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rearrangeCircles()
    }
}

fileprivate extension CirclesVerticalLoadingView {

    // MARK: Animation

    fileprivate func animate() {
        guard isAnimating else { return }

        animateSingleCircle() { self.animate() }
    }

    private func animateSingleCircle(completion: @escaping (Void) -> Void) {
        updateAnimationIndex()

        // The 'active' circle's index
        let index = animForward ? (animIndex - 1) : animIndex
        // If the 'gap' is above the circle - add it to the mix
        let gapAdd = animForward ? 0.0 : gapSize
        // Finds the 'default' position for the circle (and adds the 'gap' when needed)
        let yPoint = (stepSize * CGFloat(index)) + circleRadius + gapAdd

        UIView.animate(withDuration: animDura, delay: 0.0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            self.circles[index].center.y = yPoint
        }) { _ in completion() }
    }

    private func updateAnimationIndex() {
        // Reverse the direction
        if (animIndex == circlesCount) || (animIndex == 0) {
            animForward = !animForward
        }

        animIndex += animForward ? 1 : -1
    }


    // MARK: Creation

    fileprivate func createCircles() {
        circles = (0..<circlesCount).flatMap { _ -> Circle in createCircle() }
    }

    private func createCircle() -> Circle {
        let circle = Circle()

        configureCircle(circle, colour: circleColour, radius: circleRadius)

        addSubview(circle)

        return circle
    }


    // MARK: Configuration

    fileprivate func configureCircles(newCount: Int) {
        guard circles.count != newCount else { return }

        let diff = abs(circles.count - newCount)

        // Remove 'extra' circles
        if circles.count > newCount {
            (0..<diff).forEach { _ in circles.popLast()?.removeFromSuperview() }
        }
        // Add 'missing' circles
        else {  
            circles.append(contentsOf: (0..<diff).flatMap { _ -> Circle in createCircle() })
        }

        setNeedsLayout()
    }

    fileprivate func configureCircles(colour: UIColor, radius: CGFloat) {
        circles.forEach { configureCircle($0, colour: colour, radius: radius) }
    }

    private func configureCircle(_ circle: Circle, colour: UIColor, radius: CGFloat) {
        let sideLength = 2.0 * radius

        circle.backgroundColor      = colour
        circle.layer.cornerRadius   = radius
        circle.bounds.size          = CGSize(width: sideLength, height: sideLength)
    }

    fileprivate func rearrangeCircles() {
        let availableHeight = bounds.height - (2.0 * circleRadius)

        // Calculate the new 'sizes'
        gapSize     = (gapPercentage / 100.0) * bounds.height
        stepSize    = (availableHeight - gapSize) / max(CGFloat(circlesCount - 1), 1e-5)

        // Move the circles
        circles.enumerated().forEach {
            let gapAdd = ($0.offset < gapLocation) ? CGFloat(0.0) : gapSize

            $0.element.center.x = bounds.midX
            $0.element.center.y = (stepSize * CGFloat($0.offset)) + circleRadius + gapAdd
        }
    }
}

