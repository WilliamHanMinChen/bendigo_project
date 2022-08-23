//
//  VideoCallViewController.swift
//  Image Recogniser
//
//  Created by William Chen on 2022/7/11.
//

import UIKit
import AgoraRTE
import AgoraRtcKit

class VideoCallViewController: UIViewController {
    
    
    // Defines localView
    var localView: UIView!
    // Defines remoteView
    var remoteView: UIView!
    // Defines agoraKit
    var agoraKit: AgoraRtcEngineKit!
    
    //Keeps track of the parent VC
    var parentVC: ViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Initializes the video view
        initView()
        // The following functions are used when calling Agora APIs
        initializeAgoraEngine()
        setupLocalVideo()
        joinChannel()
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: "You are now connected")
        }
        
        //Add swipe gesture recognisers
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipeUp.direction = .up
        
        self.view.addGestureRecognizer(swipeUp)
        
        self.view.isAccessibilityElement = true
        self.view.accessibilityTraits = .allowsDirectInteraction
        
    }
    
    
    //Got a swipe
    @IBAction func onSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .up:
            print("Swiped up")
            
            
            //Leaves the channel
            agoraKit.stopPreview()
            agoraKit.leaveChannel(nil)
            AgoraRtcEngineKit.destroy()
            
            
            let transition = CATransition()
            transition.duration = 0.2
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromTop
            view.window!.layer.add(transition, forKey: kCATransition)
            self.dismiss(animated: false)
        default:
            print("Swiped in another direction")
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        //Setup the ARView camera to prevent lag
//        parentVC?.setUp()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        
    }
    
    //MARK: Agora functions
    
    // Sets the video view layout
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        remoteView.frame = self.view.bounds
        localView.frame = CGRect(x: self.view.bounds.width - 110, y: 90, width: 90, height: 160)
        
    }
    
    func initView(){
        // Initializes the remote video view. This view displays video when a remote host joins the channel.
        remoteView = UIView()
        self.view.addSubview(remoteView)
        // Initializes the local video window. This view displays video when the local user is a host.
        localView = UIView()
        self.view.addSubview(localView)
    }
    
    
    func initializeAgoraEngine(){
        let config = AgoraRtcEngineConfig()
        // Pass in your App ID here.
        config.appId = "e46ac44e46bf4c64b15ab93108d9db33"
        // Use AgoraRtcEngineDelegate for the following delegate parameter.
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    
    func setupLocalVideo(){
        // Enables video module
        agoraKit.enableVideo()
        // Starts the local video preview
        agoraKit.startPreview()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        // Sets the local video view
        agoraKit.setupLocalVideo(videoCanvas)
    }
    
    
    func joinChannel(){
        let option = AgoraRtcChannelMediaOptions()
        // For a live streaming scenario, set the channel profile as liveBroadcasting.
        option.channelProfile = .of((Int32)(AgoraChannelProfile.liveBroadcasting.rawValue))
        // Set the client role as broadcaster or audience.
        option.clientRoleType = .of((Int32)(AgoraClientRole.broadcaster.rawValue))

        // Join the channel with a temp token. Pass in your token and channel name here
       agoraKit.joinChannel(byToken: "006e46ac44e46bf4c64b15ab93108d9db33IAARVtdPmgFrTcbesWksHBpEY4uV7QvccMdi+XugWWzkVcqFUwsAAAAAEAAtDEjTA1bbYgEAAQADVtti", channelId: "temp", uid: 0, mediaOptions: option)
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

extension VideoCallViewController: AgoraRtcEngineDelegate{
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int){
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        agoraKit.setupRemoteVideo(videoCanvas)
    }
}


