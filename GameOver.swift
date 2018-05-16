//
//  GameOver.swift
//  gameProject
//
//  Created by Noah Landes on 5/10/18.
//  Copyright © 2018 Noah Landes. All rights reserved.
//

import Foundation
import SpriteKit

class GameOver: SKScene {
    init(size: CGSize, won:Bool) {
        super.init(size: size)
        
        //set background color to white
        backgroundColor = SKColor.white
        
        //if won is true or false show the right message
        let message = won ? "You won!" : "You lose"
        
        //displaying a label of text on screen
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        //wait for 3 seconds then run the flip scene trasnition that lasts .5 secs and create the scene
        run(SKAction.sequence([SKAction.wait(forDuration: 3.0),
                               SKAction.run() { [weak self] in
                                
                                guard let `self` = self else { return}
                                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                                let scene = GameScene(size: size)
                                self.view?.presentScene(scene, transition:reveal)
                                
            } ]))
    }
    
    //dummy implementation needed 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) hasnt been implemented")
    }
}
