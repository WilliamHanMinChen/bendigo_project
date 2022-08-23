//
//  ViewController.swift
//  Bendigo Project
//
//  Created by William Chen on 2022/8/23.
//

import UIKit
import RealityKit
import ARKit
import SceneKit
import AVFoundation
import Darwin

class ViewController: UIViewController, ARSessionDelegate, AVAudioPlayerDelegate  {

    //The view handling all AR interactions
    @IBOutlet var arView: ARView!
    
    //Records down the time when we last gave haptic feedback
    var lastImapctTime: Date = Date()
    
    //Ratio of impact time, smaller value = faster haptic feedback
    var impactRatio = 3.0
    
    //Hpatic feedback engine
    let hardImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    //The audio player for description
    var descriptionAudioPlayer: AVAudioPlayer?
    
    //The audio players for the different layers of sound
    var closeAudioPlayer: AVAudioPlayer?
    var mediumAudioPlayer: AVAudioPlayer?
    var farAudioPlayer: AVAudioPlayer?
    
    
    //Keeps track of whether we are already playing media or not
    var playing: Bool = false
    
    //Keeps track of whether we are currently playing layered sound or not
    var farLayerPlaying: Bool = false
    var mediumLayerPlaying: Bool = false
    var closeLayerPlaying: Bool = false
    
    
    //Keeps track of which anchor we are currently playing description for
    var currentDescriptionAnchor: ARAnchor?
    
    //Keeps track of which anchor we are playing the layered sound for
    var currentLayerAnchor: ARAnchor?
    
    //Boolean value to indicate whether there is only one image on the screen or not
    var oneImageOnScreen: Bool = false
    
    //This value indicates in meters how close the user has to be for our app to count as "they are looking" at the painting
    let FOCUS_DISTANCE = 0.75
    
    //Keeps track of the first swipe down time since going to the connect me page requires two
    var firstSwipeDownTime: Date?
    
    //Variable to keep track of which filter we are at rightnow
    var filterIndex: Int = 0
    
    //Keeps track of the number of filters we have
    var numberOfFilters: Int = 4
    
    //Success sound to be played
    let systemSoundID: SystemSoundID = 1407
    
    //Distionary holding all the URLs to the descripition audio files
    var audioDictionary : [String: String] = [
        "bridge":                        "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/london.m4a?alt=media&token=99792e4d-8966-4149-97c7-c43aad5d3523",
        "rapallo" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/fortress.m4a?alt=media&token=c8e18851-f6b8-4e9c-8f45-9a2e97826fe7",
        "woman": "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/woman.m4a?alt=media&token=48ff1ced-55ed-4472-aade-10db846fac14",
        "polygon": "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/woman.m4a?alt=media&token=48ff1ced-55ed-4472-aade-10db846fac14",
        "cow" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/a-cow-in-a-landscape.wav?alt=media&token=64b970e2-8e65-4e76-acb0-5e8498661864"]
    
    
    //Temporary dictionary to keep track of all the layers of audio
    var londonDictionary: [String: String] = [
        "close" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FLondon%20-%20Close.mp3?alt=media&token=114fceea-c45c-4cb7-9079-875bb31cc618",
        "medium" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FLondon%20-%20Medium.mp3?alt=media&token=1e2b6a62-5c2b-4c52-8a88-4e1025c980b3",
        "far" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FLondon%20-%20Far.mp3?alt=media&token=e7a7a3f2-55f7-450c-b6dd-96dbe1d89889"
        
    ]
    
    var fortressDictionary: [String: String] = [
        "close" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FFortress%20-%20Close.mp3?alt=media&token=e827718d-2b56-45fb-a971-aa631ca2f917",
        "medium" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FFortress%20-%20Medium.mp3?alt=media&token=b69e74a3-80fd-4234-be58-b61e21de3117",
        "far" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FFortress%20-%20Far.mp3?alt=media&token=f9fc69d8-47af-48f2-8e5f-393581fc8c69"
    ]
    
    var defaultDistionary: [String: String] = [
        "close" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FNoSound.mp3?alt=media&token=fa311080-c713-4579-aa28-3866f23305ee",
        "medium" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FNoSound.mp3?alt=media&token=fa311080-c713-4579-aa28-3866f23305ee",
        "far" : "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/Audio%20Files%2FNoSound.mp3?alt=media&token=fa311080-c713-4579-aa28-3866f23305ee"
    ]
    
    
    
    // MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadBox()
//        
//        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Setup the ARView
        //Configuration for tracking images and objects
        let configuration = ARWorldTrackingConfiguration()
        
        //Provide it with the reference objects
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        //Loads all the images its going to look for
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        
        
        //Provide it to the configuration
        configuration.detectionObjects = referenceObjects
        configuration.detectionImages = referenceImages

        //Give it a maximum number it can track at the same time
        configuration.maximumNumberOfTrackedImages = 10
        
        
        // Set ARView delegate so we can define delegate methods in this controller
        arView.session.delegate = self
        
        // Forgo automatic configuration to do it manually instead
        arView.automaticallyConfigureSession = false
        
        // Disable any unneeded rendering options
        arView.renderOptions = [.disableCameraGrain, .disableHDR, .disableMotionBlur, .disableDepthOfField, .disableFaceMesh, .disablePersonOcclusion, .disableGroundingShadows, .disableAREnvironmentLighting]
        
        //Run the session
        arView.session.run(configuration)
        
        //Add the swipe gesture recogniser
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeDown.direction = .down
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeLeft.direction = .left
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeRight.direction = .right
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeUp.direction = .up
        
        //Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        
        //Add the gesture recognisers
        arView.addGestureRecognizer(swipeDown)
        arView.addGestureRecognizer(swipeLeft)
        arView.addGestureRecognizer(swipeRight)
        arView.addGestureRecognizer(swipeUp)
        self.arView.addGestureRecognizer(tapGesture)
        
        //Allows gesture recognisers to work
        arView.isAccessibilityElement = true
        arView.accessibilityTraits = .allowsDirectInteraction
        
    }
    
    // MARK: ARView delegate methods
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
        //Loop through each of the added anchors
        for anchor in anchors{
            
            if let imageAnchor = anchor as? ARImageAnchor { //If it is an image anchor
                
                //Get the anchor and camera position
                let anchorPosition = imageAnchor.transform.columns.3
                guard let cameraPosition = session.currentFrame?.camera.transform.columns.3 else { fatalError("Could not get camera values") }
                
                //A line from camera to anchor (to measure the distance)
                let cameraToAnchor = cameraPosition - anchorPosition
                
                //Gets the reference image it found
                let referenceImage = imageAnchor.referenceImage
                
                guard let name = referenceImage.name else {
                    fatalError("This anchor does not have a name")
                }
                
                //Get the image
                var imageName = getImageName(anchorName: name)
                
                
                guard let url = getFilteredImageURL(imageName: imageName) else {
                    fatalError("Could not find the image file")
                }
                
                
                
                //Create a plane
                let mesh: MeshResource = .generatePlane(width: Float(referenceImage.physicalSize.width), depth: Float(referenceImage.physicalSize.height))
                
                let refImageAnchor = AnchorEntity(anchor: imageAnchor)
                
                var material = UnlitMaterial()
                do {
                    //Load the image
                    let texture = try TextureResource.load(contentsOf: url)
                    //Set the image as the texture
                    material.color.texture = SimpleMaterial.Texture.init(texture)
                    material.color.tint = UIColor.white.withAlphaComponent(1)
                    let refImageMarker = ModelEntity(mesh: mesh, materials: [material])
                    
                    //Generate collision shapes for gestures
                    refImageMarker.generateCollisionShapes(recursive: true)
                    
                    //Install the gestures
                    arView.installGestures([.scale], for: refImageMarker)
                    
                    refImageMarker.position.y = 0.04
                    //refImageMarker.orientation = simd_quatf(angle: Float.pi/4, axis: [0, 1, 0])
                    refImageAnchor.addChild(refImageMarker)
                    
                    
                    
                    guard let imageName = referenceImage.name else {
                        fatalError("No name associated with this image")
                    }
                    //Set the same
                    refImageAnchor.name = imageName
                    
                    arView.scene.addAnchor(refImageAnchor)
                    
                } catch {
                    print(error)
                }
            } else { //It is an object anchor
                // TODO: Add code for recognising an object
                print("Spotted an object")
            }
        }
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        //Get the camera position
        guard let cameraPosition = session.currentFrame?.camera.transform.columns.3 else { fatalError("Could not get camera values") }
        
        //Sort the anchors by distance , closest first
        let anchors = anchors.sorted(by: { length(cameraPosition - $0.transform.columns.3) < length(cameraPosition - $1.transform.columns.3)})
        
        //Initialise the anchor distance variable
        var anchorDistance = 0.0
        
        //Loop through the anchors (Currently tracked images)
        for anchor in anchors {
            
            let anchorPosition = anchor.transform.columns.3
            //Create a line between the camera and the anchor
            let cameraToAnchor = cameraPosition - anchorPosition
            //Get the scalar distance
            anchorDistance = Double(length(cameraToAnchor))
            
            //Print it for debugging
            print("\(anchor.name) \(anchorDistance) m")
            

        }
        
        var currentDictionary : [String: String] = [:]
        if anchors[0].name == "bridge" { //Set our current dictionary
            currentDictionary = self.londonDictionary
        } else if anchors[0].name == "rapallo" {
            currentDictionary = self.fortressDictionary
        } else {
            currentDictionary = self.defaultDistionary
        }
        
        //Check if the user can only see one image
        if anchors.count == 1 {
            
            //Check if the user is within the focus distance
            if anchorDistance < FOCUS_DISTANCE{
                //If we are, play the description
                if playing { //If we are already playing something, check if the anchor is the same anchor, if not, play the new audio tape
                    guard let currentDescriptionAnchor = currentDescriptionAnchor else { //If we have a current description anchor
                    return
                    }
                    if currentDescriptionAnchor.name == anchors[0].name { //If they are the same anchor, dont do anything
                    } else {
                        //Play the new audio tape
                        guard let name = anchors[0].name else {
                            fatalError("This anchor does not have a name")
                        }
                        self.currentDescriptionAnchor = anchors[0]
                        //Play the success sound
                        playSuccessSound()
                        //Play the description
                        playDescription(name: name)
                    }
                    
                } else { //If we are not playing anything
                    self.playing = true
                    self.currentDescriptionAnchor = anchors[0]
                    
                    guard let name = anchors[0].name else {
                        fatalError("This anchor does not have a name")
                    }
                    
                    //Play the success sound
                    playSuccessSound()
                    //Play the description
                    playDescription(name: name)
                }
            } else if anchorDistance < 1.5 { //Less than 1.5m away: Close
                
                if closeLayerPlaying { //If we are currently already playing something, check if its from the same anchor, if not play new sound
                    //Check if our current anchor is the same as the previous one
                    if currentLayerAnchor?.name == anchors[0].name { //Same name, we do nothing
                        
                    } else { //Different name, then we load the layer of sounds again
                        //First we stop all the layer of sounds
                        stopLayeringSound()
                    
                        //Update our current anchor
                        currentLayerAnchor = anchors[0]
                        //We then play audio again
                        
                        playCloseLayer(currentDictionary: currentDictionary)
                        playMediumLayer(currentDictionary: currentDictionary)
                        playFarLayer(currentDictionary: currentDictionary)
                        
                    }
                } else { //We are not currently playing, fetch the audio
                    //Update our current anchor
                    currentLayerAnchor = anchors[0]
                    playCloseLayer(currentDictionary: currentDictionary)
                    if !mediumLayerPlaying {
                        playMediumLayer(currentDictionary: currentDictionary)
                        mediumAudioPlayer?.volume = 0.9
                    }
                    if !farLayerPlaying {
                        playFarLayer(currentDictionary: currentDictionary)
                        farAudioPlayer?.volume = 0.9
                    }
                }
                mediumAudioPlayer?.volume = 0.9
                farAudioPlayer?.volume = 0.9
                self.closeAudioPlayer?.volume = Float(pow((0.75 / anchorDistance), 3))
                
                
                
            } else if anchorDistance < 3.0 { //Less than 3.0 meters away: Medium
                
                if mediumLayerPlaying { //If we are currently already playing something, check if its from the same anchor, if not play new sound
                    //Check if our current anchor is the same as the previous one
                    if currentLayerAnchor?.name == anchors[0].name { //Same name, we do nothing
                        
                    } else { //Different name, then we load the layer of sounds again
                        //First we stop all the layer of sounds
                        stopLayeringSound()
                        
                        //We then play audio again
                        //Update our current anchor
                        currentLayerAnchor = anchors[0]
                        playMediumLayer(currentDictionary: currentDictionary)
                        playFarLayer(currentDictionary: currentDictionary)
                        farAudioPlayer?.volume = 0.9
                    }
                } else { //We are not currently playing, fetch the audio
                    //Update our current anchor
                    currentLayerAnchor = anchors[0]
                    playMediumLayer(currentDictionary: currentDictionary)
                    if !farLayerPlaying {
                        playFarLayer(currentDictionary: currentDictionary)
                        farAudioPlayer?.volume = 0.9
                    }
                }
                self.mediumAudioPlayer?.volume = Float(pow((1.5 / anchorDistance), 3))
                
                
            } else { //Further than that: Far
                
                if farLayerPlaying { //If we are currently already playing something, check if its from the same anchor, if not play new sound
                    //Check if our current anchor is the same as the previous one
                    if currentLayerAnchor?.name == anchors[0].name { //Same name, we do nothing
                        
                    } else { //Different name, then we load the layer of sounds again
                        //First we stop all the layer of sounds
                        stopLayeringSound()
                        
                        //We then play audio again
                        //Update our current anchor
                        currentLayerAnchor = anchors[0]
                        playFarLayer(currentDictionary: currentDictionary)
                    }
                } else { //We are not currently playing, fetch the audio
                    
                    //Update our current anchor
                    currentLayerAnchor = anchors[0]
                    
                    
                    playFarLayer(currentDictionary: currentDictionary)
                }
                self.farAudioPlayer?.volume = Float(pow((3.0 / anchorDistance), 3))
            }
        }
        
//
//
//        //If there is only one image on the screen
//        if countTracked(anchors: anchors) == 1 && anchorDistance < FOCUS_DISTANCE{
//            if !oneImageOnScreen{ //If first time finding this image
//                //Play sound and feedback
//                AudioServicesPlaySystemSound(self.systemSoundID)
//                let delay = 0.5
//                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//
//                    let generator = UINotificationFeedbackGenerator()
//                    generator.notificationOccurred(.success)
//                }
//
//            }
//            //Should handle the swipe gesture
//            oneImageOnScreen = true
//
//
//        } else if countTracked(anchors: anchors) == 0 { //If there are no images, pause all layering sounds
//
//            guard let closeAudioPlayer = closeAudioPlayer, let mediumAudioPlayer = mediumAudioPlayer, let farAudioPlayer = farAudioPlayer else {
//                return
//            }
//
//            if closeAudioPlayer.isPlaying || mediumAudioPlayer.isPlaying || farAudioPlayer.isPlaying {
//                stopLayeringSound()
//                //Wait some time
//
//                let delay = 1.5
//                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//                    self.closeLayerPlaying = false
//                    self.mediumLayerPlaying = false
//                    self.farLayerPlaying = false
//                }
//            }
//
//        } else {
//
//            //More than one image on screen, shouldnt handle the swipe gesture
//            oneImageOnScreen = false
//
//
//        }
        
        
        //Get the cloesst image we calculated before
        let closestImage = anchors[0]
        //Get the distance
        let distance = length(cameraPosition - closestImage.transform.columns.3)
        
        let name = closestImage.name
        
        
        //Depending on the distance, we give intervaled feedback
        if Date().timeIntervalSince(lastImapctTime) > ((Double(distance)/impactRatio)) && distance > Float(FOCUS_DISTANCE) {
            if distance < 2.0 { //Less than a meter away
                radarHaptic(impactIntensity: .medium, distance: distance)
            } else if distance < 3.0 { //Less than 2.5 meters away
                radarHaptic(impactIntensity: .medium, distance: distance)
            } else { //Further than that
                radarHaptic(impactIntensity: .light, distance: distance)
            }
            lastImapctTime = Date()
        }
        
        
    }
    
    
    
    // MARK: Helper methods
    
    func getImageName(anchorName: String) -> String{
        var imageName = ""
        switch anchorName{
        case "bridge":
            imageName = "london1.jpg"
        case "rapallo":
            imageName = "rapallo1.jpg"
        case "woman":
            imageName = "woman1.jpg"
        case "cow":
            imageName = "cow1.jpg"
        default:
            imageName = "test1.jpg"
        }
        
        return imageName
    }
    
    func updateImageFilter(direction: UISwipeGestureRecognizer.Direction){
        //Change the texture (Image) of all the anchors
        
        //Update our filter index
        if direction == .left {
            //If we are at the last filter, go back to the first one
            if filterIndex == numberOfFilters - 1 {
                filterIndex = 0
            } else { //We go to the next one
                filterIndex += 1
            }
        } else {
            if filterIndex == 0 { //If we are at the first index, move to the last one
                filterIndex = numberOfFilters - 1
            } else  { //Else we just subtract one
                filterIndex -= 1
            }
        }
        
        
        for anchor in arView.scene.anchors{
            
            //Cast it to a model entity
            let entity = anchor.children.first as? ModelEntity
            //Get the image
            var imageName = getImageName(anchorName: anchor.name)
            
            guard let url = getFilteredImageURL(imageName: imageName) else {
                print("Could not get image name")
                return
            }
            
            var material = UnlitMaterial()
            do {
                //Load the image
                let texture = try TextureResource.load(contentsOf: url)
                //Set the image as the texture
                material.color.texture = SimpleMaterial.Texture.init(texture)
                material.color.tint = UIColor.white.withAlphaComponent(1)
            } catch {
                print(error)
            }
            
            entity?.model?.materials = [material]
        }
        
    }
    
    //This method processes an image given its name and filter index, returns a local URL of the image
    func getFilteredImageURL(imageName: String) -> URL?{
        
        //Gets the default file manager
        let fileManager = FileManager.default
        //Gets the directory
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        
        //Load image into CIImage
        let image = UIImage(named: imageName)!
        let originalCIImage = CIImage(image: image)!
        
        
        //Check if the file exists
        let url = cacheDirectory.appendingPathComponent("\(imageName).jpg")
        if fileManager.fileExists(atPath: url.path) { //If it does, remove it
            do {
                try fileManager.removeItem(atPath: url.path)
            } catch {
                print(error)
            }
        }
        //Create a new image file with the new filter
        //Check which filter index we are at, then call the respective method
        var processedImage = CIImage()
        switch filterIndex {
        case 0:
            print("Default")
            processedImage = originalCIImage
        case 1:
            print("Filter 2")
            processedImage = applyFilter2(input: originalCIImage)
        case 2:
            print("Filter 3")
            processedImage = applyFilter3(input: originalCIImage)
        case 3:
            print("Filter 4")
            processedImage = applyFilter4(input: originalCIImage)
        case 4:
            print("Filter 5")
            processedImage = applyFilter5(input: originalCIImage)
        default:
            print("Got to another filter index...")
        }
        
        
        let resultImage = UIImage(ciImage: processedImage)
        
        guard let data = resultImage.pngData() else {
            return nil
            
        }
        
        fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
        return url
    }
    
    
    //Filters:
    func applyFilter2(input: CIImage) -> CIImage{
        var image = applyHighlight(input: input, highLightAmount: -75)
        image = applySaturation(input: image, saturation: 5)
        return image
    }
    
    
    func applyFilter3(input: CIImage) -> CIImage{
        var  image = applyBrightness(input: input, brightness: 0.5)
        image = applyInvertColor(input: image)
        
        return image
    }
    
    
    func applyFilter4(input: CIImage) -> CIImage{
        var image = applyEdges(input: input, inputIntensity: 5)
        return image
    }
    
    
    func applyFilter5(input: CIImage) -> CIImage{
        var image = applyLineOverlay(input: input)
        return image
    }
    
    
    //Highlight
    func applyHighlight(input: CIImage, highLightAmount: NSNumber) -> CIImage{
        
        //Get the filter
        let parameters = [
            kCIInputImageKey: input,
            "inputHighlightAmount": highLightAmount
        ] as [String : Any]
        
        let filter = CIFilter(name: "CIHighlightShadowAdjust", parameters: parameters)!
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
    }
    
    //Invert Color
    
    func applyInvertColor(input: CIImage) -> CIImage{
        //Get the filter
        
        let filter = CIFilter(name: "CIColorInvert")!
        filter.setValue(input, forKey: kCIInputImageKey)
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
    }
    
    //Apply LineOverlap
    func applyLineOverlay(input: CIImage) -> CIImage {
        
        //Get the filter
        let parameters = [
            kCIInputImageKey: input
        ] as [String : Any]
        
        //Get the filter
        let filter = CIFilter(name: "CILineOverlay", parameters: parameters)!
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
        
    }
    
    //Contrast
    func applyContrast(input: CIImage, contrast: NSNumber) -> CIImage{
        
        //Get the filter
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
    }
    
    //Brightness
    func applyBrightness(input: CIImage, brightness: NSNumber) -> CIImage{
        
        //Get the filter
        let filter = CIFilter(name: "CIColorControls")!
        
        //Set the input image
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        
        //Get our processed image
        guard let image = filter.outputImage else {
            fatalError("Could not process image")
        }
        
        return image
        
    }
    
    //Vibrance
    func applyVibrance(){
        
    }
    
    //Saturation
    func applySaturation(input: CIImage, saturation: NSNumber) -> CIImage{
        
        //Get the filter
        let filter = CIFilter(name: "CIColorControls")!
        
        //Set the input image
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        
        //Get our processed image
        guard let image = filter.outputImage else {
            fatalError("Could not process image")
        }
        
        return image
        
    }
    
    //Noise Reduction
    func applyNoiseReduction(input: CIImage, noiseLevel: NSNumber) -> CIImage{
        //Get the filter
        let parameters = [
            kCIInputImageKey: input,
            "inputNoiseLevel": noiseLevel
        ] as [String : Any]
        
        let filter = CIFilter(name: "CINoiseReduction", parameters: parameters)!
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
    }
    
    //Edges
    func applyEdges(input: CIImage, inputIntensity: NSNumber) -> CIImage{
        //Get the filter
        let parameters = [
            kCIInputImageKey: input,
            "inputIntensity": inputIntensity
        ] as [String : Any]
        
        let filter = CIFilter(name: "CIEdges", parameters: parameters)!
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
    }
    
    
    //Apply Sharpness
    //Noise Reduction
    func applySharpness(input: CIImage, sharpness: NSNumber) -> CIImage{
        //Get the filter
        let parameters = [
            kCIInputImageKey: input,
            "inputSharpness": sharpness
        ] as [String : Any]
        
        let filter = CIFilter(name: "CINoiseReduction", parameters: parameters)!
        
        guard let image = filter.outputImage else {
            fatalError("Could not get output image")
        }
        return image
        
    }
    
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playing = false
    }
    
    func radarHaptic(impactIntensity: UIImpactFeedbackGenerator.FeedbackStyle, distance: Float){
        let generator = UIImpactFeedbackGenerator(style: impactIntensity)
        //Initial impact
        generator.impactOccurred()
        //Wait some time before the next impact
        let delay = (Double(distance)/impactRatio)/4
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            generator.impactOccurred()
        }
    }
    
    
    
    //Plays the close layer sound
    func playCloseLayer(currentDictionary: [String: String]){
        //Get our current URL
        guard let url = currentDictionary["close"], let audioURL = URL(string: url) else {
            fatalError("Invalid URL")
            
        }
        closeLayerPlaying = true
        Task {
            do {
                
                //Request URL
                let (data, response) = try await URLSession.shared.data(from: audioURL)
                
                //Check we got data back
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    fatalError("Invalid server response")
                }
                
                self.closeAudioPlayer = try AVAudioPlayer(data: data)
                self.closeAudioPlayer?.numberOfLoops = -1
                self.closeAudioPlayer?.play()
                
                
            } catch {
                fatalError(error.localizedDescription)
            }
            
        }
    }
    
    //Plays the medium layer sound
    func playMediumLayer(currentDictionary: [String: String]){
        guard let url = currentDictionary["medium"], let audioURL = URL(string: url) else {
            fatalError("Invalid URL")
        }
        mediumLayerPlaying = true
        Task {
            do {
                
                //Request URL
                let (data, response) = try await URLSession.shared.data(from: audioURL)
                
                //Check we got data back
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    fatalError("Invalid server response")
                }
                
                self.mediumAudioPlayer = try AVAudioPlayer(data: data)
                self.mediumAudioPlayer?.numberOfLoops = -1
                self.mediumAudioPlayer?.play()
                
                
            } catch {
                fatalError(error.localizedDescription)
            }
            
        }
    }
    
    
    //Plays the far layer sound
    func playFarLayer(currentDictionary: [String: String]){
        
        guard let url = currentDictionary["far"], let audioURL = URL(string: url) else {
            fatalError("Invalid URL")
            
        }
        
        farLayerPlaying = true
        Task {
            do {
                
                //Request URL
                let (data, response) = try await URLSession.shared.data(from: audioURL)
                
                //Check we got data back
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    fatalError("Invalid server response")
                }
                
                self.farAudioPlayer = try AVAudioPlayer(data: data)
                self.farAudioPlayer?.numberOfLoops = -1
                self.farAudioPlayer?.play()

            } catch {
                fatalError(error.localizedDescription)
            }
            
        }

    }
    
    

    //Plays the description file
    func playDescription(name: String){
        Task {
            do {
                //Set current anchor we are playing
                self.descriptionAudioPlayer?.stop()
                guard let url = self.audioDictionary[name], let audioURL = URL(string: url) else {
                    fatalError("Invalid URL")
                    
                }
                let (data, response) = try await URLSession.shared.data(from: audioURL)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    fatalError("Invalid server response")
                    
                }
                
                self.descriptionAudioPlayer = try AVAudioPlayer(data: data)
                let delay = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.descriptionAudioPlayer?.play()
                }
                self.descriptionAudioPlayer?.delegate = self
                
            }
            catch { print(error.localizedDescription)
            }
            
        }
    }
    
    func playSuccessSound(){
        //Play sound and feedback
        AudioServicesPlaySystemSound(self.systemSoundID)
        let delay = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func stopLayeringSound(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            self.closeAudioPlayer?.setVolume(0.0, fadeDuration: 1.5)
            self.mediumAudioPlayer?.setVolume(0.0, fadeDuration: 1.5)
            self.farAudioPlayer?.setVolume(0, fadeDuration: 1.5)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: Action Methods
    //Got a swipe
    @IBAction func onSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .up:
            print("Swiped up")
            //Check if theres only one image on screen
            if oneImageOnScreen{
                //If there is only one, perform the segue
                
                //Give haptic feedback
                hardImpact.impactOccurred()
                performSegue(withIdentifier: "ARToDetailsSegue", sender: nil)
                
                
            }
            
        case .down:
            print("Swiped down")
//            if let firstSwipeDownTime = firstSwipeDownTime { //If there was already a swipe down
//                if Date().timeIntervalSince(firstSwipeDownTime) < 5.0 { //If the last swipe was within 5 seconds
//
//                    if UIAccessibility.isVoiceOverRunning {
//                        UIAccessibility.post(notification: .screenChanged, argument: "Connecting you to someone")
//                    }
//
//
//                    let screen = self.storyboard?.instantiateViewController(withIdentifier: "video") as? VideoCallViewController
//                    screen?.parentVC = self
//
//                    screen?.modalPresentationStyle = .fullScreen
//                    let transition = CATransition()
//                    transition.duration = 0.3
//                    transition.type = CATransitionType.push
//                    transition.subtype = CATransitionSubtype.fromBottom
//                    view.window!.layer.add(transition, forKey: kCATransition)
//                    self.present(screen!, animated: false, completion: nil)
//
//                } else { //Update the last swipe time and announce something to the user
//                    self.firstSwipeDownTime = Date()
//                    if UIAccessibility.isVoiceOverRunning {
//                        UIAccessibility.post(notification: .announcement, argument: "Swipe down again to speak to someone")
//                    }
//
//
//                }
//
//            } else {
//                self.firstSwipeDownTime = Date()
//                if UIAccessibility.isVoiceOverRunning {
//                    UIAccessibility.post(notification: .announcement, argument: "Swipe down again to speak to someone")
//                }
//            }
            
        case .left:
            print("Swipe left handled")
            updateImageFilter(direction: .left)
        case .right:
            print("Swipe right handled")
            updateImageFilter(direction: .right)
            
        default:
            print("got another direction")
        }
    }
    
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        
        
        let tapLocation: CGPoint = sender.location(in: arView)
        let result: [CollisionCastHit] = arView.hitTest(tapLocation)
        
        
        //print("\(tapLocation.x),\(tapLocation.y)")
        
        guard let hitTest: CollisionCastHit = result.first
        else { return }
        
        let entity: Entity = hitTest.entity
        print(entity.name)
    }
    
    
    
    
    
}
