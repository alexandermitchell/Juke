//
//  TableViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-13.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import PlaybackButton

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
   //MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    //shows as zero before it is set (need to set it when we are transitioning)
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var songProgressBar: UIProgressView!
    @IBOutlet weak var playbackButton: PlaybackButton!
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    
    //MARK: Properties
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var manager = DataManager.shared()
    let jukeBox = JukeBoxManager()
    var playerIsActive: Bool = false
    
    var songTimer = SongTimer()
    var trackArray: [Song] = [] {
        didSet {
            tableView.reloadData()
            updateCurrentTrackInfo()
            if !playerIsActive {
                hostPlayNextSong()
                playerIsActive = true
            }
            
            print("\(trackArray[0].isExplicit)")
            //need to fetch album art
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        jukeBox.delegate = self
//        jukeBox.isHost = true //this needs to be set in a login
        songTimer.delegate = self
        labelsNeedUpdate()
        setup()
    
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
    
        //        self.playbackButton.layer.cornerRadius = self.playbackButton.frame.size.height / 2
        //        self.playbackButton.layer.borderWidth = 2.0
        self.playbackButton.adjustMargin = 1
        self.playbackButton.duration = 0.3 // animation duration default 0.24
    
    }
    
//    func playNewSong() {
//        
//        if jukeBox.isHost {
//            
//           hostPlayNextSong()
//            
//        } else {
//            
//            nonHostPlayNextSong()
//        }
//    }
    
    func hostPlayNextSong() {
        
        if playerIsActive {
            trackArray.removeFirst()
        }
    
        guard let firstSong = trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        //play new song and adjust timers
        self.player?.playSpotifyURI(firstSong.songURI, startingWith: 0, startingWithPosition: 0, callback: nil)
        songTimer.setMaxSongtime(milliseconds: Int(firstSong.duration))
        
        playbackButton.setButtonState(.playing, animated: false)
        view.layoutIfNeeded()
        //send new song event to connected peers
        let event = Event(songAction: .startNewSong, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
        songTimer.startTimer()
        //won't update - is this getting called before the button is instantiated?
  


    }
    
    func nonHostPlayNextSongFrom(_ event: Event) {
        
        if playerIsActive {
            trackArray.removeFirst()
        }


        
        songTimer.countDownTimer.invalidate()
        playbackButton.setButtonState(.playing, animated: true)
        updateTimersFrom(event)
        songTimer.startTimer()
        playerIsActive = true

        
    }
    
    func toggleHostPlayState() {
        
        if jukeBox.isHost {
            
            if self.playbackButton.buttonState == .playing {
                
                pausePlayback()
                
            } else {
                
                resumePlayback()
                
            }
            
            sendTogglePlayEvent()
            
        }
    }
    
    func pausePlayback() {
        self.player?.setIsPlaying(false, callback: nil)
        self.playbackButton.setButtonState(.pausing, animated: true)
        songTimer.pauseTimer()
        
    }
    
    func resumePlayback() {
        self.player?.setIsPlaying(true, callback: nil)
        self.playbackButton.setButtonState(.playing, animated: true)
        songTimer.pauseTimer()
        
    }
    
    func sendTogglePlayEvent() {
        
        guard let firstSong = trackArray.first else {
            print("No Song")
            //can handle no song in here
            return
        }
        
        let event = Event(songAction: .togglePlay, song: firstSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
        let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
        jukeBox.send(event: newEvent as NSData)
        
    }
    
    func updateCurrentTrackInfo() {
        songTitleLabel.text = trackArray[0].title
        artistNameLabel.text = trackArray[0].artist
        //album art = 
        //isExplicit =

    }
   
    @IBAction func becomeHostButtonTapped(_ sender: Any) {
        self.jukeBox.isHost = true
        print("I have become the host")
    }
    
    @IBAction func didTapPlaybackButton(_ sender: Any) {
        
        toggleHostPlayState()
    
    }
    
//        if jukeBox.isHost {
//        
//            if self.playbackButton.buttonState == .playing {
//                self.player?.setIsPlaying(false, callback: nil)
//                self.playbackButton.setButtonState(.pausing, animated: true)
//                
//                let event = Event(songAction: .togglePlay, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
//                let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
//                jukeBox.send(event: newEvent as NSData)
//                
//                
//                
//                songTimer.pauseTimer()
//                
//            } else if self.playbackButton.buttonState == .pausing {
//                //need to check if player is active - if active then set isPlaying to true if not, call the playwithURI
//                if !playerIsActive {
//                    self.player?.playSpotifyURI(trackArray.first?.songURI, startingWith: 0, startingWithPosition: 0, callback: nil)
//                    
//                    songTimer.setMaxSongtime(milliseconds: Int(trackArray[0].duration))
//                    
//                    //wrap up in function
//                    //might be causing second timer
//                    let event = Event(songAction: .startNewSong, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
//                    let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
//                    jukeBox.send(event: newEvent as NSData)
//                    
//                    //this is causing issues
//                    songTimer.startTimer()
//                    playerIsActive = true
//                } else {
//                    self.player?.setIsPlaying(true, callback: nil)
//                    //wrap up in function
//                    let event = Event(songAction: .togglePlay, song: trackArray[0], totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
//                    let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
//                    jukeBox.send(event: newEvent as NSData)
//                    
//                    
//                    songTimer.pauseTimer()
//                }
//                
//                self.playbackButton.setButtonState(.playing, animated: true)
//            }
//            
//        }
//    }
    
    func togglePlayButtonState() {
        if self.playbackButton.buttonState == .pausing {
            self.playbackButton.setButtonState(.playing, animated: true)
        } else {
            self.playbackButton.setButtonState(.pausing, animated: true)
        }
    }
    // MARK: - Navigation
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
        if segue.identifier == "first" {
            let initialVC = segue.source as! SongViewController
            guard let newSong = initialVC.selectedSong else {
                print("no song returned")
                return
            }
            trackArray.append(newSong)
//            let savedSong = NSKeyedArchiver.archivedData(withRootObject: newSong)
//            jukeBox.send(song: savedSong as NSData)
            
            let event = Event(songAction: .addSong, song: newSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox.send(event: newEvent as NSData)
            
            //Int(songTimer.totalSongTime)
            
            
            
        } else if segue.identifier == "newSearchSong" {
            let initialVC = segue.source as! AddMusicViewController
            guard let newSong = initialVC.selectedSong else {
                print("no song returned")
                return
            }
            trackArray.append(newSong)
//            let savedSong = NSKeyedArchiver.archivedData(withRootObject: newSong)
//            jukeBox.send(song: savedSong as NSData)
            
            let event = Event(songAction: .addSong, song: newSong, totalSongTime: Int(songTimer.totalSongTime), timeRemaining: songTimer.timeRemaining, timeElapsed: songTimer.timeElapsed)
            let newEvent = NSKeyedArchiver.archivedData(withRootObject: event)
            jukeBox.send(event: newEvent as NSData)

            
        }
    }
    
    
    
    func updateProgressBar(){
        songProgressBar.progressTintColor = UIColor.blue
        songProgressBar.setProgress(Float(songTimer.timeElapsed) / songTimer.totalSongTime, animated: true)
        songProgressBar.layoutIfNeeded()
    }
    
    
    
    //MARK: TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JukeTableViewCell
        cell.textLabel?.text = trackArray[indexPath.row].title
        
        return cell
        
    }
    
    //MARK: Spotify Authentication
    
    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
    }
    @IBAction func loginPressed(_ sender: UIButton) {
        
//        if UIApplication.shared.openURL(loginUrl!) {
//            if auth.canHandle(auth.redirectURL) {
//                // To do - build in error handling
//            }
//
//        }
        UIApplication.shared.open(loginUrl!, options: [:]) { (didFinish) in
            if didFinish {
                if self.auth.canHandle(self.auth.redirectURL) {
                    //build in error handling
                }
                
            }
        }
    }
    
    
    func updateAfterFirstLogin () {
        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
    }
    
    //MARK: Audio Player Methods
    
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken!)
            
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        
    }
    
    @IBAction func playSong(_ sender: UIButton) {
        self.player!.playSpotifyURI(self.trackArray.first?.songURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
            
            print(error ?? "no error")
        })
        
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        print("\(session.accessToken)")
        
        print("\(session.encryptedRefreshToken)")
        print("\(auth.clientID)")
    }
    
}

extension TableViewController : JukeBoxManagerDelegate {
    
    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    //MARK: NEW-----------
    func newEvent(manager: JukeBoxManager, event: Event) {
        OperationQueue.main.addOperation {
            switch event.songAction {
            case .addSong:
                print("add song")
                self.trackArray.append(event.song)
            case .removeSong:
                print("remove Song")
            case .togglePlay:
                print("toggle play")
                
                self.updateTimersFrom(event)
                self.songTimer.pauseTimer()
                self.togglePlayButtonState()
                
            case .startNewSong:
                
                self.nonHostPlayNextSongFrom(event)

                
                
            
            
            //            self.player!.queueSpotifyURI(song.songURI, callback: nil)
            
        }
    }
    }
    
    func updateTimersFrom(_ event: Event) {
        self.songTimer.totalSongTime = Float(event.totalSongTime)
        self.songTimer.timeRemaining = event.timeRemaining
        self.songTimer.timeElapsed = event.timeElapsed


    }
}

extension TableViewController: SongTimerProgressBarDelegate {
    
    func progressBarNeedsUpdate() {
        self.updateProgressBar()
    }
    
    func songDidEnd() {
        
        if jukeBox.isHost {
            hostPlayNextSong()
        }
//        playbackButton.setButtonState(.pausing, animated: true)
//        trackArray.remove(at: 0)
//        updateCurrentTrackInfo()

    }
    
    func labelsNeedUpdate() {
        durationLabel?.text = songTimer.timeString(time: TimeInterval(songTimer.timeRemaining))
        timeElapsedLabel.text = songTimer.timeString(time: TimeInterval(songTimer.timeElapsed))
    }
    func syncResumeTapped(resumeTapped: Bool) {
        self.songTimer.resumeTapped = resumeTapped
    }
}



