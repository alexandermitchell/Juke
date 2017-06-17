//
//  TableViewController.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-13.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {

    @IBOutlet weak var tableView: UITableView!
   
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    //shows as zero before it is set (need to set it when we are transitioning)
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var songProgressBar: UIProgressView!

    
    @IBOutlet weak var albumArtImageView: UIImageView!
    var countDownTimer = Timer()
    var countUpTimer = Timer()
    var timeRemaining = 0
    var timeElapsed = 0 {
        didSet {
            updateProgressBar()
        }
    }
    var resumeTapped = false
    
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var manager = DataManager.shared()
    let jukeBox = JukeBoxManager()
    
    
    var trackArray: [Song] = [] {
        didSet {
            tableView.reloadData()
            songTitleLabel.text = trackArray[0].title
            artistNameLabel.text = trackArray[0].artist
            setMaxSongtime(milliseconds: Int(trackArray[0].duration))
            startTimer()
        }
    }
    var track: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        durationLabel.text = String(timeRemaining)
//        setMaxSongtime(seconds: 240) //use to set new song length when we start playing a new song
        timeElapsedLabel.text = String(timeElapsed)
        
      
        
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
        
        jukeBox.delegate = self

        
        

        // Do any additional setup after loading the view.
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
            let savedSong = NSKeyedArchiver.archivedData(withRootObject: newSong)
            jukeBox.send(song: savedSong as NSData)

            
        } else if segue.identifier == "newSearchSong" {
            let initialVC = segue.source as! AddMusicViewController
            guard let newSong = initialVC.selectedSong else {
                print("no song returned")
                return
            }
            trackArray.append(newSong)
            let savedSong = NSKeyedArchiver.archivedData(withRootObject: newSong)
            jukeBox.send(song: savedSong as NSData)

        }
    }
    
    //MARK: Timer Methods
    
    func setMaxSongtime(milliseconds: Int) {
        timeRemaining = milliseconds/1000
    }
    
    func startTimer() {
        countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TableViewController.updateCounter)), userInfo: nil, repeats: true)
        countUpTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(TableViewController.updateCountUpTimer)), userInfo: nil, repeats: true)
        
    }
    func updateCounter() {
        if timeRemaining == 0 {
            countDownTimer.invalidate()
            countUpTimer.invalidate()
            //notify everyone that the song is finished
            let notificationName = Notification.Name("songDidFinishPlaying")
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo:  ["nextSong" : "testNextSong", "finishedSong": "testFinishedSong"])
        } else {
            timeRemaining -= 1 //count up by 1 second at a time
            durationLabel.text = timeString(time: TimeInterval(timeRemaining))
        }
        
    }
    
    func updateCountUpTimer() {
        
            timeElapsed += 1 //count up by 1 second at a time
            timeElapsedLabel.text = timeString(time: TimeInterval(timeElapsed))
    }
    
    func pauseTimer() {
        if self.resumeTapped == false {
            countDownTimer.invalidate()
            self.resumeTapped = true
        } else {
            startTimer()
            self.resumeTapped = false
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
    
        return String(format:"%02d:%02d", minutes, seconds)
       
    }

    func updateProgressBar(){
        songProgressBar.progressTintColor = UIColor.blue
        songProgressBar.setProgress(Float(timeElapsed) / Float(timeRemaining), animated: true)
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
    
    func updateAfterFirstLogin () {
        if let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
    }
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken!)
        }
    }
    func setup() {
        auth.clientID = ConfigCreds.clientID
        auth.redirectURL = URL(string: ConfigCreds.redirectURLString)
        
        
        //REMEMBER TO ADD BACK SCOPES
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthUserFollowReadScope,SPTAuthUserLibraryReadScope,SPTAuthUserReadPrivateScope,SPTAuthUserReadTopScope,SPTAuthUserReadBirthDateScope,SPTAuthUserReadEmailScope]
        
        loginUrl = auth.spotifyWebAuthenticationURL()
        
        //loginUrl = auth.spotifyAppAuthenticationURL()
        
        
        
    }
    
    
    @IBAction func loginPressed(_ sender: UIButton) {
        
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
        
        //        UIApplication.shared.open(loginUrl!, options: [:]) { (bool) in
        //
        //        }
        
    }
    
    func updateLabels(song: Song) {
//        titleLabel.text = song.title
//        artistLabel.text = song.artist
        //        durationLabel.text = "\(song.duration)"
        
    }
    
//    @IBAction func sendSong1Tapped(_ sender: UIButton) {
//        let savedSong = NSKeyedArchiver.archivedData(withRootObject: trackArray[0])
//        jukeBox.send(song: savedSong as NSData)
//        updateLabels(song: trackArray[0])
//        
//    }
//    
//    @IBAction func sendSong2Tapped(_ sender: UIButton) {
//        let savedSong = NSKeyedArchiver.archivedData(withRootObject: trackArray[1])
//        jukeBox.send(song: savedSong as NSData)
//        updateLabels(song: trackArray[1])
//        
//    }
    
    
    
    
    @IBAction func getSong(_ sender: UIButton) {
        
        //        manager.spotifyCurrentUserPlaylists()
        //
        //        manager.spotifyPlaylistTracks(ownerID: "jmperezperez", playlistID: "3cEYpjA9oz9GiPac4AsH4n")
        
//        manager.spotifySearch(searchString: "perez") {(array) in
//            print("YAAAAAAAA")
//            print("Array deets, # of songs: \(array.count) array deets: \(array)")
//
//            self.trackArray = array
//        }
        
        
        
    }
    
    
    @IBAction func playSong(_ sender: UIButton) {
        self.player!.playSpotifyURI(self.track!, startingWith: 0, startingWithPosition: 0, callback: { (error) in
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
    func newSong(manager: JukeBoxManager, song: Song) {
        OperationQueue.main.addOperation {
            self.trackArray.append(song)
        }
    }

   
}
