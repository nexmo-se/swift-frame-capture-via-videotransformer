//
//  ViewController.swift
//  Custom Frame Capture via Media Transformers
//
//  Created by Beejay Urzo April 1, 2024
//  Vonage CSE

import UIKit
import OpenTok

// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = ""
// Replace with your generated session ID
let kSessionId = ""
// Replace with your generated token
let kToken = ""

let kWidgetHeight = 240
let kWidgetWidth = 320

class FrameCap: NSObject, OTCustomVideoTransformer {
    var saveImage: Bool = false
   
    func transform(_ videoFrame: OTVideoFrame) {
        
        //when getImage is triggered, we get the frame. We immediately set the saveImage flag to false
        //so we don't process succeeding frames. We could have created a deep copy of videoFrame here
        //but for some reason OTVideoFrame.copy points to copyWithZone and it's not implemented
        if(saveImage){
            saveImage = false
            videoFrame.orientation = OTVideoOrientation.left
            var width: Int = Int(videoFrame.format!.imageWidth)
            let height: Int = Int(videoFrame.format!.imageHeight)
            //let's store the original width so we can remove the excess later in case we square off the image
            let origWidth: Int = width
            //if it's a portrait image, we square it off first
            if (width<height){
                
                width = height
            }
            getImageProcess(frame: videoFrame, width: width, height: height, origWidth: origWidth)
            
        }
    }
    
    func getImage(){
        //we use this to trigger the image copy
        saveImage = true
    }
    
    func getImageProcess(frame: OTVideoFrame, width: Int, height: Int, origWidth: Int){
       
        let ystride: Int = Int(frame.getPlaneStride(0))
        let uvstride: Int = Int(frame.getPlaneStride(1))
        var pos: Int = 0
        
        let pixelAttributes = [
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            pixelAttributes as CFDictionary,
            &pixelBuffer)

        
        CVPixelBufferLockBaseAddress(pixelBuffer!, [])
        let yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
        var rowStart: Int = 0
        pos = 0
        for _ in 0...(Int(height)-1){
            memcpy(yDestPlane!+pos, (frame.planes?.pointer(at: 0))!+rowStart, ystride)
            rowStart+=Int(ystride)
            pos+=width
        }
        
        let uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
        pos = 0
        rowStart = 0
        for _ in 0...((height / 2)-1){
            for c in 0...((width/2)-1){
                if(c<uvstride){memcpy(uvDestPlane!+pos, (frame.planes?.pointer(at: 1))!+rowStart+c, 1)}
                pos+=1
                if(c<uvstride){memcpy(uvDestPlane!+pos, (frame.planes?.pointer(at: 2))!+rowStart+c, 1)}
                pos+=1
            }
            rowStart+=Int(uvstride)
            
        }
        

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.ArrayLiteralElement())

        if result != kCVReturnSuccess {
            print("Unable to create cvpixelbuffer \(result)")
        }

        // CIImage Conversion
        let coreImage = CIImage(cvPixelBuffer: pixelBuffer!)
        
        let MytemporaryContext = CIContext(options: nil)
        let MyvideoImage = MytemporaryContext.createCGImage(
            coreImage,
            from: CGRect(x: 0, y: 0, width: origWidth, height: height))

        // UIImage Conversion
        var Mynnnimage: UIImage?
        if let MyvideoImage {
            Mynnnimage = UIImage(
                cgImage: MyvideoImage,
                scale: 1.0,
                orientation: .up)
        
            UIImageWriteToSavedPhotosAlbum(Mynnnimage!, nil, nil, nil)
        }
       
        var test: Bool
        test = OTPixelFormat.I420 == frame.format?.pixelFormat
        print(test)
        saveImage = false
        return
    }

}

class ViewController: UIViewController {
    
    var buttonFrameCap: UIButton!
    let frameCap: FrameCap = FrameCap() // Create an instance of CustomTransformer
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    
    
    var subscriber: OTSubscriber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doConnect()
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if error != nil {
            fatalError("An error occurred: \(String(describing: error))")
        }
        
        if let pubView = publisher.view {
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
        
        guard let myCustomTransformer = OTVideoTransformer(name: "frameCap", transformer: frameCap)  else { return }
        var myVideoTransformers = [OTVideoTransformer]()
        myVideoTransformers.append(myCustomTransformer)
        publisher.videoTransformers = myVideoTransformers
        
        // Configure toogle button
        buttonFrameCap = UIButton(type: .custom)
        buttonFrameCap.frame = CGRect(x: kWidgetWidth - 65, y: 50, width: 50, height: 25)
        buttonFrameCap.layer.cornerRadius = 5.0
        self.view.addSubview(buttonFrameCap)
        self.view.bringSubviewToFront(buttonFrameCap)
        buttonFrameCap.setTitle("Capture", for: .normal)
        buttonFrameCap.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        buttonFrameCap.setTitleColor(.gray, for: .normal)
        buttonFrameCap.backgroundColor = .white
        buttonFrameCap.layer.borderWidth = 1.0
        buttonFrameCap.layer.borderColor = UIColor.gray.cgColor
        buttonFrameCap.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    

    @objc func buttonTapped(_ sender: UIButton) {
        frameCap.getImage()
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
