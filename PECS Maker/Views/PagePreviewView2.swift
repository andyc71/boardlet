//
//  PagePreviewView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI
import Combine
import AVKit
import PhotoPicker

var rowCount = 2
var colCount = 2

struct PagePreviewView: View {
    
    @State
    private var datas: [PhotoPickerData?] = []
    
    @State
    private var isShowingPicker = false
    
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text("Page Preview:")
                    .font(.headline)
                Spacer()
                Button("Select Photos", action: {
                    self.isShowingPicker = true
                })
            }
            
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                ForEach(datas.enumerated().map { ($0, $1) }, id: \.0) { i, data in
                    if let image = data?.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            //.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    else if let videoURL = data?.video {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(width: 200, height: 200, alignment: .center)
                    }
                    else if let livePhoto = data?.livePhoto {
                        LivePhotoView(livePhoto: .constant(livePhoto))
                    }
                }
            }
            
            
            .frame(maxHeight: .infinity)
            .padding()
            .border(Color(UIColor.secondaryLabel), width: 1)
        }
        .frame(maxHeight: .infinity)
        .sheet(isPresented: $isShowingPicker) {
                    PhotoPicker(
                        datas: $datas,
                        configuration: pickerConfig,
                        pattern: pickerPattern
                    )
                }
        
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PagePreviewView()
    }
}
