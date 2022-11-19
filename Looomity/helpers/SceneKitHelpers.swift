//
//  SceneKitHelpers.swift
//  Looomity
//
//  Created by Michael Langbein on 11.11.22.
//

import SceneKit


/// Calculate world-coordinates of head
/// - parameter w: width of head in meters
/// - parameter h: height of head in meters
/// - parameter ar: aspect ratio. Assumed to be the same for SCNScene and UIImage.
/// - parameter projectionT: transforms from camera-space into clipping-space
/// - parameter viewT: transforms from world-space into camera-space
/// - parameter (top, right, bottom, left)Img: [0, 1]^2, x from left to right, y from bottom to top
func getHeadPosition(
    w: Float, h: Float, ar: Float,
    topImg: Float, rightImg: Float, bottomImg: Float, leftImg: Float,
    projectionTransform: SCNMatrix4, viewTransform: SCNMatrix4
) -> SCNVector4 {
    
    //----------------------------
    // Calculating head-position
    //----------------------------
    
    var updatedProjectionTransform = projectionTransform
    if (updatedProjectionTransform.m11 == updatedProjectionTransform.m22) {
        print("accounting for aspect ratio")
        updatedProjectionTransform.m11 = updatedProjectionTransform.m11 / ar
    }
    
    // Face-bbox: from relative-image-coordinates to clipspace-x and y.
    let top     =  2.0 * topImg     - 1.0
    let bottom  =  2.0 * bottomImg  - 1.0
    let right   =  2.0 * rightImg   - 1.0
    let left    =  2.0 * leftImg    - 1.0
    
    // Placing face-bbox in clip-space [x, y, 1, 1]
    let tl = imageSpace2ClipSpace(left, top)
    let tr = imageSpace2ClipSpace(right, top)
    let br = imageSpace2ClipSpace(right, bottom)
    let bl = imageSpace2ClipSpace(left, bottom)
    
    // Getting central point c. A ray will be cast through c to the head's actual position
    let aClip = midpoint(tl, bl)
    let bClip = midpoint(tr, br)
    let cClip = midpoint(aClip, bClip)
    let dClip = midpoint(tl, tr)
    let eClip = midpoint(bl, br)
    let fClip = midpoint(dClip, eClip)
    
    // Projecting out of clipping space into camera space.
    // Accounts for focal length, near and far, and aspect-ratio.
    // (Actually not so sure about the latter. Transformation matrices seem to always have m11 == m22 ...)
    // Results are not points, but directions (their w == 0)
    let projectionInverse = SCNMatrix4Invert(updatedProjectionTransform)
    let a = matMul(projectionInverse, aClip)  // direction towards point a
    let b = matMul(projectionInverse, bClip)  // direction towards point b
    let c = matMul(projectionInverse, cClip)  // direction towards point c
    let d = matMul(projectionInverse, dClip)
    let e = matMul(projectionInverse, eClip)
    let f = matMul(projectionInverse, fClip)
    
    let magA = magnitude(a)
    let magB = magnitude(b)
    let magC = magnitude(c)
    let magD = magnitude(d)
    let magE = magnitude(e)
    let magF = magnitude(f)
    
    // Angle between a and b.
    // Used to calculate at what distance from origin the head must be.
    // Assumes that the head-bounding-box is orthogonal to the ray towards c.
    let sigma = acos( dot(a, b) / (magA * magB) )
    let l = w / (2.0 * tan(sigma / 2.0))
    // angle between d and e.
    let sigma2 = acos( dot(d, e) / (magD * magE) )
    let l2 = h / (2.0 * tan(sigma2 / 2.0))
    
    // Scaling normalized c by l
    let cNorm = scalarProd(1.0 / magC, c)
    let cCam = scalarProd(l, cNorm)
    let fNorm = scalarProd(1.0 / magF, f)
    let fCam = scalarProd(l2, fNorm)
    
    // Transforming out of camera-space into world-space
    let viewInverse = SCNMatrix4Invert(viewTransform)
    let cWorld = matMul(viewInverse, cCam)
    let fWorld = matMul(viewInverse, fCam)
    
    let ray = midpoint(cWorld, fWorld)
    
    return ray
}

func matMul(_ matrix: SCNMatrix4, _ vector: SCNVector4) -> SCNVector4 {
    
    // matrices in Scenekit are OpenGL-oriented ... that is: column/row
    let row1 = SCNVector4(x: matrix.m11, y: matrix.m21, z: matrix.m31, w: matrix.m41)
    let row2 = SCNVector4(x: matrix.m12, y: matrix.m22, z: matrix.m32, w: matrix.m42)
    let row3 = SCNVector4(x: matrix.m13, y: matrix.m23, z: matrix.m33, w: matrix.m43)
    let row4 = SCNVector4(x: matrix.m14, y: matrix.m24, z: matrix.m34, w: matrix.m44)
    
    let x = dot(row1, vector)
    let y = dot(row2, vector)
    let z = dot(row3, vector)
    let w = dot(row4, vector)

    return SCNVector4(
        x: x, y: y, z: z, w: w
    )
}

func imageSpace2ClipSpace(_ x: Float, _ y: Float) -> SCNVector4 {
    return SCNVector4(
        x: x,
        y: y,
        z: 1,
        w: 1
    )
}


func midpoint(_ v1: SCNVector4, _ v2: SCNVector4) -> SCNVector4 {
    return SCNVector4(
        x: (v1.x + v2.x) / 2.0,
        y: (v1.y + v2.y) / 2.0,
        z: (v1.z + v2.z) / 2.0,
        w: (v1.w + v2.w) / 2.0
    )
}

func dot(_ v1: SCNVector4, _ v2: SCNVector4) -> Float {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w
}

func magnitude(_ v: SCNVector4) -> Float {
    return sqrtf(dot(v, v))
}

func scalarProd(_ scalar: Float, _ vec: SCNVector4) -> SCNVector4 {
    return SCNVector4(
        x: scalar * vec.x,
        y: scalar * vec.y,
        z: scalar * vec.z,
        w: scalar * vec.w
    )
}


func applyCustomShader(_ node: SCNNode) {
    node.geometry?.firstMaterial?.transparencyMode = .aOne
    node.geometry?.shaderModifiers = [
        SCNShaderModifierEntryPoint.fragment : """
            #pragma transparent
            #pragma body
            float whiteness = (_output.color.r + _output.color.g + _output.color.b) / 3.0;
            // both rgb and a range from 0 to 1
            // a = 0.0: transparent
            // a = 1.0: opaque
            _output.color.a = 1.0 - whiteness;
        """
    ]
    for child in node.childNodes {
        applyCustomShader(child)
    }
}

