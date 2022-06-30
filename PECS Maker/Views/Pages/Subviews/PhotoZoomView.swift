//
//  PhotoZoomView.swift
//  PECS Maker
//
//  Created by Andy on 28/06/2022.
//

import SwiftUI

struct PhotoZoomView: View {
    var image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)
    }
}

struct PhotoZoomView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoZoomView(image: UIImage(systemName: "music.note")!)
    }
}
