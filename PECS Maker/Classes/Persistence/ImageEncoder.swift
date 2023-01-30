//
//  ImageEncoder.swift
//  PECS Maker
//
//  Created by Andy on 31/07/2022.
//

import UIKit
import LogFramework

public struct ImageEncoderError : Error {
    public var message: String
    public init(message: String) {
        self.message = message
        
    }
}

public class ImageEncoder {
    
//    var directory: URL
//
//    init(directory: URL) {
//        self.directory = directory
//    }
//
//    init() {
//        self.directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
    
    public enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    public enum ImageFormat {
        case jpeg(quality: JPEGQuality)
        case png
    }
    
    private static func getImageData(image: UIImage, format: ImageFormat) throws -> Data {
        switch format {

        case .png:
            guard let imageData = image.pngData() else {
                let message = "Could not get PNG data from image"
                logger.logError(.repo, message)
                throw ImageEncoderError(message: message)
            }
            return imageData

        case .jpeg(let quality):
            guard let imageData = image.jpegData(compressionQuality: quality.rawValue) else {
                let message = "Could not get JPEG data from image"
                logger.logError(.repo, message)
                throw ImageEncoderError(message: message)
            }
            return imageData
        }
    }
    
    //JPEG will give smaller files, but PNG preserves transparency.
    //Be aware that PNG will roatate a RAW file so we need to find a workaround.
    public static func save(image: UIImage, to imageURL: URL, format: ImageFormat = .jpeg(quality: .high)) throws {

        let imageData = try getImageData(image: image, format: format)
        
        do {
            try imageData.write(to: imageURL)
        } catch {
            let message = "Could not save image data to \(imageURL.path)"
            logger.logError(.repo, message,  error)
            throw ImageEncoderError(message: message)
        }
        
    }
    
    public static func load(from imageURL: URL) throws -> UIImage? {
        let imageData = try Data(contentsOf: imageURL)
        //let image = UIImage(contentsOfFile: imageURL.path)
        let image = UIImage(data: imageData)
        return image
    }
}

