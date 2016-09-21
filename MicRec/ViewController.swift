//
//  ViewController.swift
//  MicRec
//
//  Created by Valerii Lider on 9/20/16.
//  Copyright © 2016 Valerii Lider. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // engine for getting audio pcm stream
    var engine: AVAudioEngine?

    // we will write to file
    var file: AVAudioFile?
    
    deinit {
        file = nil
        engine?.inputNode?.removeTap(onBus: 0)
        engine = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize engine
        engine = AVAudioEngine()
        guard nil != engine?.inputNode else {
            // @TODO: error out
            return
        }
        
        do {
            var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url.appendPathComponent("1.wav")
            
            file = try AVAudioFile(forWriting: url, settings: [AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false])
        } catch {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startRecording(_: UIControl) {
        installTap()
    }
    
    @IBAction func stopRecording(_: UIControl) {
        removeTap()
    }

    func installTap() {
    
        engine = AVAudioEngine()
        guard let engine = engine, let input = engine.inputNode else {
            // @TODO: error out
            return
        }
        
        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize:4096, format:format, block: { [weak self] buffer, when in
            
            guard let this = self else {
                return
            }
    
            // writing to file: for testing purposes only
            do {
                try this.file!.write(from: buffer)
            } catch {
                
            }
            
            if let channel1Buffer = buffer.floatChannelData?[0] {
                /*! @property floatChannelData
                 @abstract Access the buffer's float audio samples.
                 @discussion
                 floatChannelData returns pointers to the buffer's audio samples if the buffer's format is
                 32-bit float, or nil if it is another format.
                 
                 The returned pointer is to format.channelCount pointers to float. Each of these pointers
                 is to "frameLength" valid samples, which are spaced by "stride" samples.
                 
                 If format.interleaved is false (as with the standard deinterleaved float format), then
                 the pointers will be to separate chunks of memory. "stride" is 1.
                 
                 If format.interleaved is true, then the pointers will refer into the same chunk of interleaved
                 samples, each offset by 1 frame. "stride" is the number of interleaved channels.
                 */
                
                // @TODO: send data, better to pass into separate queue for processing
            }            
        })

        engine.prepare()

        do {
            try engine.start()
        } catch {
            // @TODO: error out
        }
    }

    func removeTap() {
        
        engine?.inputNode?.removeTap(onBus: 0)
        engine = nil
        
        file = nil
    }
}

