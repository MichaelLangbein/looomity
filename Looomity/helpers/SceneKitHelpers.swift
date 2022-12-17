//
//  SceneKitHelpers.swift
//  Looomity
//
//  Created by Michael Langbein on 16.12.22.
//

import SceneKit

func createPopAnimation() -> CAKeyframeAnimation {
    let animation = CAKeyframeAnimation(keyPath: "scale")
    animation.duration = 0.2
    animation.keyTimes = [
        NSNumber(value: 0),
        NSNumber(value: 0.1 * animation.duration),
        NSNumber(value: 0.5 * animation.duration),
        NSNumber(value: animation.duration)
    ]
    animation.values = [
        SCNVector3(x: 1, y: 1, z: 1),
        SCNVector3(x: 1.3, y: 1.3, z: 1.3),
        SCNVector3(x: 0.8, y: 0.8, z: 0.8),
        SCNVector3(x: 1, y: 1, z: 1),
    ]
    animation.repeatCount = 1
    animation.autoreverses = false
    animation.isRemovedOnCompletion = true  // revert to initial state
    return animation
}

func createOpacityRevealAnimation(fromOpacity: Float = 0.0, toOpacity: Float = 1.0) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.duration = 0.2
    animation.fromValue = fromOpacity
    animation.toValue = toOpacity
    animation.repeatCount = 0
    animation.autoreverses = false
    // https://stackoverflow.com/questions/6059054/cabasicanimation-resets-to-initial-value-after-animation-completes
    animation.isRemovedOnCompletion = false  // maintain new state
    animation.fillMode = .forwards           // maintain new state
    return animation
}

func createOpacityHideAnimation(fromOpacity: Float = 1.0, toOpacity: Float = 0.0) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.duration = 0.2
    animation.fromValue = fromOpacity
    animation.toValue = toOpacity
    animation.repeatCount = 0
    animation.autoreverses = false
    animation.isRemovedOnCompletion = false  // maintain new state
    animation.fillMode = .forwards           // maintain new state
    return animation
}

func createSpinAnimation() -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.rotation.y")
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    animation.fromValue = 0.0
    animation.toValue = Float.pi
    animation.repeatCount = 1
    animation.autoreverses = false
    animation.isRemovedOnCompletion = false  // maintain new state
    animation.fillMode = .forwards           // maintain new state
    return animation
}

func getGestureHits(view: SCNView, gesture: UIGestureRecognizer) -> [SCNNode] {
    let location = gesture.location(in: view)
    let hitNodes = view.hitTest(location, options: [:])
    return hitNodes.map { $0.node }
}

func setValueRecursively(node: SCNNode, val: any Equatable, key: String) {
    node.setValue(val, forKey: key)
    for child in node.childNodes {
        setValueRecursively(node: child, val: val, key: key)
    }
}

func findByValueRecursively<T: Comparable>(node: SCNNode, val: T, key: String) -> SCNNode? {
    let foundVal = node.value(forKey: key) as? T
    if foundVal != nil && foundVal == val {
        return node
    } else {
        for child in node.childNodes {
            let result = findByValueRecursively(node: child, val: val, key: key)
            if result != nil {
                return result
            }
        }
    }
    return nil
}

func findByValueInList<T: Comparable>(list: [SCNNode], val: T, key: String) -> SCNNode? {
    for node in list {
        let foundVal = node.value(forKey: key) as? T
        if foundVal != nil && foundVal == val {
            return node
        }
    }
    return nil
}
