//
//  DetailsViewController.swift
//  Bendigo Project
//
//  Created by William Chen on 2022/8/28.
//

import UIKit

class DetailsViewController: UIViewController, UIScrollViewDelegate {

    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!
    
    var imageSelected: String?
    
    //The painting's regions
    var painting: Painting?
    
    //Holds the original brightness of the screen
    var brightness: CGFloat?
    
    var parentVC: ViewController?
    
    //Variable to keep track of which filter we are at rightnow
    var filterIndex: Int = 0

    //Keeps track of the number of filters we have
    var numberOfFilters: Int = 5
    
    
    //Hpatic feedback engine
    let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    
    
    
    //Records down the time when we last gave haptic feedback
    var topLastImapctTime: Date = Date()
    var bottomLastImapctTime: Date = Date()
    var leftLastImapctTime: Date = Date()
    var rightLastImapctTime: Date = Date()
    
    var lastImpactTime: Date = Date()
    
    
    //Keeps track of the image's size
    var height = 0
    var width = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Record down our brightness
        brightness = UIScreen.main.brightness
        
        //Set our screen to brightest
        UIScreen.main.brightness = CGFloat(1.0)
        
        
        //Set the delegate
        scrollView.delegate = self
        
        
        //Allow user interations in Voiceover
        imageView.isUserInteractionEnabled = true
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = [UIAccessibilityTraits.allowsDirectInteraction]
        
        
        //The tap gesture recogniser
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGesture.numberOfTapsRequired = 1
        
        //Add the gesture recogniser
        imageView.addGestureRecognizer(tapGesture)
        
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
    
    
    override func viewDidAppear(_ animated: Bool) {
        setUp()
        
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
                var width = 0
                var height = 0
                //Loop through the regions
                for result in annotation.result {
                    //Get the value object which includes the points and the label
                    let value = result.value
                    
                    width = result.original_width
                    height = result.original_height

                    //Create and empty list of points
                    var points: [Point] = []
                    for point in value.points{ //Loop through the points also convert them to the right ratio
                        points.append(Point(x: Float(point[0] / 100.0 * Float(result.original_width)), y: Float(point[1] / 100.0 * Float(result.original_height)))) //Add the points to the points list
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
                self.painting = Painting(regions: regions, width: width, height: height)
                
                
            } catch {
                print(error)
            }
        }
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
            
            imageView.image = image //Set the image
            
            //Set the maximum scroll and minimum scroll
            scrollView.maximumZoomScale = 10.0
            
            let heightRatio = image.size.height/self.view.safeAreaLayoutGuide.layoutFrame.height
            let widthRatio = image.size.width/self.view.safeAreaLayoutGuide.layoutFrame.width
            
            scrollView.minimumZoomScale = min(1 / heightRatio, 1/widthRatio)
            
            print("Height ratio \(1 / heightRatio)")
            print("Width ratio \(1/widthRatio)")
        } else {
            fatalError("Could not find image")
        }
    }
    
        
        
        
        
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    
    //Swipe
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
    
    
    
    
    
    //Tap
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        
        let tapLocation = sender.location(in: imageView)
        
        //Create a point with the tap
        let tappedPoint = Point(x: Float(tapLocation.x), y: Float(tapLocation.y))
        
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
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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
            
            
            //Update our image view
            self.imageView.image = returnImage
            
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
    
    
    //Haptic feedback
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //Check if the user reached the edge, if they did give haptic feedback
        
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let scrollOffsetHorizontal = scrollView.contentOffset.x
        
        
        //Left edge
        
        if scrollView.contentOffset.x >= (scrollView.contentSize.width - scrollView.frame.size.width) && Date().timeIntervalSince(lastImpactTime) > 1{
            // then we are at the top
            mediumImpact.impactOccurred()
            lastImpactTime = Date()
        }
        
        
        
        //Top edge
        if  scrollOffsetHorizontal < 0 && Date().timeIntervalSince(lastImpactTime) > 1 {
            // then we are at the top
            mediumImpact.impactOccurred()
            lastImpactTime = Date()
            
            }
        
        
        //Right edge
        
        //Top edge
        if  scrollOffset < 0 && Date().timeIntervalSince(lastImpactTime) > 1 {
            // then we are at the top
            mediumImpact.impactOccurred()
            lastImpactTime = Date()
            
            }
        
        //Bottom edge
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) && Date().timeIntervalSince(lastImpactTime) > 1{
            // then we are at the top
            mediumImpact.impactOccurred()
            lastImpactTime = Date()
        }
        
        
        //Bottom edge
        
        
        
        
    }
    
    

}
