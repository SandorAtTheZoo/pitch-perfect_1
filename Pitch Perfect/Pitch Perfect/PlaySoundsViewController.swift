//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Christopher Johnson on 3/15/15.
//  Copyright (c) 2015 Christopher Johnson. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation


//most of this was implemented based on class direction and Apple docs
//however, I think some items were useful from http://www.rockhoppertech.com/blog/swift-avfoundation/
//although I don't think I used anything verbatim (I just see it left in my browser tab, and it looks relelvant)
//and I found the headphones off of a free download from 
//http://www.sketchappsources.com/free-source/34-ios-bluetooth-headphones-icon.html
//and I made a couple mods to it in Sketch
//constraints were fixed referencing this thread :
//http://stackoverflow.com/questions/13075415/evenly-space-multiple-views-within-a-container-view/25898949#25898949
//
class PlaySoundsViewController: UIViewController {

    @IBOutlet var barSpeed: UISlider!
    @IBOutlet var barPitch: UISlider!
    @IBOutlet var barReverb: UISlider!
    @IBOutlet var barDistortion: UISlider!
    @IBOutlet var enableDistortion: UISwitch!
    
    var audioPlayer:AVAudioPlayer!
    var audioPlayerNode:AVAudioPlayerNode!
    var receivedAudio:RecordedAudio!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    
    var audioPitch:AVAudioUnitTimePitch!
    var audioReverb:AVAudioUnitReverb!
    var audioSpeed:AVAudioUnitVarispeed!
    var audioDistortion:AVAudioUnitDistortion!
    
    var audioSession:AVAudioSession!
    var error:NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathURL, error: nil)
        audioPlayer.enableRate = true
        
        audioEngine = AVAudioEngine()
        audioFile = AVAudioFile(forReading: receivedAudio.filePathURL, error: nil)
        
        configAudioSession()
        audioSession.setActive(true, error: &error)
        
        //configure audio player node and engine.  this seems to stop the crashes under playAudio when it checks for
        //audioPlayerNode.playing if fast/slow buttons pushed first...this fixes implicit type resolving to nil
        //but I can't seem to use this in lieu of the instantiations under playAudioWithVariablePitch...then it
        //_REALLY_ crashes...I didn't think this was namespace related, since var was declared global to this class
        initAudioNode(0, reverb: 0.0, speed: 1.0, distortion: 0)
    }
    
    override func viewWillDisappear(animated: Bool) {
        stopAllPlayback()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //plays audio from the fast/slow buttons from the beginning
    //stops playback from the audioNode player first
    func playAudio(){
        stopAllPlayback()
        audioPlayer.currentTime = 0
        audioPlayer.play()
    }

    @IBAction func playSlowButton(sender: UIButton) {
        audioPlayer.rate = 0.5
        self.playAudio()
    }

    @IBAction func playFastButton(sender: UIButton) {
        audioPlayer.rate = 2.0
        self.playAudio()
    }
    
    //stops all audio
    @IBAction func stopPlayback(sender: UIButton) {
        stopAllPlayback()
    }
    
    @IBAction func playChipmunkAudio(sender: UIButton) {
        playAudioWithVariablePitch(1000)
    }
    
    @IBAction func playDarthVaderAudio(sender: UIButton) {
        playAudioWithVariablePitch(-1000)
    }
    
    //everything takes float except distortion, which is a set of 22 enums
    //so I cast Float -> Int and referenced :
    //http://stackoverflow.com/questions/24029917/convert-float-to-int-in-swift
    @IBAction func playComboAudio(sender: UIButton) {
        playAudioWithVariableEverything(barPitch.value, reverb: barReverb.value, speed: barSpeed.value, distortion: Int(floor(barDistortion.value)))
    }
    
    
    func playAudioWithVariablePitch(pitch : Float) {
        initAudioNode(pitch, reverb: 0.0, speed: 1.0, distortion: 0)
        audioPlayerNode.play()
    }
    
    //uses the sliders to create a bunch of different sounds
    func playAudioWithVariableEverything(pitch: Float, reverb:Float, speed:Float, distortion:Int) {
        initAudioNode(pitch, reverb: reverb, speed: speed, distortion: distortion)
        audioPlayerNode.play()
    }
    //defaults to iPhone speaker rather than receiver
    func configAudioSession() {
        audioSession = AVAudioSession()
        if !(audioSession.setActive(true, error: &error)) {
            if (audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker, error: nil)) {
                println("success")
            } else {
                println("session failure")
            }
        } else {
            //learned this from thiago on the udacity forums
            audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker, error: &error)
        }
    }
    ///initializes audioNode, attaches engine, and pitch, speed and distortion effects
    ///connects player to pitch and engine
    ///points player to file for playback, starts audioEngine
    func initAudioNode(pitch : Float, reverb : Float, speed: Float, distortion: Int) {
        
        audioPlayerNode = AVAudioPlayerNode()
        
        stopAllPlayback()
        
        audioEngine.attachNode(audioPlayerNode)
        
        audioPitch = AVAudioUnitTimePitch()
        audioPitch.pitch = pitch
        audioPitch.rate = speed
        audioEngine.attachNode(audioPitch)
        
        audioReverb = AVAudioUnitReverb()
        audioReverb.wetDryMix = reverb
        audioEngine.attachNode(audioReverb)
        
        audioDistortion = AVAudioUnitDistortion()
        audioDistortion.loadFactoryPreset(AVAudioUnitDistortionPreset(rawValue: distortion)!)
        audioEngine.attachNode(audioDistortion)
        
        audioEngine.connect(audioPlayerNode, to: audioPitch, format: audioFile.processingFormat)
        audioEngine.connect(audioPitch, to: audioReverb, format: audioFile.processingFormat)
        
        if (enableDistortion.on) {
            audioEngine.connect(audioReverb, to: audioDistortion, format: audioFile.processingFormat)
            audioEngine.connect(audioDistortion, to: audioEngine.outputNode, format: audioFile.processingFormat)
        } else {
            audioEngine.connect(audioReverb, to: audioEngine.outputNode, format: audioFile.processingFormat)
        }
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: nil)
        
        audioEngine.startAndReturnError(nil)
    }
    
    func stopAllPlayback() {
        if (audioPlayer.playing) {
            audioPlayer.stop()
        }
        if (audioPlayerNode.playing) {
            audioPlayerNode.stop()
        }
        audioEngine.stop()
        audioEngine.reset()
        audioSession.setActive(false, error: &error)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
