//
//  ViewController.swift
//  NSImageRepLeakTest
//
//  Created by Pierre Tacchi on 07/12/21.
//

import Cocoa
import UniformTypeIdentifiers

class ViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    
    @objc dynamic var imageLoaded = false
    
    @objc dynamic var imagePoints: String = ""
    @objc dynamic var imagePixels: String = ""
    @objc dynamic var imageBytes: Int = 0
    
    @IBAction func capture(_ sender: Any) {
        guard
            let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)
        else { return print("Nope, no NSBitmapImageRep for you!") }
        
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        let image = NSImage(size: bitmapRep.size)
        image.addRepresentation(bitmapRep)

        imageView.image = image
        imageLoaded = true
        imagePoints = "Points: \(Int(bitmapRep.size.width))×\(Int(bitmapRep.size.height))"
        imagePixels = "Pixels: \(Int(bitmapRep.pixelsWide))×\(Int(bitmapRep.pixelsHigh))"
        imageBytes = bitmapRep.bytesPerPlane * bitmapRep.numberOfPlanes
    }
    
    @IBAction func clearImage(_ sender: Any) {
        imageView.image = nil
        imageLoaded = false
        imagePoints = ""
        imagePixels = ""
        imageBytes = 0
    }
    
    @IBAction func saveImage(_ sender: Any) {
        guard let window = view.window else { return print("No window, strange...") }
        
        let panel = NSSavePanel()
        
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        panel.nameFieldStringValue = "Capture.png"
        
        panel.beginSheetModal(for: window) { response in
            guard
                response == .OK,
                let dstURL = panel.url,
                let imageRep = self.imageView.image?.representations.first as? NSBitmapImageRep,
                let pngData = imageRep.representation(using: .png, properties: [:])
            else { return }
            
            if case .failure(let err) = self.write(pngData: pngData, to: dstURL) {
                self.presentError(err, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                print("*** Image succesfully written to \(dstURL.path)")
            }
        }
    }
    
    private func write(pngData: Data, to url: URL) -> Result<(), NSError> {
        var coordinatorError: NSError?
        var writerError: NSError?
        
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: [.forReplacing], error: &coordinatorError) { url in
            do {
                try pngData.write(to: url)
            } catch let we as NSError {
                writerError = we
            }
        }
        
        return writerError.map(Result.failure) ?? coordinatorError.map(Result.failure) ?? .success(())
    }
}

