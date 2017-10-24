//
//  ViewController+Drag.swift
//  ARKitExample
//
//  Created by Andreas Dias on 10/19/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController : UIDragInteractionDelegate {
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let image = preview.image else {
            return []
        }

        print("draggin")

        let provider = NSItemProvider(object: image)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = image

        // add context to the drag sessions so that we know what UIImageView this drag started from
        session.localContext = preview

        return [item]
    }
}

