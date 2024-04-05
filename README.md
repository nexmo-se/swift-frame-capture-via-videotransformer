Camera Capture via Custom Video Transformer 
======================

The Video Transformers app is a very simple application created on top of Basic Video Chat that shows how to capture a Video frame via Media Processor APIs on OpenTok iOS SDK. 

This creates a custom video transformer to apply to published video. It includs a method to capture a video frame and saves it to the photo gallery.

Adding the OpenTok library
==========================
In this example the OpenTok iOS SDK was not included as a dependency,
you can do it through Swift Package Manager or Cocoapods.


Swift Package Manager
---------------------
To add a package dependency to your Xcode project, you should select 
*File* > *Swift Packages* > *Add Package Dependency* and enter the repository URL:
`https://github.com/opentok/vonage-client-sdk-video.git`.


Cocoapods
---------
To use CocoaPods to add the OpenTok library and its dependencies into this sample app
simply open Terminal, navigate to the root directory of the project and run: `pod install`.


The Video-Transformers app is a very simple application meant to get a new developer
started using the OpenTok iOS SDK.
