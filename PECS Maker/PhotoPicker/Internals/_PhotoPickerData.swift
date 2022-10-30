import UIKit
import Photos

enum _PhotoPickerData: PhotoPickerData
{
    case image(UIImage, String?)
    case video(URL?, String?)
    case livePhoto(PHLivePhoto, String?)

    var assetIdentifier: String?
    {
        guard case let .image(_, identifier) = self else { return nil }
        return identifier
    }
    
    var image: UIImage?
    {
        guard case let .image(value, _) = self else { return nil }
        return value
    }

    var video: URL?
    {
        guard case let .video(value, _) = self else { return nil }
        return value
    }

    var livePhoto: PHLivePhoto?
    {
        guard case let .livePhoto(value, _) = self else { return nil }
        return value
    }
}
