//
//  GradientDescent.swift
//  Looomity
//
//  Created by Michael Langbein on 05.11.22.
//

import Vision
import SceneKit

/**
Problem:
$$ \text{min}_x f(x) $$
Algorithm:
$$
    \Delta_0 = - \alpha \frac{df}{dx}|x_0  \\
    x_1 = x_0 + \Delta_0
$$

```python
def f(x):
    return 1 - (x[0]-4)**3 + (x[1]-1)**2

def size(v):
    return np.sum(v * v)

def gradDesc(f, x):
    deltaX = np.asarray([0.001, 0.0])
    deltaY = np.asarray([0.0, 0.001])
    alpha = 0.01
    s = 10000
    sMax = 0.001
    while s > sMax:
        fx = f(x)
        dfdx = np.asarray([
            (f( x + deltaX ) - fx) / deltaX[0],
            (f( x + deltaY ) - fx) / deltaY[1],
        ])
        x = x - alpha * dfdx
        s = size(dfdx)
    return x

gradDesc(f, np.asarray([1, 1]))
```
*/

func gradientDescent(sceneView: SCNView, head: SCNNode, observation: VNFaceObservation, image: UIImage) -> SCNNode {
    func f(x: [Float]) -> Float {
        head.position.x = x[0]
        head.position.y = x[1]
        // optimisation works best when we only focus on the most important paras.
        // seems to struggle with scale in particular.
//        head.eulerAngles.x = x[2]
//        head.eulerAngles.y = x[3]
//        head.eulerAngles.z = x[4]
//        head.scale.x = x[2]
//        head.scale.y = x[2]
//        head.scale.z = x[2]
        let s = sse(sceneView: sceneView, head: head, observation: observation, image: image)
        return s
    }
    let initial = [head.position.x, head.position.y]
    let optimal = rand_gd(f: f, initial: initial)
    head.position.x = optimal[0]
    head.position.y = optimal[1]
//    head.scale.x = optimal[2]
//    head.scale.y = optimal[2]
//    head.scale.z = optimal[2]
    return head
}

// Might also try BNNS Adam: https://developer.apple.com/documentation/accelerate/bnns/adamoptimizer


func gd(f: ([Float]) -> Float, initial: [Float]) -> [Float] {
    
    let alpha: Float = 0.01                  // learning rate
    let deltaX: Float = 0.001                // deltaX for df/dx calculation
    var s = Float.greatestFiniteMagnitude    // size of change
    let sMax: Float = 0.00001                // stop when change is less than this
    var x = initial
    let jMax = 1000             // max iteration
    let maxDelta: Float = 0.1   // max change per step
    
    var bestXSoFar = x
    var fMin = Float.greatestFiniteMagnitude
    
    var j = 0
    while s > sMax && j < jMax {
        let fx = f(x)
        
        if (fx < fMin) {
            bestXSoFar = x
            fMin = fx
        }
        
        var dfdx = [Float](repeating: 0.0, count: initial.count)
        for i in 0 ..< initial.count {
            var dx = x
            dx[i] += deltaX
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / deltaX
        }
        
        for i in 0 ..< initial.count {
            var delta = alpha * dfdx[i]
            if delta > maxDelta {
                let maxDeltaJ = maxDelta * (Float(jMax - j)) / Float(jMax)
                let r = Float.random(in: 0.0 ... maxDeltaJ)  // randomising a little to prevent loops
                delta =  ( maxDeltaJ + r ) / 2.0
            } else if delta < -maxDelta {
                let maxDeltaJ = maxDelta * (Float(jMax - j)) / Float(jMax)
                let r = Float.random(in: 0.0 ... maxDeltaJ)  // randomising a little to prevent loops
                delta = -( maxDeltaJ + r ) / 2.0
            }
            x[i] = x[i] - delta
        }
        s = size(dfdx)
        
        j += 1
    }

    return bestXSoFar
}



/**
 * Randomised gradient descent.
 *  - Some random perturbation to every delta (getting smaller on every iteration)
 *  - Never strays too far from optimum (= never more than `maxIterationsAwayFromBest`)
 *  - Always returns best one found so far.
 */
func rand_gd(f: ([Float]) -> Float, initial: [Float], maxRand: Float = 0.01) -> [Float] {

    let alpha: Float = 0.01                  // learning rate
    let deltaX: Float = 0.01                 // deltaX for df/dx calculation
    var currentChange = Float.greatestFiniteMagnitude    // size of change
    let maximumChange: Float = 0.00001                   // stop when change is less than this
    var x = initial
    let jMin = 1000             // min iterations
    let jMax = 5000             // max iterations
    let maxDelta: Float = 0.1   // max change per step
    
    var bestXSoFar = x
    var fMin = Float.greatestFiniteMagnitude
    var iterationsAwayFromBest = 0
    let maxIterationsAwayFromBest = jMax / 5
    
    var j = 0
    while (j < jMin) || (currentChange > maximumChange && j < jMax) {
        
        //------------- Evaluate --------------------------------------------------//
        var fx = f(x)

        //------------- If too far away, go back to last optimum ------------------//
        if (fx < fMin) {
            bestXSoFar = x
            fMin = fx
            iterationsAwayFromBest = 0
        } else {
            iterationsAwayFromBest += 1
            if iterationsAwayFromBest > maxIterationsAwayFromBest {
                // resetting
                x = bestXSoFar
                fx = fMin
                iterationsAwayFromBest = 0
            }
        }
        
        //------------- dfdx ------------------------------------------------------//
        var dfdx = [Float](repeating: 0.0, count: initial.count)
        for i in 0 ..< initial.count {
            var dx = x
            dx[i] += deltaX
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / deltaX
        }
        
        //----------- x = x - alpha * dfdx ---------------------------------------//
        let fractionLeft: Float = (1.0 - Float(j / jMax))
        for i in 0 ..< initial.count {
            //--------- reducing learning rate, but never all the way to 0 -------//
            var delta = max(fractionLeft, 0.2) * alpha * dfdx[i]
            //--------- preventing jumps that are too far ------------------------//
            if delta > maxDelta {
                delta = maxDelta
            } else if delta < -maxDelta {
                delta = -maxDelta
            }
            //-------- adding some randomness -------------------------------------//
            delta += Float.random(in: -maxRand * fractionLeft  ... maxRand * fractionLeft)
            x[i] = x[i] - delta
        }
        currentChange = size(dfdx)
        
        j += 1
    }

    #if DEBUG
    print("Completed gradient descent after \(j) operations")
    #endif
    
    return bestXSoFar
}

func size(_ arr: [Float]) -> Float {
    var sum: Float = 0.0
    for v in arr {
        sum += v * v
    }
    return sum
}


func sse(sceneView: SCNView, head: SCNNode, observation: VNFaceObservation, image: UIImage) -> Float {
    
    let imageWidth = image.size.width
    let imageHeight = image.size.height
    
    guard
        let scene = sceneView.scene,
        let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true),
        let camera = cameraNode.camera
    else { return 0.0 }
    
    let cameraWordTransform = cameraNode.worldTransform
    let cameraProjectionTransform = camera.projectionTransform
    
    // get important points from model
    guard
        let eyeBrowL  = head.childNode(withName: "eyebrow_left_r", recursively: true),
        let eyeBrowR  = head.childNode(withName: "eyebrow_right_l", recursively: true),
        let leftEyeL  = head.childNode(withName: "left_eye_left", recursively: true),
        let leftEyeR  = head.childNode(withName: "left_eye_right", recursively: true),
        let rightEyeL = head.childNode(withName: "right_eye_left", recursively: true),
        let rightEyeR = head.childNode(withName: "right_eye_right", recursively: true),
        let nose      = head.childNode(withName: "nose_center", recursively: true),
        let mouth     = head.childNode(withName: "mouth_center", recursively: true),
        let mouthL    = head.childNode(withName: "mouth_left", recursively: true),
        let mouthR    = head.childNode(withName: "mouth_right", recursively: true),
        let chin      = head.childNode(withName: "chin", recursively: true)
    else { return 0.0 }
    
    // get important points from image
    guard
        let landmarks = observation.landmarks,
        let leftEyeBrowLandmark  = landmarks.leftEyebrow,
        let rightEyeBrowLandmark = landmarks.rightEyebrow,
        let leftEyeLandmark      = landmarks.leftEye,
        let rightEyeLandmark     = landmarks.rightEye,
        let noseCrestLandmark    = landmarks.noseCrest,
        let outerLipsLandmark    = landmarks.outerLips,
        let medianLandmark       = landmarks.medianLine
    else { return 0.0 }
    let leftEyeBrowObs  = rightMostPoint(leftEyeBrowLandmark.normalizedPoints)
    let rightEyeBrowObs = leftMostPoint(rightEyeBrowLandmark.normalizedPoints)
    let leftEyeLObs     = leftMostPoint(leftEyeLandmark.normalizedPoints)
    let leftEyeRObs     = rightMostPoint(leftEyeLandmark.normalizedPoints)
    let rightEyeLObs    = leftMostPoint(rightEyeLandmark.normalizedPoints)
    let rightEyeRObs    = rightMostPoint(rightEyeLandmark.normalizedPoints)
    let noseObs         = centerPoint(noseCrestLandmark.normalizedPoints)
    let mouthObs        = centerPoint(outerLipsLandmark.normalizedPoints)
    let mouthLObs       = leftMostPoint(outerLipsLandmark.normalizedPoints)
    let mouthRObs       = rightMostPoint(outerLipsLandmark.normalizedPoints)
    let chinObs         = lowestPoint(medianLandmark.normalizedPoints)
    
    let modelPoints =       [eyeBrowL,       eyeBrowR,        leftEyeL,    leftEyeR,    rightEyeL,    rightEyeR,    nose,    mouth,    mouthL,    mouthR,    chin]
    let observationPoints = [leftEyeBrowObs, rightEyeBrowObs, leftEyeLObs, leftEyeRObs, rightEyeLObs, rightEyeRObs, noseObs, mouthObs, mouthLObs, mouthRObs, chinObs]
    
    var s: Float = 0.0
    for i in 0..<modelPoints.count {
        
        let modelPoint = modelPoints[i]
        let modelClip = scene2clipping(modelPoint.position, cameraWordTransform, cameraProjectionTransform)
        
        let obsPoint = observationPoints[i]
        let obsImg = landmark2image(obsPoint, observation.boundingBox)
        let obsScene = image2scene(obsImg, Int(imageWidth), Int(imageHeight))
        let obsClip = scene2clipping(obsScene, cameraWordTransform, cameraProjectionTransform)
        
        let diff = vectorDiff(modelClip, obsClip)
        s += diff
    }
    
    return s
}

private func leftMostPoint(_ points: [CGPoint]) -> CGPoint {
    var leftPoint = points[0]
    for point in points {
        if point.x < leftPoint.x {
            leftPoint = point
        }
    }
    return leftPoint
}

private func rightMostPoint(_ points: [CGPoint]) -> CGPoint {
    var rightPoint = points[0]
    for point in points {
        if point.x > rightPoint.x {
            rightPoint = point
        }
    }
    return rightPoint
}

private func lowestPoint(_ points: [CGPoint]) -> CGPoint {
    var lowestPoint = points[0]
    for point in points {
        if point.y > lowestPoint.y {  // landmarks' y-values are 0 on top and 1 at bottom.
            lowestPoint = point
        }
    }
    return lowestPoint
}

private func centerPoint(_ points: [CGPoint]) -> CGPoint {
    let xMean = points.reduce(0.0, { intermediate, point in
        intermediate + point.x
    }) / CGFloat(points.count)
    let yMean = points.reduce(0.0, { intermediate, point in
        intermediate + point.y
    }) / CGFloat(points.count)
    return CGPoint(x: xMean, y: yMean)
}


private func vectorDiff(_ v1: SCNVector3, _ v2: SCNVector3) -> Float {
    return Float(pow(v1.x - v2.x, 2.0) + pow(v1.y - v2.y, 2.0))
}
