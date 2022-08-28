//
//  DetailViewController.swift
//  Image Recogniser
//
//  Created by William Chen on 2022/7/7.
//

import UIKit
import CoreImage
import SceneKit

class DetailViewController: UIViewController {
    

    
    //List containing all the filters
    
    let filterList: [String] = ["CIColorClamp", "CIColorControls"]
    
    //Variable to keep track of which filter we are at rightnow
    var filterIndex: Int = 0

    //Keeps track of the number of filters we have
    var numberOfFilters: Int = 5
    
    @IBOutlet weak var imageView: UIImageView!
    

    
    
    var imageSelected: String?
    
    //Stores the scale ratio
    var scaleRatio: Double = 0
    
    //The painting's information
    var painting: Painting?
    var width = 0
    var height = 0
    
    
    //Holds the original brightness of the screen
    var brightness: CGFloat?
    
    var parentVC: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        brightness = UIScreen.main.brightness
        
        //Set our screen to brightest
        UIScreen.main.brightness = CGFloat(1.0)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGesture.numberOfTapsRequired = 1
        //Enable user interactions
        imageView.isUserInteractionEnabled = true
        //Add the gesture recogniser
        imageView.addGestureRecognizer(tapGesture)
        
        imageView.contentMode = .scaleAspectFit
        
        //Accessibility
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        
        guard let imageSelected = imageSelected else {
            fatalError("Did not set selected image, did the user select an image?")
        }
        
        //Swipe down gesture for going back
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeDown.direction = .down
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeLeft.direction = .left
        
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeRight.direction = .right
        
        
        
        //Add the gestures
        self.view.addGestureRecognizer(swipeDown)
        self.imageView.addGestureRecognizer(swipeDown)
        
        self.view.addGestureRecognizer(swipeLeft)
        self.imageView.addGestureRecognizer(swipeLeft)
        
        self.view.addGestureRecognizer(swipeRight)
        self.imageView.addGestureRecognizer(swipeRight)
        
        
    }
    
    
    @IBAction func onSwipe(_ sender: UISwipeGestureRecognizer) {
        //Pop the VC
        
        switch sender.direction {
        case .down:
            self.dismiss(animated: true)
        case . right:
            updateImageFilter(direction: .right)
        case .left:
            updateImageFilter(direction: .left)
        default:
            print("Another direction")
        }
    }
    
    
    
    //MARK: IMAGE FILTERS
    func updateImageFilter(direction: UISwipeGestureRecognizer.Direction){
        
        do {
            //Get the image
            var imageName = ""
            switch imageSelected{
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
        
            guard let url = createLocalUrl(forImageNamed: imageName) else {
                fatalError("Could not find the image file")
            }
            
            //Load image into CI Image
            let image = UIImage(named: imageName)!
            let originalCIImage = CIImage(image: image)!
            
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
            
            
            let returnImage = UIImage(ciImage: processedImage)
            
            //Get the width and height of the image and screen
            let screenWidth = self.view.safeAreaLayoutGuide.layoutFrame.width
            let screenHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
            
            let result = returnImage.scalePreservingAspectRatio(targetSize: CGSize(width: screenWidth, height: screenHeight))
            
            //Update our image view
            self.imageView.image = result.0
            
        } catch {
            print(error)
        }
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
    
    
    
    
    
    
    //Helper functions
    //Brilliance
    func applyBrilliance(){
        
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
    
    
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let brightness = brightness {
            parentVC?.changeBrightness(brightness: brightness)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    func setUp(){
        
        //Create the context
        let context = CIContext()
        //Get the image
        var imageName = ""
        switch imageSelected{
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
        if let image = UIImage(named: imageName) { //Found the image
            
            //Get the width and height of the image and screen
            let screenWidth = self.view.safeAreaLayoutGuide.layoutFrame.width
            let screenHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            
            print("Image width: \(imageWidth), Screen width: \(screenWidth), Image height: \(imageHeight), Screen Height: \(screenHeight)")
            
            //Get the ratio
            let imageWidthToScreenWidthRatio =  imageWidth/screenWidth
            let imageHeightToScreenHeightRatio = imageHeight/screenHeight
            
            print("Width Ratio: \(imageWidthToScreenWidthRatio), Height Ratio: \(imageHeightToScreenHeightRatio)")
            
            //Scale the image down
            
            //Determine either width or height
            if abs(1 - imageWidthToScreenWidthRatio) > abs(1 - imageHeightToScreenHeightRatio){ //The image is really wide, so scale it down according to the width
                print("wide")
                
            } else { //The image is proportionally really tall
                print("height")
            }
            
            let result = image.scalePreservingAspectRatio(targetSize: CGSize(width: screenWidth, height: screenHeight))
            
            let scaledImage = result.0
            
            //Update our sacled ratio
            scaleRatio = result.1
            print("Scale Factor: \(result.1)")
            
            imageView.image = scaledImage //Set the image
            
        } else {
            fatalError("Could not find image")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setUp()
        print("called viewdidappear")
        //JSON Data
        Task{
            do {
                
                //Get the JSON file remotely
                
                var urlString = ""
                switch imageSelected{
                case "bridge":
                    urlString = "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/JSON%2Flondon.json?alt=media&token=ff2ceffc-2fec-469b-896b-098179caac07"
                case "rapallo":
                    urlString = "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/JSON%2Frapallo.json?alt=media&token=7ffbbe18-eec4-47dc-8fff-5e0500a5e361"
                case "woman":
                    urlString = "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/JSON%2Fwoman.json?alt=media&token=e0ea2f6f-0a7c-401f-88e7-1923ca95e8ca"
                case "cow":
                    urlString = "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/JSON%2Fcow.json?alt=media&token=0dbe19ec-24d1-4777-ade1-9b3786714a5d"
                default:
                    urlString = "https://firebasestorage.googleapis.com/v0/b/bendigo-art-gallery.appspot.com/o/JSON%2Fhexagon.json?alt=media&token=aedb0068-cf70-4e34-bd38-275e195b9e58"
                }
                
                
                guard let URL = URL(string: urlString) else {
                    fatalError("Couldnt parse URL")
                }

                //Get the data
                let (data, response) = try await URLSession.shared.data(from: URL)

                let decoder = JSONDecoder()
                
                //Decode the JSON data
                let decoded = try decoder.decode([JSONObject].self, from: data)

                
                //Change the JSON data into our custom objects
                
                //This gets the most recent annotation (Most up to date)
            
                //Currently only getting the first object, we are assuming one JSON file will only contain region information for one painting
                guard let annotation = decoded[0].annotations.last else {
                    fatalError("Did not find any annotations")
                }
                
                
                //Create an empty list of regions
                var regions : [Region] = []
                //Loop through the regions
                for result in annotation.result {
                    //Get the painting's original width and height
                    self.width = result.original_width
                    self.height = result.original_height
                    
                    //Get the value object which includes the points and the label
                    let value = result.value
                    
                    //Create and empty list of points
                    var points: [Point] = []
                    for point in value.points{ //Loop through the points also convert them to the right ratio
                        points.append(Point(x: Float(point[0] / 100.0 * Float(self.width)), y: Float(point[1] / 100.0 * Float(self.height)))) //Add the points to the points list
                    }
                    
                    
                    //Loop through the points and create line segments
                    var lineSegments: [LineSegment] = []
                    
                    for i in 0 ... points.count - 2 {
                        //Create a line between two adjacent points
                        lineSegments.append(LineSegment(startingPoint: points[i], endingPoint: points[i + 1]))
                    }
                    
                    //Create a line between the last point and first point
                    guard let first = points.first, let last = points.last else {
                        fatalError("Not enough points")
                    }
                    lineSegments.append(LineSegment(startingPoint: last, endingPoint: first))
                    
                    //It is a list but we just get the last element and assume it is the label we need to read
                    guard let label = value.polygonlabels.last else {
                        fatalError("No label found, did the annotator set one?")
                    }
                    
                    //Create the new region
                    let region = Region(lineSegments: lineSegments, label: label)
                    
                    //Append it to our painting
                    regions.append(region)
                }
                
                //Set our current painting
                self.painting = Painting(regions: regions, width: self.width, height: self.height)
                
                
            } catch {
                print(error)
            }
        }
        
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        
        let tapLocation = sender.location(in: imageView)
        
        //Create a point with the tap
        let tappedPoint = Point(x: Float(tapLocation.x) / Float(scaleRatio), y: Float(tapLocation.y) / Float(scaleRatio))
        
        //Loop through all the line segments and if the tap's y value is between the line's start's y and end's y then we count as intersection
        
        
        //Unwrap our painting
        guard let painting = painting else {
            return
        }
        
        //Print the tap
        print("Tapped x: \(tappedPoint.x), y: \(tappedPoint.y)")
        
        //Loop through each region
        for region in painting.regions {
            //Counter to keep track of intersection
            var counter = 0
            //Loop through each line segment
            for lineSegment in region.lineSegments {
                //Calculate the point of intersection, only count as intersection if the point of intersection is to the right of the tapped point
                
                print("Looking at \(lineSegment.startingPoint.x),\(lineSegment.startingPoint.y) to\(lineSegment.endingPoint.x),\(lineSegment.endingPoint.y)")
                if (tappedPoint.y < lineSegment.startingPoint.y && tappedPoint.y > lineSegment.endingPoint.y ) ||
                    (tappedPoint.y > lineSegment.startingPoint.y && tappedPoint.y < lineSegment.endingPoint.y) {
                    
                    //Getting here means our horizontal line will intersect at a point with the line, figure out where
                    let slope = (lineSegment.startingPoint.y - lineSegment.endingPoint.y) / (lineSegment.startingPoint.x - lineSegment.endingPoint.x)
                    let b = lineSegment.startingPoint.y - (slope * lineSegment.startingPoint.x)
                    
                    //The x coordinate of the intersection
                    let intercept = (tappedPoint.y - b) / slope
                    
                    //Only record the intersection if its to our right or if its a vertial line
                    if intercept >= tappedPoint.x || (lineSegment.startingPoint.x == lineSegment.endingPoint.x && lineSegment.startingPoint.x >= tappedPoint.x) {
                        counter += 1
                        print("Intersection: \(intercept), Slope: \(slope), B: \(b), Region: \(region.label)")
                    }
                    
                    
                    
                }
                
                
            }
            
            //Check if the counter is odd
            if counter % 2  == 1 {
                print("Tapped inside \(region.label)")
                
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .announcement, argument: region.label)
                }
                
                
                return
            }
        }

        //This prints it
        print("Tapped outside of all regions")
        
        
        //TODO: OPTIMISE FOR BETTER PERFORMANCE
        //Determine whether our tapped point is inside a region or not
        
        //We ignore lines that start and end to the left of our tap
        
        //Only count intersection if our tap's y value is in between the y values of the start and end point of a line
        
        //If even number of intersections with a region, we are not in
        
        //If odd number of intersections with a region, we are in
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}


//From: https://www.advancedswift.com/resize-uiimage-no-stretching-swift/ with no modification
extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> (UIImage, Double) {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return (scaledImage, scaleFactor)
    }
}



//Exposure
func applyExposure(){
    
}




func createLocalUrl(forImageNamed name: String) -> URL? {

        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name).jpg")

    guard fileManager.fileExists(atPath: url.path) else {
            guard
                let image = UIImage(named: name),
                let data = image.pngData()
            else { return nil }

            fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
            return url
        }

        return url
    }








//JSON Objects


