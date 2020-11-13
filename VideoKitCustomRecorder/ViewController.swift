//
//  ViewController.swift
//  VideoKitCustomRecorder
//
//  Created by Dennis Stücken on 11/11/20.
//
import UIKit
import VideoKitRecorder
import AVFoundation

class ViewController: UIViewController {
    internal var videoURL: URL?
    internal var vkRecorder: VKRecorder = VKRecorder.shared
    
    internal var recordButton: VKRecordButton = {
        let button = VKRecordButton(frame: CGRect(origin: .zero, size: CGSize(width: 90, height: 90)))
        return button
    }()
    
    internal var previewView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        return view
    }()
    
    var recordingProgressView: VKRecordingProgressView = {
        let view = VKRecordingProgressView(progressViewStyle: .default)
        
        // Set recoding time to 60 seconds max
        view.maxTime = 60
        
        return view
    }()
    
    internal var isRecording: Bool = false {
        didSet {
            if isRecording {
                recordButton.startRecordingAnimation()
                recordButton.showStopIndicator()
            } else {
                recordButton.stopRecordingAnimation()
                recordButton.hideStopIndicator()
            }
        }
    }
    
    func startCamera() {
        if vkRecorder.canCaptureVideo {
            if VKRecorder.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                VKRecorder.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                
                do {
                    // Only start session if session is not already started
                    if vkRecorder.session == nil {
                        try vkRecorder.start()
                    }
                } catch let error {
                    print("Failed to start camera \(error)")
                }
                
            } else {
                // Ask for video permissions
                VKRecorder.requestAuthorization(forMediaType: .video) { (mediaType, status) in
                    if VKRecorder.authorizationStatus(forMediaType: AVMediaType.video) == .authorized && VKRecorder.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                        self.startCamera()
                    }
                }
                
                // Ask for audio permissions
                VKRecorder.requestAuthorization(forMediaType: AVMediaType.audio) { (mediaType, status) in
                    if VKRecorder.authorizationStatus(forMediaType: AVMediaType.video) == .authorized && VKRecorder.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                        self.startCamera()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(previewView)
        vkRecorder.delegate = self
        vkRecorder.videoDelegate = self
        vkRecorder.videoConfiguration.autoMergeClipsAfterRecording = true
        
        view.addSubview(recordButton)
        let safeAreaBottom: CGFloat = view.safeAreaInsets.bottom
        recordButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.size.height - safeAreaBottom - (recordButton.frame.size.height * 0.5) - 50.0)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        
        view.addSubview(recordingProgressView)
        recordingProgressView.center = CGPoint(x: view.bounds.midX, y: view.bounds.size.height - safeAreaBottom - (recordButton.frame.size.height * 0.5) - 125)
        
        previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vkRecorder.previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(vkRecorder.previewLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vkRecorder.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        vkRecorder.previewLayer.frame = previewView.bounds
    }
    
    fileprivate func startRecording() {
        if !isRecording {
            isRecording = true
            
            // Reset zoom factor
            vkRecorder.videoZoomFactor = 0
            
            // Start recording
            vkRecorder.record()
        }
    }
    
    @objc func toggleRecording() {
        if isRecording {
            vkRecorder.pause()
            isRecording = false
        } else {
            startRecording()
        }
    }
    
    deinit {
        vkRecorder.stop()
        vkRecorder.session?.removeAllClips()
    }
}

extension ViewController: VKRecorderVideoDelegate {
    
    func vkRecorder(_ vkRecorder: VKRecorder, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: VKRecorderSession) {
        let progress = Float(session.totalDuration.seconds / recordingProgressView.maxTime)

        recordingProgressView.setProgress(min(max(progress, 0), 1), animated: true)
    }
    
}

extension ViewController: VKRecorderDelegate {
    func vkRecorderDidFinishAutoMerge(_ url: URL, _ session: VKRecorderSession) {
        print("\(session.clips.count) video clip(s) have/has been merged to \(url.absoluteString)")
    }
}
