//
//  VC+Zoom.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/10/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import AVKit

extension ViewController {
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let device = backCameraDevice else { return }
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(gesture.scale * lastZoomFactor)
        
        switch gesture.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
}
