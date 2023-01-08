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
        // optimization works best when we only focus on the most important paras.
        // seems to struggle with scale in particular.
//        head.eulerAngles.x = x[2]
//        head.eulerAngles.y = x[3]
//        head.eulerAngles.z = x[4]
//        head.scale.x = x[5]
//        head.scale.y = x[5]
//        head.scale.z = x[5]
        let s = sse(sceneView: sceneView, head: head, observation: observation, image: image)
        return s
    }
    let initial = [head.position.x, head.position.y]
    let optimal = rand_gd(f: f, initial: initial)
    head.position.x = optimal[0]
    head.position.y = optimal[1]
    return head
}

// Might also try BNNS Adam: https://developer.apple.com/documentation/accelerate/bnns/adamoptimizer


func gd(f: ([Float]) -> Float, initial: [Float]) -> [Float] {
    
    let alpha: Float = 0.01                  // learning rate
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
            dx[i] += alpha
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / alpha
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
    var s = Float.greatestFiniteMagnitude    // size of change
    let sMax: Float = 0.00001                // stop when change is less than this
    var x = initial
    let jMax = 1000             // max iteration
    let maxDelta: Float = 0.1   // max change per step
    
    var bestXSoFar = x
    var fMin = Float.greatestFiniteMagnitude
    var iterationsAwayFromBest = 0
    let maxIterationsAwayFromBest = jMax / 5
    
    var j = 0
    while s > sMax && j < jMax {
        var fx = f(x)
        
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
            }
        }
        
        var dfdx = [Float](repeating: 0.0, count: initial.count)
        for i in 0 ..< initial.count {
            var dx = x
            dx[i] += alpha
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / alpha
        }
        
        let r: Float = maxRand * (1.0 - Float(j / jMax))
        for i in 0 ..< initial.count {
            var delta = alpha * dfdx[i]
            if delta > maxDelta {
                delta = maxDelta
            } else if delta < -maxDelta {
                delta = -maxDelta
            }
            x[i] = x[i] - delta + Float.random(in: -r ... r)
        }
        s = size(dfdx)
        
        j += 1
    }

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
    
    // get important points from model
    guard
        let leftEyeL  = head.childNode(withName: "left_eye_left", recursively: true),
        let leftEyeR  = head.childNode(withName: "left_eye_right", recursively: true),
        let rightEyeL = head.childNode(withName: "right_eye_left", recursively: true),
        let rightEyeR = head.childNode(withName: "right_eye_right", recursively: true),
        let nose      = head.childNode(withName: "nose_center", recursively: true),
        let mouth     = head.childNode(withName: "mouth_center", recursively: true)
    else { return 0.0 }
    // project those points
    let leftEyeLProjected  = sceneProjectToImageCoordinates(sceneView, image, leftEyeL.worldPosition)
    let leftEyeRProjected  = sceneProjectToImageCoordinates(sceneView, image, leftEyeR.worldPosition)
    let rightEyeLProjected = sceneProjectToImageCoordinates(sceneView, image, rightEyeL.worldPosition)
    let rightEyeRProjected = sceneProjectToImageCoordinates(sceneView, image, rightEyeR.worldPosition)
    let noseProjected      = sceneProjectToImageCoordinates(sceneView, image, nose.worldPosition)
    let mouthProjected     = sceneProjectToImageCoordinates(sceneView, image, mouth.worldPosition)

    // get important points from image
    guard let landmarks = observation.landmarks else { return 0.0 }
    guard
        let leftEyeLandmark = landmarks.leftEye,
        let rightEyeLandmark = landmarks.rightEye,
        let noseCrestLandmark = landmarks.noseCrest,
        let outerLipsLandmark = landmarks.outerLips
    else { return 0.0 }
    let leftEyeLTarget   = leftMostPoint(leftEyeLandmark.normalizedPoints)
    let leftEyeRTarget   = rightMostPoint(leftEyeLandmark.normalizedPoints)
    let rightEyeLTarget  = leftMostPoint(rightEyeLandmark.normalizedPoints)
    let rightEyeRTarget  = rightMostPoint(rightEyeLandmark.normalizedPoints)
    let noseTarget       = centerPoint(noseCrestLandmark.normalizedPoints)
    let mouthTarget      = centerPoint(outerLipsLandmark.normalizedPoints)
    // project those points
    let leftEyeLTargetProjected = obsProjToImageCoords(point: leftEyeLTarget, observation: observation)
    let leftEyeRTargetProjected = obsProjToImageCoords(point: leftEyeRTarget, observation: observation)
    let rightEyeLTargetProjected = obsProjToImageCoords(point: rightEyeLTarget, observation: observation)
    let rightEyeRTargetProjected = obsProjToImageCoords(point: rightEyeRTarget, observation: observation)
    let noseTargetProjected = obsProjToImageCoords(point: noseTarget, observation: observation)
    let mouthTargetProjected = obsProjToImageCoords(point: mouthTarget, observation: observation)
    
//    let imagePlaneOpt = sceneView.scene?.rootNode.childNode(withName: "ImagePlane", recursively: true)
//    if let imagePlane = imagePlaneOpt {
//        if let geo = imagePlane.geometry {
//            print(geo.boundingBox.min)
//            print(geo.boundingBox.max)
//            print(sceneProjToImageCoords(sceneView, image, geo.boundingBox.min))
//            print(sceneProjToImageCoords(sceneView, image, geo.boundingBox.max))
//            print(leftEyeLTargetProjected)
//            print(rightEyeRTargetProjected)
//            print(noseTargetProjected)
//        }
//    }
    
    // compare projected points with face-landmarks
    let s = (
          vectorDiff(leftEyeLProjected, leftEyeLTargetProjected)
        + vectorDiff(leftEyeRProjected, leftEyeRTargetProjected)
        + vectorDiff(rightEyeLProjected, rightEyeLTargetProjected)
        + vectorDiff(rightEyeRProjected, rightEyeRTargetProjected)
        + vectorDiff(noseProjected, noseTargetProjected)
        + vectorDiff(mouthProjected, mouthTargetProjected)
    )
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

private func centerPoint(_ points: [CGPoint]) -> CGPoint {
    let xMean = points.reduce(0.0, { intermediate, point in
        intermediate + point.x
    }) / CGFloat(points.count)
    let yMean = points.reduce(0.0, { intermediate, point in
        intermediate + point.y
    }) / CGFloat(points.count)
    return CGPoint(x: xMean, y: yMean)
}


private func sceneProjectToImageCoordinates(_ sceneView: SCNView, _ image: UIImage, _ v: SCNVector3) -> CGPoint {
 
    let scene_w = sceneView.frame.width
    let scene_h = sceneView.frame.height
    
    let img_w = image.size.width
    let img_h = image.size.height
    
    
    /*==================================================================
     =          From word-coords to clipping-coords                    =
     =================================================================*/
    var arScreen = 1.0
    if scene_w > scene_h { // landscape
        arScreen = scene_h / scene_w
    } else {
        arScreen = scene_w / scene_h
    }
    
    guard
        let scene = sceneView.scene,
        let cameraNode = scene.rootNode.childNode(withName: "Camera", recursively: true),
        let camera = cameraNode.camera
    else { return CGPoint() }
    
    let projectionMatrix = camera.projectionTransform
    var updatedProjectionMatrix = projectionMatrix
    if (updatedProjectionMatrix.m11 == updatedProjectionMatrix.m22) {
        updatedProjectionMatrix.m11 = updatedProjectionMatrix.m11 * Float(arScreen)
    }
    let viewMatrix = SCNMatrix4Invert(cameraNode.worldTransform)
    
    let v4 = SCNVector4(x: v.x, y: v.y, z: v.z, w: 1.0)
    let vCamPos = matMul(viewMatrix, v4)
    let vClip = matMul(updatedProjectionMatrix, vCamPos)
    let vClipNorm = SCNVector3(x: vClip.x / vClip.w, y: vClip.y / vClip.w, z: vClip.z / vClip.w)
    
    
    /*==================================================================
     =          From clipping-coords to screen-relative-coords         =
     =================================================================*/

//    Clipping-space is clipped off where it reaches over the device-bounds
//    (At least when projection-matrix accounts for aspect-ratio)
//
//                     device-screen
//    ┌────────────┬───────────────────┬─────────────┐ clipping-space
//    │            │         ▲         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │   X = scene_w / (scene_h * 2) = 0.28125
//    │            │         │         │             │
//    │            │         │         │             │
// -1 │◄───────────┼─────────┼─────────X────────────►│ 1
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         │         │             │
//    │            │         ▼         │             │
//    └────────────┴───────────────────┴─────────────┘
    
    var xClipMin = -1.0
    var xClipMax =  1.0
    var yClipMin = -1.0
    var yClipMax =  1.0
    if scene_w > scene_h { // landscape-orientation
        yClipMin = -scene_h / (scene_w * 2.0)
        yClipMax =  scene_h / (scene_w * 2.0)
    } else {
        xClipMin = -scene_w / (scene_h * 2.0)
        xClipMax =  scene_w / (scene_h * 2.0)
    }
    let xClipRange = xClipMax - xClipMin
    let yClipRange = yClipMax - yClipMin
    let xScreenRel = (Double(vClipNorm.x) - xClipMin) / xClipRange
    let yScreenRel = (Double(vClipNorm.y) - yClipMin) / yClipRange
    
    
    /*==================================================================
     =          From screen-relative-coords to img-relative-coords     =
     =================================================================*/

//    ┌──────────────┐ ▲ 1
//    │              │ │
//    │              │ │
//    ├───────────1─▲┤ │ 1.0 - delta = 0.8
//    │             ││ │
//    │             ││ │
//    │             ││ │
//    │          0.5││ │ 0.5
//    │             ││ │
//    │             ││ │
//    │             ││ │
//    ├───────────0─┴┤ │ delta = 0.2
//    │              │ │
//    │              │ │
//    └──────────────┘ │ 0
    
    var xOffset = 0.0
    var yOffset = 0.0
    if scene_w > scene_h { // landscape
        let uPerPixImg = 1.0 / img_h
        let img_w_u = img_w * uPerPixImg
        let uPerPixScreen = 1.0 / scene_h
        let scene_w_u = scene_w * uPerPixScreen
        let delta = (scene_w_u - img_w_u) / 2.0
        xOffset = delta
    } else {
        let uPerPixImg = 1.0 / img_w
        let img_h_u = img_h * uPerPixImg
        let uPerPixScreen = 1.0 / scene_w
        let scene_h_u = scene_h * uPerPixScreen
        let delta = (scene_h_u - img_h_u) / 2.0
        yOffset = delta
    }
    
    let xImgRel = (Double(xScreenRel) - xOffset) / (1.0 - 2.0 * xOffset)
    let yImgRel = (Double(yScreenRel) - yOffset) / (1.0 - 2.0 * yOffset)
    
    return CGPoint(
        x: xImgRel,
        y: yImgRel
    )
}

private func obsProjToImageCoords(point: CGPoint, observation: VNFaceObservation) -> CGPoint {
    let projected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(point.x), y: Float(point.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    return projected
}

private func vectorDiff(_ v1: CGPoint, _ v2: CGPoint) -> Float {
    return Float(pow(v1.x - v2.x, 2.0) + pow(v1.y - v2.y, 2.0))
}
