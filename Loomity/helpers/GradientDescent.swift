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
    let optimal = gd(f: f, initial: initial)
    head.position.x = optimal[0]
    head.position.y = optimal[1]
    return head
}


func gd(f: ([Float]) -> Float, initial: [Float]) -> [Float] {
    let alpha: Float = 0.01
    var s: Float = 10_000.0  // size of change
    let sMax: Float = 0.00001
    var x = initial
    let jMax = 1000  // max iteration
    
    var j = 0
    while s > sMax && j < jMax {
        let fx = f(x)
        
        var dfdx = [Float](repeating: 0.0, count: initial.count)
        for i in 0 ..< initial.count {
            var dx = x
            dx[i] += alpha
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / alpha
        }
        
        for i in 0 ..< initial.count {
            x[i] = x[i] - alpha * dfdx[i]
        }
        s = size(dfdx)
        
        j += 1
        print("\(s) -- \(x)")
    }

    return x
}

func rand_gd(f: ([Float]) -> Float, initial: [Float], maxRand: Float = 0.01) -> [Float] {
    let alpha: Float = 0.01
    var s: Float = 10_000.0  // size of change
    let sMax: Float = 0.00001
    var x = initial
    let jMax = 1000  // max iteration
    
    var j = 0
    while s > sMax && j < jMax {
        let fx = f(x)
        
        var dfdx = [Float](repeating: 0.0, count: initial.count)
        for i in 0 ..< initial.count {
            var dx = x
            dx[i] += alpha
            let fdx = f(dx)
            dfdx[i] = (fdx - fx) / alpha
        }
        
        let r: Float = maxRand * (1.0 - Float(j / jMax))
        for i in 0 ..< initial.count {
            x[i] = x[i] - alpha * dfdx[i]   + Float.random(in: -r ... r)
        }
        s = size(dfdx)
        
        j += 1
        print("\(s) -- \(x)")
    }

    return x
}

func size(_ arr: [Float]) -> Float {
    var sum: Float = 0.0
    for v in arr {
        sum += v * v
    }
    return sum
}


func sse(sceneView: SCNView, head: SCNNode, observation: VNFaceObservation, image: UIImage) -> Float {
    

    /**
ar = imgH / imgW
    
         1  ┌──────────────────────────────────┐      imgCoords│ sceeenCoords
            ▲                                  │               │1
            │                                  │               │
            │                                  │               │
            │                                  │             1 │0.5 + ar/2
  0.5+ ar/2 │▲ 1                               │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │0.5
      0.5│  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │               │
         │  ││                                 │            0  │0.5 - ar/2
 0.5 - ar/2 ├┴────────────────────────────────►│               │
            │0                                1│               │
            │                                  │               │
            │                                  │               │
          0 ├──────────────────────────────────┘►              │0
            0                                 1

 imgCoords 0                                   1
           ─────────────────────────────────────
           0                                   1
 screenCoords
*/
     
    let scene_w = sceneView.frame.width
    let scene_h = sceneView.frame.height
    
    let img_w = image.size.width
    let img_h = image.size.height
    
    var xOffset = 0.0
    var xScale = 1.0
    var yOffset = 0.0
    var yScale = 1.0
    if scene_w > scene_h { // landscape
        let ar = img_w / img_h
        xOffset = 0.5 - (ar / 2.0)
        xScale = ar
    }
    else { // portrait
        let ar = img_h / img_w
        yOffset = 0.5 - (ar / 2.0)
        yScale = ar
    }
    
    
    // get important points from model
    let leftEyeL  = head.childNode(withName: "left_eye_left", recursively: true)!
    let leftEyeR  = head.childNode(withName: "left_eye_right", recursively: true)!
    let rightEyeL = head.childNode(withName: "right_eye_left", recursively: true)!
    let rightEyeR = head.childNode(withName: "right_eye_right", recursively: true)!
    let nose      = head.childNode(withName: "nose_center", recursively: true)!
    let mouth     = head.childNode(withName: "mouth_center", recursively: true)!
    

    // project those points
    let leftEyeLProjected  = sceneProjToImageCoords(sceneView.projectPoint(leftEyeL.worldPosition),  xOffset, xScale, yOffset, yScale)
    let leftEyeRProjected  = sceneProjToImageCoords(sceneView.projectPoint(leftEyeR.worldPosition),  xOffset, xScale, yOffset, yScale)
    let rightEyeLProjected = sceneProjToImageCoords(sceneView.projectPoint(rightEyeL.worldPosition), xOffset, xScale, yOffset, yScale)
    let rightEyeRProjected = sceneProjToImageCoords(sceneView.projectPoint(rightEyeR.worldPosition), xOffset, xScale, yOffset, yScale)
    let noseProjected      = sceneProjToImageCoords(sceneView.projectPoint(nose.worldPosition),      xOffset, xScale, yOffset, yScale)
    let mouthProjected     = sceneProjToImageCoords(sceneView.projectPoint(mouth.worldPosition),     xOffset, xScale, yOffset, yScale)

    // get important points from image
    let landmarks = observation.landmarks!
    let leftEyeLTarget   = leftMostPoint(landmarks.leftEye!.normalizedPoints)
    let leftEyeRTarget   = rightMostPoint(landmarks.leftEye!.normalizedPoints)
    let rightEyeLTarget  = leftMostPoint(landmarks.rightEye!.normalizedPoints)
    let rightEyeRTarget  = rightMostPoint(landmarks.rightEye!.normalizedPoints)
    let noseTarget       = centerPoint(landmarks.noseCrest!.normalizedPoints)
    let mouthTarget      = centerPoint(landmarks.outerLips!.normalizedPoints)

    // project those points
    let leftEyeLTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(leftEyeLTarget.x), y: Float(leftEyeLTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    let leftEyeRTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(leftEyeRTarget.x), y: Float(leftEyeRTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    let rightEyeLTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(rightEyeLTarget.x), y: Float(rightEyeLTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    let rightEyeRTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(rightEyeRTarget.x), y: Float(rightEyeRTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    let noseTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(noseTarget.x), y: Float(noseTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    let mouthTargetProjected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(mouthTarget.x), y: Float(mouthTarget.y)),
        observation.boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    
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


private func sceneProjToImageCoords(_ v: SCNVector3, _ xOffset: Double, _ xScale: Double, _ yOffset: Double, _ yScale: Double) -> CGPoint {
    return CGPoint(
        x:       (Double(v.x) - xOffset) / xScale,
        y: 1.0 - (Double(v.y) - yOffset) / yScale
    )
}

private func vectorDiff(_ v1: CGPoint, _ v2: CGPoint) -> Float {
    return Float(pow(v1.x - v2.x, 2.0) + pow(v1.y - v2.y, 2.0))
}

func applyDelta(sceneView: SCNView, deltaX: Float, deltaY: Float, deltaScale: Float, deltaYaw: Float, deltaRoll: Float, deltaPitch: Float) {
    guard let scene = sceneView.scene else { return }
    
    let head = scene.rootNode.childNode(withName: "Head", recursively: true)!
    head.position = SCNVector3(
        x: head.position.x + deltaX,
        y: head.position.y + deltaY,
        z: 0
    )
    head.eulerAngles = SCNVector3(
        x: head.eulerAngles.x + deltaPitch,
        y: head.eulerAngles.y + deltaYaw,
        z: head.eulerAngles.z + deltaRoll
    )
    head.scale = SCNVector3(
        x: 1.0 + deltaScale,
        y: 1.0 + deltaScale,
        z: 1.0 + deltaScale
    )
}
