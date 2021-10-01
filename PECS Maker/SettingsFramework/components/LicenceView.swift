//
//  LicenceView.swift
//  SwiftUI Settings Screen
//
//  Created by Andy Clynes on 08/09/20.
//  Copyright © 2020 Andy Clynes. All rights reserved.
//

import SwiftUI
import SwiftUIX
import LogFramework

class LicenceViewModel : ObservableObject {

    @Published var licenceText: String = ""

    init (licenceFile: String) {
        loadFile(licenceFile)
    }
    
    func loadFile(_ file: String) {
        guard let filepath = Bundle.main.path(forResource: file, ofType: "txt") else {
            logger.logError(.general, "Error loading licence file named \(file)")
            return
        }
        
        do {
            let contents = try String(contentsOfFile: filepath)
            DispatchQueue.main.async {
                self.licenceText = contents
            }
        } catch let error as NSError {
            logger.logError(.general, "Error loading licence file named \(file)", error)
        }
    }

    
}

struct LicenceView: View {
    
    @ObservedObject var model: LicenceViewModel

    init (licenceFile: String) {
        self.model = LicenceViewModel(licenceFile: licenceFile)
    }
        
    var body: some View {
        
        TextView(NSAttributedString(string: model.licenceText))
            //.lineLimit(10)
            //.multilineTextAlignment(.leading)

    }
}


struct LicenceView_Previews: PreviewProvider {
    static var previews: some View {
        LicenceView(licenceFile: "mit")
            .frame(minWidth: .infinity, maxWidth: .infinity)
    }
}
