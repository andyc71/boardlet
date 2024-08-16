//
//  TopicContextMenu.swift
//  PECS Maker
//
//  Created by Andy on 15/12/2022.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import LazyViewSwiftUI
import SwiftUIX

/*
struct PhotoAction : Equatable {
    enum Action : Equatable { case view, rename, duplicate, delete }
    var action: Action
    var photo: PhotoItem
    init(_ photo: PhotoItem, _ action: Action) {
        self.photo = photo
        self.action = action
    }
}
 */

typealias PhotoAction = PhotoCellAction

extension View {
    
    @ViewBuilder
    func photoContextMenuItems(for photo: PhotoItem, photoAction: Binding<PhotoAction<PhotoItem>?>) -> some View {
        
        //Prior to IOS 16 we have 2 problems with ContextMenu:
        //1. AccessibilityIdentifier is completely lost
        //2. The first items shows up as "disabled" in Accessibility Instpector. To workaround this
        //we put the topic name as a label as the first item because it doesn't matter that this is
        //disabled.
        if #unavailable(iOS 16.0) {
            if let title = photo.title {
                //TODO: Have an "untitled" string as well.
                Text(title)
            }
        }
        
        Button(L10n.TopicContextMenu.editButton, systemImage: SFSymbolName.eye) {
            photoAction.wrappedValue = PhotoAction(photo, .tap)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.editButton)
        
        Button(L10n.TopicContextMenu.renameButton, systemImage: SFSymbolName.pencil) {
            photoAction.wrappedValue = PhotoAction(photo, .rename)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.renameButton)
        
        Button(L10n.TopicContextMenu.duplicate, systemImage: SFSymbolName.plusSquareOnSquare) {
            photoAction.wrappedValue = PhotoAction(photo, .duplicate)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.duplicateButton)
                
        DestructiveButton(L10n.TopicContextMenu.deleteButton, systemImage: SFSymbolName.trash) {
            photoAction.wrappedValue = PhotoAction(photo, .delete)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.deleteButton)
    }
    
    @ViewBuilder
    func photoCellContextMenu(for photo: PhotoItem, photoAction: Binding<PhotoAction<PhotoItem>?>) -> some View {
        if #available(iOS 16.0, *) {
            contextMenu {
                photoContextMenuItems(for: photo, photoAction: photoAction)
            } preview: {
                Image(uiImage: photo.image)
                    .resizable()
                //.frame(minWidth: 300, maxWidth: 500, maxHeight: 500)
                    .aspectRatio(contentMode: .fit)
            }
        } else {
            contextMenu {
                photoContextMenuItems(for: photo, photoAction: photoAction)
            }
        }
    }
    
    
}
