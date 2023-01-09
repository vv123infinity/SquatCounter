//
//  ViewController.swift
//  SquatCounter
//
//  Created by Infinity vv123 on 2023/1/8.
//

import UIKit
import VideoToolbox
import AVFoundation


class ViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var countUIView: UIView!
    @IBOutlet weak var videoUIView: UIView!
    @IBOutlet weak var squatCountLabel: UILabel!
    @IBOutlet weak var squatCounterStateLabel: UILabel!
    @IBOutlet private var previewImageView: PoseImageView!
    
    // MARK: Properties
    
    //    > > > > properties of squat < < < <
    // the number of squat
    var squatCount: Int = 0
    
    // Does the squat count start
    var squatStartFlag: Bool = false
    
    // Start time for deep squats
    var startTime: CGFloat = 0.0
         
    // Angle of the previous period
    var prevKneeAngle: CGFloat = 0.0
    
    // Current state of the squat
    var squatPos = 0
    
    // The state of deep squatting some time ago
    var prevSqautPos = 0
    
    private let videoCapture = VideoCapture()
    private var poseNet: PoseNet!
    // The frame the PoseNet model is currently making pose predictions from.
    private var currentFrame: CGImage?
    // The algorithm the controller uses to extract poses from the current frame.
    private var algorithm: Algorithm = .single
    // The set of parameters passed to the pose builder when detecting poses.
    private var poseBuilderConfiguration = PoseBuilderConfiguration()
    private var popOverPresentationManager: PopOverPresentationManager?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.init_ui()
        
        do {
            poseNet = try PoseNet()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }
        poseNet.delegate = self
        
        
        self.setupCapturingVideoFrames()
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        // Reinitilize the camera to update its output stream with the new orientation.
        setupCapturingVideoFrames()
    }
    
    private func setupCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }

            self.videoCapture.delegate = self
        }
    }
    
    
    // MARK: - IBAction
    @IBAction func startBtnPressed(_ sender: UIButton) {
        self.previewImageView.isHidden = false
        self.squatCounterStateLabel.text = "Counting"
        self.videoCapture.startCapturing()
        self.squatStartFlag = true
        self.squatCount = 0
        self.squatCountLabel.text = "0"
    }
    
    @IBAction func stopBtnPressed(_ sender: UIButton) {
        self.previewImageView.isHidden = true
        self.squatCounterStateLabel.text = "Press Start"
        self.videoCapture.stopCapturing()
        self.squatStartFlag = false
    }
    
    @IBAction func onCameraButtonTapped(_ sender: Any) {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Failed to flip camera with error \(error)")
            }
        }
    }
    
    
    

    
    // MARK: - UI
    func init_ui(){
        let threeUIView = [countUIView, videoUIView]
        for i in threeUIView{
            i?.layer.masksToBounds = true
            i?.layer.cornerRadius = 20
        }
        
        self.previewImageView.isHidden = true
    }
    


}


// MARK: - Squat Counter Algo
extension ViewController {
    func squatDetectionCount(_ poses: [Pose]) {
        // get all keypoints
        let leftHipJoint: Joint = {return (poses.first?.joints[Joint.Name.leftHip])!}()
        let rightHipJoint: Joint = {return (poses.first?.joints[Joint.Name.rightHip])!}()
        let leftKneeJoint: Joint = {return (poses.first?.joints[Joint.Name.leftKnee])!}()
        let rightKneeJoint: Joint = {return (poses.first?.joints[Joint.Name.rightKnee])!}()
        let leftAnkleJoint: Joint = {return (poses.first?.joints[Joint.Name.leftAnkle])!}()
        let rightAnkleJoint: Joint = {return (poses.first?.joints[Joint.Name.rightAnkle])!}()
        let leftHipPoint: CGPoint = CGPoint(x: leftHipJoint.position.x, y: leftHipJoint.position.y)
        let rightHipPoint: CGPoint = CGPoint(x: rightHipJoint.position.x, y: rightHipJoint.position.y)
        let leftKneePoint: CGPoint = CGPoint(x: leftKneeJoint.position.x, y: leftKneeJoint.position.y)
        let rightKneePoint: CGPoint = CGPoint(x: rightKneeJoint.position.x, y: rightKneeJoint.position.y)
        let leftAnklePoint: CGPoint = CGPoint(x: leftAnkleJoint.position.x, y: leftAnkleJoint.position.y)
        let rightAnklePoint: CGPoint = CGPoint(x: rightAnkleJoint.position.x, y: rightAnkleJoint.position.y)
        
        // Calculate the Angle of a particular position of the human body
        let squatKneeAngle = get_knee_angle(leftHipPoint, rightHipPoint, leftKneePoint, rightKneePoint, leftAnklePoint, rightAnklePoint)
        if squatKneeAngle[2] < prevKneeAngle {
//            print("Up Up Up !!!")
            prevKneeAngle = squatKneeAngle[2]
        }
        else {
//            print("Down Down Down !!!\n")
            prevKneeAngle = squatKneeAngle[2]
        }
        
        // compute the average angle
        let avgAngle = (squatKneeAngle[0] + squatKneeAngle[1]) / 2
        // Determine the squat status
        // Basically complete the knee Angle of the squat
        
        // 100 is just an arbitrary Angle that can be replaced with 80 or 120. The higher the value, the deeper the user will squat.
        if round(avgAngle) > 100 {
            
            // Get the current time
            let now = Date()
            let timeInterval: TimeInterval = now.timeIntervalSince1970
            let timeStamp = CGFloat(timeInterval)
            
            let passTime = timeStamp - startTime
            
            if passTime > 0.1 && passTime < 3000 {
                squatPos = 1 // Reassign. This is not a squat
            }
            
        }
        else if round(avgAngle) < 10 {
                // Because the Angle of the knee cannot be 0 when the human body is standing directly in the squat, it is set to 10. Again, this value can be replaced with the value you want.
                // get current time
                let now = Date()
                let timeInterval: TimeInterval = now.timeIntervalSince1970
                let timeStamp = CGFloat(timeInterval)
                startTime = timeStamp
                squatPos = 0  // Squatting
            }
        else {
                squatPos = 999
        }

        if prevSqautPos - squatPos == 1 {
            squatCount += 1
            
        }
        if squatPos == 0 || squatPos == 1{
            prevSqautPos = squatPos
        }
        self.squatCountLabel.text = "\(squatCount)"
        
        }

    
    func calcDis(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat{
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
}



// MARK: - VideoCaptureDelegate

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        guard currentFrame == nil else {
            return
        }
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }

        currentFrame = image
        poseNet.predict(image)
    }
}

// MARK: - PoseNetDelegate
extension ViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        defer {
            self.currentFrame = nil
        }
        
        guard let currentFrame = currentFrame else {
            return
        }
        
        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)
        
        let poses = algorithm == .single
        ? [poseBuilder.pose]
        : poseBuilder.poses
        
        previewImageView.show(poses: poses, on: currentFrame)
        // start counting
        if poses.first != nil && self.squatStartFlag == true {
            squatDetectionCount(poses)
        }
        
    }
    
}
