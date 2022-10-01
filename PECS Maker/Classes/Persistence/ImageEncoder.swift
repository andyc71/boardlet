//
//  ImageEncoder.swift
//  PECS Maker
//
//  Created by Andy on 31/07/2022.
//

import UIKit
import LogFramework

public struct ImageEncoderError : Error {
    var message: String
}

public class ImageEncoder {
    
    var directory: URL
    
    init(directory: URL) {
        self.directory = directory
    }
    
    init() {
        self.directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @discardableResult func save(image: UIImage, fileName: String) throws -> URL {
        let docURL = directory
        let imageURL = docURL.appendingPathComponent(fileName)
        guard let imageData = image.pngData() else {
            let message = "Could not load image data from \(imageURL.path)"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        //let imageData = image.jpegData(compressionQuality: .)
        //let imageData = image.base64EncodedData()
        do {
            // Save the 'Products' data file to the Documents directory.
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            let message = "Could not load image data from \(imageURL.path)"
            logger.logError(.repo, message,  error)
            throw ImageEncoderError(message: message)
        }
    }
    
    func load(fileName: String) throws -> UIImage? {
        let docURL = directory
        let imageURL = docURL.appendingPathComponent(fileName)
        let imageData = try Data(contentsOf: imageURL)
        //let image = UIImage(contentsOfFile: imageURL.path)
        let image = UIImage(data: imageData)
        return image
    }
}

