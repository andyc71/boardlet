import SwiftUI
import PhotosUI
import Combine
import LogFramework

/// `PHPickerViewController` wrapper for SwiftUI.
public struct PhotoPicker: UIViewControllerRepresentable
{
    @Binding
    public var datas: [PhotoPickerData?]

    private var configuration: PHPickerConfiguration
    private let pattern: PickerPattern

    @Environment(\.presentationMode)
    private var presentationMode

    public init(
        datas: Binding<[PhotoPickerData?]>,
        configuration: PHPickerConfiguration,
        pattern: PickerPattern
    )
    {
        self._datas = datas
        self.configuration = configuration
        
        
        if #available(iOS 15, *) {
            var preselectedIdentifiers = [String]()
            for item in datas {
                if let id = item.wrappedValue?.assetIdentifier {
                    preselectedIdentifiers.append(id)
                }
            }
            self.configuration.preselectedAssetIdentifiers = preselectedIdentifiers
            /*
            self.configuration.preselectedAssetIdentifiers = datas.compactMap { $0.wrappedValue?.assetIdentifier }
             */
            let count = self.configuration.preselectedAssetIdentifiers.count
            print("Count \(count)")
        }
        self.pattern = pattern
        MFAnalytics.logScreenView(screenName: "PhotoPicker")
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController
    {
        let vc = PHPickerViewController(configuration: configuration)
        vc.delegate = context.coordinator
        return vc
    }
    
    private func printViewHierarchy(_ parent: UIView, level: Int) {
        
        if level == 0 {
            print("*****Photo Picker view hierarchy*****")
        }

        var levelString = ""
        for _ in 0..<level {
           levelString += "  "
        }
        
        for child in parent.subviews {
            //print("*****\(child.accessibilityIdentifier) - \(child.accessibilityValue)")
            //print("*****\(levelString)\(child.accessibilityIdentifier) - \(child.accessibilityValue)")
            print("\(levelString)\(type(of: child))")
            printViewHierarchy(child, level: level + 1)
        }
        
    }
    
    public func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    )
    {
        let vc: UIViewController = uiViewController
        printViewHierarchy(vc.view, level: 0)
    }

    public func makeCoordinator() -> Coordinator
    {
        Coordinator(self)
    }

    // MARK: - Coordinator

    public class Coordinator: PHPickerViewControllerDelegate
    {
        private let parent: PhotoPicker

        private var cancellables: Set<AnyCancellable> = .init()

        init(_ parent: PhotoPicker)
        {
            self.parent = parent
        }

        public func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        )
        {
            
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
            
            if results.isEmpty {
                DispatchQueue.main.async {
                    self.parent.datas = []
                }
            }
            
            //Remove any items that have been deselected. We have to do this because
            //the results set when enumerated will only return newly selected items.
            let identifiers = results.compactMap(\.assetIdentifier)
            //print(identifiers)
            for index in parent.datas.indices.reversed() {
                guard let id = parent.datas[index]?.assetIdentifier else {
                    DispatchQueue.main.async { self.parent.datas.remove(at: index) }
                    continue
                }
                if !identifiers.contains(where: {$0 == id }) {
                    parent.datas.remove(at: index)
                }
            }
            
            //self.parent.datas.removeAll()
            for result in results {
                let prov = result.itemProvider
                
                //Make sure we don't already have it in the list.
                if let id = result.assetIdentifier {
                    if parent.datas.contains(where: {$0?.assetIdentifier == id }) {
                        continue
                    }
                }
                
                //Load the image
                prov.loadObject(ofClass: UIImage.self) { imageMaybe, errorMaybe in
                    if let image = imageMaybe as? UIImage {
                        let data = _PhotoPickerData.image(image, result.assetIdentifier)
                        DispatchQueue.main.async {
                            self.parent.datas.append(data)
                        }

                    }
                }
            }

            /*
            
            parent.pattern.makePublisher(results: results)
                .sink(receiveValue: { (datas: [PhotoPickerData?]) in
                    DispatchQueue.main.async {
                        self.parent.datas = datas
                    }
                })
                .store(in: &cancellables)
             */
        }
    }
}
