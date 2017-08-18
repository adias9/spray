//
//  Line.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class Line {
    
    var segments: [Segment] = []
    
    struct Segment {
        var start: CGPoint?
        var end: CGPoint?
        init(start: CGPoint, end: CGPoint) {
            self.start = start
            self.end = end
        }
    }
    
    init() {
        
    }
    
    func appendSegment(start: CGPoint, end: CGPoint) {
        let segment = Segment(start: start, end: end)
        segments.append(segment)
    }
    
}
