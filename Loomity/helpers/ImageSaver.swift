//
//  ImageSaver.swift
//  Looomity
//
//  Created by Michael Langbein on 26.12.22.
//

import SwiftUI

class ImageSaver: NSObject {
    
    private var onSuccess: () -> Void
    private var onError: (Error) -> Void
    
    init(onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            self.onError(error!)
        } else {
            self.onSuccess()
        }
    }
}
