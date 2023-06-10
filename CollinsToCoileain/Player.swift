//
//  Player.swift
//  CollinsToCoileain
//
//  Created by Jónótdón Ó Coileáin on 6/8/23.
//

import Foundation
import AVKit

class Player: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var player: AVPlayer?
    
    func playLocal(word: URL) {
        if audioPlayer?.isPlaying != true {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: word)
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
            } catch {
                print(error)
            }
        }
    }
    
    func playOnWebsite(phrase: [String]) {
        var items: [AVPlayerItem] = []
        for word in phrase {
            let urlString = "https://www.teanglann.ie/CanC/" + word
            if let url = URL(string: urlString) {
                let playerItem = AVPlayerItem(url: url)
                items.append(playerItem)
            }
        }
        self.player = AVQueuePlayer(items: items)
        self.player?.volume = 1.0
        self.player?.play()
    }
}
