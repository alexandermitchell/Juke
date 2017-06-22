//
//  TestViewController.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-16.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import MGSwipeTableCell


class TestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, MGSwipeTableCellDelegate, UITextFieldDelegate {
    
    var manager = DataManager.shared()

    @IBOutlet weak var jukeView: UIView!
    @IBOutlet weak var albumImage: DraggableView!

    @IBOutlet weak var jukeHeight: NSLayoutConstraint!
    var originalHeight: CGFloat!
    var expandedHeight: Bool!
    
    // Currently Playing Info
    
    @IBOutlet weak var currentInfoWrapper: UIView!
    
    @IBOutlet weak var currentTrackLabel: UILabel!
    
    @IBOutlet weak var currentArtistLabel: UILabel!
    
    @IBOutlet weak var trackProgressView: UIProgressView!
    
    //Search View Wrapper And Search Results Table
    
    var searchWrapper: UIView!
    var searchField: UITextField!
    var resultsTable: UITableView!
    var filteredSongs: [Song]?
    var addMusicOptions = ["Playlists", "Recommendation", "Saved Music", "Recently Played"]
    var selectedSong: Song?
    
    
    
    
    
    //playlist Table
    
    var playListTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyboardDismiss = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(keyboardDismiss)

        //Initial Quadcurve setup
        // At some point, will make jukeView a custom UIView Class that will initialize a quadcurve upon setup and attach gesture capabilties

        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y + 2)
        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y + 2)
        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)

        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
        
        originalHeight = jukeHeight.constant
        albumImage.layer.cornerRadius = 10
        

        playlistTableSetup()
        searchWrapperSetup()
        
        
    }
    
    func searchWrapperSetup() {
        searchWrapper = UIView()
        view.addSubview(searchWrapper)
        
        searchWrapper.translatesAutoresizingMaskIntoConstraints = false
        searchWrapper.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
        searchWrapper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        searchWrapper.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        searchWrapper.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        searchField = UITextField()
        searchWrapper.addSubview(searchField)
        
        searchField.translatesAutoresizingMaskIntoConstraints = false
        
        searchField.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 0.67, constant: 0).isActive = true
        searchField.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor).isActive = true
        
        searchField.topAnchor.constraint(equalTo: searchWrapper.topAnchor, constant: 0).isActive = true
        
        searchField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        searchField.attributedPlaceholder = NSAttributedString(string: "Search for a track")
        
        resultsTable = UITableView()
        resultsTable.dataSource = self
        resultsTable.delegate = self
        
        let categoryNib = UINib(nibName: "SearchCategoryCell", bundle: nil)
        //let searchTrackNib = UINib
        
        resultsTable.register(categoryNib, forCellReuseIdentifier: "Cell")
        
        
        
        searchWrapper.addSubview(resultsTable)
        resultsTable.widthAnchor.constraint(equalTo: searchWrapper.widthAnchor, multiplier: 1.0, constant: 0).isActive = true
        
        resultsTable.centerXAnchor.constraint(equalTo: searchWrapper.centerXAnchor).isActive = true
        resultsTable.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0).isActive = true
        resultsTable.bottomAnchor.constraint(equalTo: searchWrapper.bottomAnchor, constant: 0).isActive = true
        
        
        
        
        
    }
    
    func playlistTableSetup() {
        
        playListTable = UITableView()
        
        playListTable.dataSource = self
        playListTable.delegate = self
        
        let nib = UINib(nibName: "PlaylistTableCell", bundle: nil)
        playListTable.register(nib, forCellReuseIdentifier: "Cell")
        

        jukeView.addSubview(playListTable)
        
        playListTable.backgroundColor = jukeView.backgroundColor
        
        playListTable.translatesAutoresizingMaskIntoConstraints = false
        playListTable.widthAnchor.constraint(equalTo: jukeView.widthAnchor, multiplier: 1).isActive = true
        playListTable.centerXAnchor.constraint(equalTo: jukeView.centerXAnchor).isActive = true
        playListTable.bottomAnchor.constraint(equalTo: jukeView.bottomAnchor).isActive = true
        
        playListTable.topAnchor.constraint(equalTo: currentInfoWrapper.bottomAnchor).isActive = true
        
        playListTable.isHidden = true
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch tableView {
        case resultsTable:
            if (searchField.text?.isEmpty)! {
                return addMusicOptions.count
            }
            break
        case playListTable:
            return 7
        default:
            break
        }
        return 0
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        swipeSettings.transition = MGSwipeTransition.clipCenter
        swipeSettings.keepButtonsSwiped = false
        expansionSettings.buttonIndex = 0
        expansionSettings.threshold = 1.0
        expansionSettings.expansionLayout = MGSwipeExpansionLayout.center
        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.cubicOut
        expansionSettings.fillOnTrigger = false
        
        let color = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 1.0)
        let font = UIFont(name: "HelveticaNeue-Light", size: 14)
        
        if direction == MGSwipeDirection.leftToRight {
//            let upvote = MGSwipeButton(title: "👏🏼", backgroundColor: UIColor.init(red: 0, green: 0, blue: 0, alpha: 0), padding: 15, callback: { (sender) -> Bool in
//                
//            })
            
            // reported issue of possible retain cycle in MGSwipeButton callback. Use [unowned self] if problem arises
            
            let upvote = MGSwipeButton(title: "", icon: #imageLiteral(resourceName: "heart2"), backgroundColor: UIColor.init(red: 254.0/255, green: 46.0/255, blue: 83.0/255, alpha: 0), padding: 15, callback: { (sender) -> Bool in
                print("upvoted")
                return true
            })
            
            if cell.swipeState == .swipingLeftToRight {
                upvote.iconTintColor(UIColor.white)
            }
            
            //upvote.titleLabel?.font = font
            //expansionSettings.expansionColor = UIColor.init(red: 254.0/255, green: 46.0/255, blue: 83.0/255, alpha: 1.0)
            
            
            return [upvote]
        } else {
            let downvote = MGSwipeButton(title: "👎🏼", backgroundColor: UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 0), padding: 15, callback: { (sender) -> Bool in
                print("downvoted")
                return true
            })
            downvote.titleLabel?.font = font
            expansionSettings.expansionColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 49/255.0, alpha: 0)
            return [downvote]
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tableView {
        case resultsTable:
            if (searchField.text?.isEmpty)! {
                let cell = resultsTable.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchCategoryCell
                
                return cell
            } else {
                let cell = resultsTable.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchTrackCell
                
                return cell
                
            }
            
        default:
            <#code#>
        }
        
        let cell = playListTable.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlaylistTableCell
        cell.delegate = self
        cell.selectionStyle = UITableViewCellSelectionStyle.none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
//        switch tableView {
//        case resultsTable:
//            
//        default:
//
//        }
        
        return 120
    }

    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint) {
        
        let layer = CAShapeLayer()
        
        jukeView.layer.addSublayer(layer)
        layer.strokeColor = jukeView.layer.backgroundColor
        layer.fillColor = jukeView.layer.backgroundColor
        layer.lineWidth = 1

        let path = UIBezierPath()
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        layer.path = path.cgPath
        path.stroke()
   
    }
    
    @IBAction func showPlaylist(_ sender: UISwipeGestureRecognizer) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            
            self.jukeHeight.constant = self.view.bounds.size.height - 100
            
            self.playListTable.isHidden = false
            
            self.playListTable.heightAnchor.constraint(equalToConstant: 0).isActive = false

            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
    }
    
    @IBAction func hidePlaylist(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            
            self.jukeHeight.constant = self.originalHeight
            
            self.playListTable.isHidden = true

            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }

}


extension UIViewController {
    func hideKeyboard() {
        self.view.endEditing(true)
    }
}

//extension TableViewController : JukeBoxManagerDelegate {
//    
//    func connectedDevicesChanged(manager: JukeBoxManager, connectedDevices: [String]) {
//        OperationQueue.main.addOperation {
//            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
//        }
//    }
//    
//    //MARK: NEW-----------
//    func newSong(manager: JukeBoxManager, song: Song) {
//        OperationQueue.main.addOperation {
//            self.trackArray.append(song)
//            //            self.player!.queueSpotifyURI(song.songURI, callback: nil)
//            
//        }
//    }
//}
//
//extension TableViewController: SongTimerProgressBarDelegate {
//    
//    func progressBarNeedsUpdate() {
//        self.updateProgressBar()
//    }
//    
//    func songDidEnd() {
//        playerIsActive = false
//        playbackButton.setButtonState(.pausing, animated: true)
//        trackArray.remove(at: 0)
//        songTitleLabel.text = trackArray[0].title
//        artistNameLabel.text = trackArray[0].artist
//        didTapPlaybackButton(self)
//    }
//    
//    func labelsNeedUpdate() {
//        durationLabel?.text = songTimer.timeString(time: TimeInterval(songTimer.timeRemaining))
//        timeElapsedLabel.text = songTimer.timeString(time: TimeInterval(songTimer.timeElapsed))
//    }
//}


