//
//  ViewController.swift
//  AVFoundationDemo
//
//  Created by Mike Huang on 2021/8/6.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var audioSourceContainer: UIView!
    @IBOutlet weak var videoSourceContainer: UIView!
    
    @IBOutlet weak var compositionButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    var playerConfiguration: (addWaterMark: Bool, title: String?, audioMix: Bool, waveGraph: Bool) = (addWaterMark: false, title: nil, audioMix: false, waveGraph: false)

    var compositionAsset: AVMutableComposition?
    
    let player = EasyAVPlayerView()
    let videoSourcesView = EasyTableView(dataSources: [], title: "Video Sources", frame: CGRect.zero)
    let audioSourcesView = EasyTableView(dataSources: [], title: "Audio Sources", frame: CGRect.zero)

    deinit {

    }
    
    func setupUI() {
        player.frame = videoView.bounds
        videoView.addSubview(player)
        player.didLoadDuration = { [weak self] asset, duration in
            guard let self = self else { return }
            if let model = self.videoSourcesView.dataSources.first(where: { $0.asset == asset }) {
                model.duration = Int64(duration)
            }
            
            if let model = self.audioSourcesView.dataSources.first(where: { $0.asset == asset }) {
                model.duration = Int64(duration)
            }
        }
        
        videoSourcesView.frame = videoSourceContainer.bounds
        videoSourceContainer.addSubview(videoSourcesView)
        videoSourcesView.didSelectedAction = { [weak self] model in
            guard let self = self else { return }
            self.updateButtonsState()
            self.player.isVideo = model.isVideo
            self.player.asset = model.isSelected ? model.asset : nil
        }
        
        audioSourcesView.frame = audioSourceContainer.bounds
        audioSourceContainer.addSubview(audioSourcesView)
        audioSourcesView.didSelectedAction = { [weak self] model in
            guard let self = self else { return }
            self.updateButtonsState()
            self.player.asset = model.isSelected ? model.asset : nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        
        loadAssets()
    }
    
    func loadAssets() {
        
        func loadURLAsset(_ name: String, type: String) -> AVURLAsset? {
            if let path = Bundle.main.path(forResource: name, ofType: type) {
                return AVURLAsset.init(url: URL(fileURLWithPath: path))
            } else {
                assert(false, "can't load asset!")
                return nil
            }
        }
        
        let resourcs = [(name: "01_nebula", type: "mp4"),
                        (name: "02_blackhole", type: "mp4"),
                        (name: "03_nebula", type: "mp4"),
                        (name: "04_quasar", type: "mp4"),
                        (name: "05_blackhole", type: "mp4"),
                        (name: "01 Star Gazing", type: "m4a"),
                        (name: "02 Keep Going", type: "m4a"),
                        (name: "John F. Kennedy", type: "m4a"),
                        (name: "Ronald Reagan", type: "m4a")]

        let datas: [EasyTableCellModel] = resourcs.map { (name, type) in
            if let asset = loadURLAsset(name, type: type) {
                let model = EasyTableCellModel(title: name, asset: asset, isVideo: type == "mp4") { model in
                    print("selected")
                } playAction: { model in
                    print("play")
                }
                return model
            } else {
                return nil
            }
        }.compactMap {
            return $0
        }
                
        videoSourcesView.dataSources = datas.filter({ model in
            return model.isVideo
        })
        
        audioSourcesView.dataSources = datas.filter({ model in
            return !model.isVideo
        })
    
    }
    
    /// MARK ACTION
    @IBAction func compositionAction(_ sender: Any) {
        
        let selectedVideos = videoSourcesView.dataSources.filter { $0.isSelected }
        let selectedAudios = audioSourcesView.dataSources.filter { $0.isSelected }
        guard selectedVideos.count > 0, selectedAudios.count > -1 else { return }
        
        compositionAsset = AVMutableComposition()
        let videoTrack = compositionAsset!.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = compositionAsset!.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    
        var cursorTime = CMTime.zero
        selectedVideos.forEach { model in
            do {
                try videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: CMTime(seconds: 10, preferredTimescale: 1)),
                                            of: model.asset.tracks(withMediaType: .video).first!,
                                            at: cursorTime)
                cursorTime = CMTimeAdd(cursorTime, CMTime(seconds: 10, preferredTimescale: 1))
            } catch {
                print("compositionAction error!")
                compositionAsset = nil
                return
            }
        }
        
        if selectedAudios.count > 0 {
            let audioMix = AVMutableAudioMix()
            var inputAudioMixParams = [AVAudioMixInputParameters]()
            cursorTime = CMTime.zero
            
            selectedAudios.forEach { model in
                do {
                    let seconds = Double(min(model.duration, 10))
                    try audioTrack?.insertTimeRange(CMTimeRange(start: cursorTime, duration: CMTime(seconds: seconds, preferredTimescale: 1)),
                                                of: model.asset.tracks(withMediaType: .audio).first!,
                                                    at: CMTime.zero)
                    
                    if playerConfiguration.audioMix {
                        let audioMixParmaUp = AVMutableAudioMixInputParameters(track: audioTrack)
                        audioMixParmaUp.setVolume(0.1, at: CMTime.zero)
                        
                        audioMixParmaUp.setVolumeRamp(fromStartVolume: 0.0,
                                                    toEndVolume: 0.5,
                                                    timeRange: CMTimeRange(start: cursorTime, duration: CMTime(seconds: 2, preferredTimescale: 1)))
                        inputAudioMixParams.append(audioMixParmaUp)
                        
                        let audioMixParmaDown = AVMutableAudioMixInputParameters(track: audioTrack)
                        audioMixParmaDown.setVolumeRamp(fromStartVolume: 0.5,
                                                    toEndVolume: 0.0,
                                                        timeRange: CMTimeRange(start: CMTimeAdd(cursorTime, CMTime.init(seconds: seconds-2, preferredTimescale: 1)),
                                                                               duration: CMTime(seconds: 2, preferredTimescale: 1)))
                        inputAudioMixParams.append(audioMixParmaDown)
                    }
                    
                    cursorTime = CMTimeAdd(cursorTime, CMTime(seconds: seconds, preferredTimescale: 1))
                } catch {
                    print("compositionAction error! :\(error)")
                    compositionAsset = nil
                    return
                }
            }
            
            audioMix.inputParameters = inputAudioMixParams
            player.audioMix = audioMix
        }
        
        player.asset = compositionAsset!.copy() as? AVAsset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.player.playOrPauseButtonAction()
        }
    }
    
    @IBAction func addWaterMarkAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setTitle("Remove waterMark", for: .selected)
        } else {
            sender.setTitle("Add waterMark", for: .normal)
        }
        playerConfiguration.addWaterMark = sender.isSelected
        player.configuration = playerConfiguration
    }
    
    @IBAction func addTitleAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setTitle("Remove title", for: .selected)
        } else {
            sender.setTitle("Add title", for: .normal)
        }
        playerConfiguration.title = sender.isSelected ? "This is a Title" : nil
        player.configuration = playerConfiguration
    }
    
    @IBAction func audioMixAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setTitle("Remove Audio Mix", for: .selected)
        } else {
            sender.setTitle("Add Audio Mix", for: .normal)
        }
        playerConfiguration.audioMix = !playerConfiguration.audioMix
        player.configuration = playerConfiguration
        compositionAction("")
    }
    
    @IBAction func addAudioWaveGraphAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.setTitle("Remove Audio Wave Graph", for: .selected)
        } else {
            sender.setTitle("Add Audio Wave Graph", for: .normal)
        }
        playerConfiguration.waveGraph = !playerConfiguration.waveGraph
        player.configuration = playerConfiguration
        compositionAction("")
    }
    
    @IBOutlet weak var videoParamsView: UIView!
    @IBOutlet weak var audioParamsView: UIView!
    
    @IBAction func changeSegmentAction(_ sender: UISegmentedControl) {
        videoParamsView.isHidden = !(sender.selectedSegmentIndex == 0)
        audioParamsView.isHidden = !(sender.selectedSegmentIndex == 1)
    }
    
    @IBAction func exportAction(_ sender: UIButton) {
        
        
        
        
    }
    
    @IBAction func clearAction(_ sender: UIButton) {
        loadAssets()
        player.clear()
        updateButtonsState()
    }
    
    func updateButtonsState() {
        compositionButton.isEnabled = haveSelectedAny()
        exportButton.isEnabled = compositionAsset != nil
    }
    
    func haveSelectedAny() -> Bool {
        videoSourcesView.dataSources.filter { $0.isSelected }.count +
        audioSourcesView.dataSources.filter { $0.isSelected }.count > 0
    }
    
}

