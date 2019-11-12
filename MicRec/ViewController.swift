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
    // lame codec
    var lame: lame_t?
    // buffer for converting from pcm to mp3
    var mp3buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
    
    // this is for testing purposes
    var file = NSMutableData()
    
    deinit {
        mp3buf.deallocate()
        
        // @TODO: possibly need to release resources taken by lame
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize engine
        engine = AVAudioEngine()
        guard nil != engine?.inputNode else {
            // @TODO: error out
            return
        }
        
        // setup lame codec
        prepareLame()
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

    func prepareLame() {
        
        guard let engine = engine else {
            // @TODO: error out
            return
        }
        let input = engine.inputNode
        let sampleRate = Int32(input.inputFormat(forBus: 0).sampleRate)
        
        lame = lame_init()
        lame_set_in_samplerate(lame, sampleRate / 2)
        lame_set_VBR(lame, vbr_default/*vbr_off*/)
        lame_set_out_samplerate(lame, 0) // which means LAME picks best value
        lame_set_quality(lame, 4); // normal quality, quite fast encoding
        lame_init_params(lame)
    }
    
    func installTap() {
    
        engine = AVAudioEngine()
        guard let engine = engine else {
            // @TODO: error out
            return
        }
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize:4096, format:format, block: { [weak self] buffer, when in
            
            guard let this = self else {
                return
            }
            
            if let channel1Buffer = buffer.floatChannelData?[0] {
                /// encode PCM to mp3
                let frameLength = Int32(buffer.frameLength) / 2
                let bytesWritten = lame_encode_buffer_interleaved_ieee_float(this.lame, channel1Buffer, frameLength, this.mp3buf, 4096)
                // `bytesWritten` bytes stored in this.mp3buf now mp3-encoded
                print("\(bytesWritten) encoded")
                
                this.file.append(this.mp3buf, length: Int(bytesWritten))
                
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
        
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
        
        do {
            var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url.appendPathComponent("mic.mp3")
            
            file.write(to: url, atomically: true)
            
            print("path: \(url)")
        } catch {
            
        }
    }
}

