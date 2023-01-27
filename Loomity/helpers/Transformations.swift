//
//  Transformations.swift
//  Loomity
//
//  Created by Michael Langbein on 25.01.23.
//

import Foundation
import SceneKit
import Vision


/**
        scene ----[ scene2clipping ] -----> clipping
         A                                                          |
         |                                                           |
      [image2scene]                               [clipping2screen]
         |                                                           |
         |                                                           V
        image  <--[screen2image]--- screen
          A
          |
    [landmark2image]
          |
        landmark
 
 */



func scene2clipping(_ v: SCNVector3, _ cameraWorldTransform: SCNMatrix4, _ cameraProjectionTransform: SCNMatrix4) -> SCNVector3 {
    
    let updatedProjectionMatrix = cameraProjectionTransform
//    if (updatedProjectionMatrix.m11 == updatedProjectionMatrix.m22) {
//        let arScreen = scene_w / scene_h
//        updatedProjectionMatrix.m11 = updatedProjectionMatrix.m11 * Float(arScreen)
//    }
    
    let viewMatrix = SCNMatrix4Invert(cameraWorldTransform)
    
    let v4 = SCNVector4(x: v.x, y: v.y, z: v.z, w: 1.0)
    let vCamPos = matMul(viewMatrix, v4)
    let vClip = matMul(updatedProjectionMatrix, vCamPos)
    let vClipNorm = SCNVector3(x: vClip.x / vClip.w, y: vClip.y / vClip.w, z: vClip.z / vClip.w)
    
    return vClipNorm
}


func clipping2screen(_ vClipNorm: SCNVector3, _ screenWidth: CGFloat, _ screenHeight: CGFloat) -> CGPoint {
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
    //    │            │         │         │             │   X = w_clip / 2
    //    │            │         │         │             │       w_clip = h_clip * ar
    //    │            │         │         │             │                h_clip = 2
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
    
    let ar = screenWidth / screenHeight
    var xClipMin = -1.0
    var xClipMax =  1.0
    var yClipMin = -1.0
    var yClipMax =  1.0
    if screenWidth > screenHeight { // landscape-orientation
        let wClip = 2.0
        let hClip = wClip / ar
        yClipMin = -hClip / 2.0
        yClipMax =  hClip / 2.0
    } else {
        let hClip = 2.0
        let wClip = hClip * ar
        xClipMin = -wClip / 2.0
        xClipMax =  wClip / 2.0
    }
    let xClipRange = xClipMax - xClipMin
    let yClipRange = yClipMax - yClipMin
    let xScreenRel = (Double(vClipNorm.x) - xClipMin) / xClipRange
    let yScreenRel = (Double(vClipNorm.y) - yClipMin) / yClipRange
    
    return CGPoint(x: xScreenRel, y: yScreenRel)
}


func screen2image(_ pScreenRel: CGPoint, _ imageWidth: CGFloat, _ imageHeight: CGFloat, _ screenWidth: CGFloat, _ screenHeight: CGFloat) -> CGPoint {
    
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
    if screenWidth > screenHeight { // landscape
        let uPerPixImg = 1.0 / imageWidth
        let img_w_u = imageHeight * uPerPixImg
        let uPerPixScreen = 1.0 / screenHeight
        let screen_w_u = screenWidth * uPerPixScreen
        let delta = (screen_w_u - img_w_u) / 2.0
        xOffset = delta
    } else {
        let uPerPixImg = 1.0 / imageWidth
        let img_h_u = imageHeight * uPerPixImg
        let uPerPixScreen = 1.0 / screenWidth
        let screen_h_u = screenHeight * uPerPixScreen
        let delta = (screen_h_u - img_h_u) / 2.0
        yOffset = delta
    }
    
    let xImgRel = (Double(pScreenRel.x) - xOffset) / (1.0 - 2.0 * xOffset)
    let yImgRel = (Double(pScreenRel.y) - yOffset) / (1.0 - 2.0 * yOffset)
    
    return CGPoint(
        x: xImgRel,
        y: yImgRel
    )
}


func landmark2image(_ point: CGPoint, _ boundingBox: CGRect) -> CGPoint {
    //        let xImg = rect.width * point.x + rect.origin.x
    //        let yImg = rect.height * point.y + rect.origin.y
    //        return CGPoint(x: xImg, y: yImg)
    let projected = VNImagePointForFaceLandmarkPoint(
        vector_float2(x: Float(point.x), y: Float(point.y)),
        boundingBox,
        1, 1 // Int(image.size.width), Int(image.size.height)
    )
    return projected
}


func image2scene(_ point: CGPoint, _ imageWidth: Int, _ imageHeight: Int, _ ortho: Bool = true) -> SCNVector3 {
    // @TODO: correction if not orthographic view
    
    let xImg = Float(point.x)
    let yImg = Float(point.y)

    let wImgScene: Float = 2.0
    let ar = Float(imageWidth) / Float(imageHeight)
    let hImgScene = wImgScene / ar

    let xScene = xImg * wImgScene - 1.0
    let yScene = (yImg * hImgScene) - (hImgScene / 2.0)
    let zScene: Float = 0.0
    return SCNVector3(x: xScene, y: yScene, z: zScene)
}

/**
 Much simpler than `scene2imageLong`, but doesn't account for perspective distortion
 which likely occurs on faces far off to the edges of the scene.
 Not a problem for ortho-view, though!
 */
func scene2image(_ point: SCNVector3, _ imageWidth: CGFloat, _ imageHeight: CGFloat) -> CGPoint {
    // @TODO: correction if not orthographic view
    
    let xScene = point.x
    let yScene = point.y
    
    let wImgScene: Float = 2.0
    let ar = Float(imageWidth / imageHeight)
    let hImgScene = wImgScene / ar
    
    let xImg = (xScene + 1.0) / wImgScene
    let yImg = (yScene + (hImgScene / 2.0)) / hImgScene
    
    // @TODO: where is this weird behaviour coming from?
    let weirdCorrectionFactor: Float = imageWidth > imageHeight ? 0.1: 0.05
    
    return CGPoint(x: Double(xImg), y: Double(yImg + weirdCorrectionFactor))
}



func interpolate(_ x: CGFloat, _ x0: CGFloat, _ x1: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> CGFloat {
    let fraction = (x - x0) / (x1 - x0)
    let y = y0 + fraction * (y1 - y0)
    return y
}

func scene2imagePerspective(
    _ point: SCNVector3,
    _ imageWidth: CGFloat, _ imageHeight: CGFloat,
    _ sceneWidth: CGFloat, _ sceneHeight: CGFloat,
    _ cameraWorldTransform: SCNMatrix4, _ cameraProjectionTransform: SCNMatrix4) -> CGPoint {
    
            
//        var cameraProjectionTransformWithAR = cameraProjectionTransform
//        if  cameraProjectionTransformWithAR.m11 ==  cameraProjectionTransformWithAR.m22 {
//            let ar = Float(sceneWidth / sceneHeight)
//            cameraProjectionTransformWithAR.m11 *= ar
//        }
        
        let clippingPos = scene2clipping(point, cameraWorldTransform, cameraProjectionTransform)
            
        let xImg = interpolate(CGFloat(clippingPos.x), -0.5, 0.5, 0.0, 1.0)
        let hImgClipping = imageHeight / imageWidth
        let yClipMin: CGFloat = -hImgClipping / 2.0
        let yClipMax: CGFloat =  hImgClipping / 2.0
        let yImg = interpolate(CGFloat(clippingPos.y), yClipMin, yClipMax, 0.0, 1.0)
        return CGPoint(x: xImg, y: yImg)
        
//    let screenPos = clipping2screen(clippingPos, screenWidth, screenHeight)
//    let imgPos = screen2image(screenPos, imageWidth, imageHeight, screenWidth, screenHeight)
//    return imgPos
}




func obsBboxCenter2Scene(boundingBox: CGRect, imageWidth: CGFloat, imageHeight: CGFloat) -> SCNVector3 {
    
    //        ImageRelative               SceneKit               ImageRel    Scene
    //
    //     1  ▲                               ▲ 1/ar                    1 ▲ 1/ar
    //        │                               │                           │
    //        │                             1 │                           │ 1
    //        │                               │                           │
    //        │                               │                           │
    //        │                     -1        │        1                  │
    //        │                     ◄─────────┼────────►                  │ 0
    //        │                               │                           │
    //        │                               │                           │
    //        │                               │                           │
    //        │                            -1 │                           │ -1
    //        │                               │                           │
    //     0  └─────────────►                 ▼ -1/ar                   0 ▼ -1/ar
    //        0             1
    //
    //                       Scene
    //                       -1        0         1
    //                       ◄───────────────────►
    //                       0                   1
    //                       ImageRel
    
    let ar = imageWidth / imageHeight
    
    let leftImg   = Float(boundingBox.minX)
    let rightImg  = Float(boundingBox.maxX)
    let topImg    = Float(boundingBox.maxY)
    let bottomImg = Float(boundingBox.minY)
    
    let wImg   = rightImg - leftImg
    let hImg   = topImg - bottomImg
    let xImg   = leftImg   + wImg / 2.0
    let yImg   = bottomImg + hImg / 2.0
    let xScene = 2.0 * xImg - 1.0
    let yScene = (2.0 * yImg - 1.0) / Float(ar)
    let cWorld = SCNVector3(x: xScene, y: yScene, z: 0)
    
    return cWorld
}



func fitImageIntoScene(width_screen: CGFloat, height_screen: CGFloat, width_img: CGFloat, height_img: CGFloat) -> CGSize {
    // verified to work correctly.
    
    let ar_screen = width_screen / height_screen
    let ar_img = width_img / height_img
    var w_img_clip: CGFloat = 1.0
    var h_img_clip: CGFloat = 1.0
    
//        Assumes that clipping space is fully contained within the screen
//        and reaches values over 1 along the screen's longer side.
//        if width > height {
//            let h_screen_clip: CGFloat = 2.0
//            let w_screen_clip = h_screen_clip * ar_screen
//            h_img_clip = h_screen_clip
//            w_img_clip = h_img_clip * ar_img
//        } else {
//            let w_screen_clip: CGFloat = 2.0
//            let h_screen_clip = w_screen_clip / ar_screen
//            w_img_clip = w_screen_clip
//            h_img_clip = w_img_clip / ar_img
//        }
    
//      Assumes that clipping space bleeds out of the screen's shorter side and is clipped off
    if width_screen > height_screen {
        let w_screen_clip: CGFloat = 2.0
        let h_screen_clip = w_screen_clip / ar_screen
        h_img_clip = h_screen_clip
        w_img_clip = h_img_clip * ar_img
    } else {
        let h_screen_clip: CGFloat = 2.0
        let w_screen_clip = h_screen_clip * ar_screen
        w_img_clip = w_screen_clip
        h_img_clip = w_img_clip / ar_img
    }
    
    return CGSize(width: w_img_clip, height: h_img_clip)
}
