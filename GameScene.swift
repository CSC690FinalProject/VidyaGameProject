//
//  GameScene.swift
//  gameProject
//
//  Created by Noah Landes on 3/26/18.
//  Copyright © 2018 Noah Landes. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let none       : UInt32 = 0
    static let all        : UInt32 = UInt32.max
    static let monster    : UInt32 = 0b1 //1st bit of the 32 is monster
    static let projectile : UInt32 = 0b10 //2nd bit is projectile
    static let player     : UInt32 = 0b100 //3rd is player
}

//overloading operators to do vector math for player projectile
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x,  y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }


func normalized() -> CGPoint {
    return self/length()
    }
}

class GameScene: SKScene {
    
    let player = SKSpriteNode(imageNamed: "player") //declare private constant for player and pass image for the player
    var monstersDestroyed = 0
    
    let backgroundImage = SKSpriteNode(imageNamed: "background")
    
    
    
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor.white
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5) //set the player image to be centered and close to the bottom of the screen
        
        addChild(player)
        
        physicsWorld.gravity = .zero // no gravity
        physicsWorld.contactDelegate = self //notify delegate when two bodies hit
        
        //calling the method to create never ending monsters
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        //run a sequence to call the add monster function to wait 1 second and add another monster endlessly
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(addMonster),
                               SKAction.wait(forDuration: 1.0)
                ])))

    }
    
    //simple random number generator
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max-min) + min
    }
    
    func addMonster(){
        
        let monster = SKSpriteNode(imageNamed: "monster") //create monster and pass the image
        
        let actualY = random(min: monster.size.height / 2, max: size.height - monster.size.height / 2) //setting the y coordinates for themosnter spawn
        
        monster.position =  CGPoint(x: size.width + monster.size.width/2, y: actualY) //setting the monster spawn position just off screenand in a random y position
        
        addChild(monster) //adding the monster to the scene
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) //create physics body for sprite as a rectangle
        monster.physicsBody?.isDynamic = true //sprite is dynamic using move actions
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster //bit mask is monster category
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile //choose the projectile category this object is
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none //setting no physics category so they can go through each other
        
        let actualDuration = random(min:CGFloat(2.0), max:CGFloat(4.0)) //setting the monster speed
        
        //make the monster continue to move from right to left in a random speed by putting in how long it should take to move
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        
        //removing the monster from the scene when its off screen to the left
        let actionMoveDone = SKAction.removeFromParent()
        
        
        //create the lose action to show the game over screen when player dies
        let loseAction = SKAction.run() { [weak self] in
            guard let `self` = self else {return}
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOver( size:self.size, won:false)
            self.view?.presentScene(gameOver, transition: reveal)
            }
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
        }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
        
        // find out where the user touched the screen
        guard let touch = touches.first else {
            return
        }
        
        //add sound effect here
        
        let touchLocation = touch.location(in: self)
        
        // set up starting location of player projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2) //create the physics body for the projectile as a cirlce
        projectile.physicsBody?.isDynamic = true //dynamic to let us handle the physics
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile //choose the bitmask from physics struct
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster //when touching a monster notify listener
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none //projectile can go through
        projectile.physicsBody?.usesPreciseCollisionDetection = true //use for fast moving object to make sure its detected when hitting monster
        
        // subtract the previous touch location from players position to get vector for shooting
        let offset = touchLocation - projectile.position
        
        // if shooting backwards dont shoot
        if (offset.x < 0) {
            return
        }
        
        // if passed check add the projectile to shoot
        addChild(projectile)
        
        // get direction of where to shoot in vector form
        let diretion = offset.normalized()
        
        // make the projectile continue untill offscreen
        let shootAmount = diretion * 1000
        
        // add it to the position player is shooting from to where it should end
        let realDest = shootAmount + projectile.position
        
        // shoot the projectile and remove once reached end of screen
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    //remove projectile when hits monster and check if player wins
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        var monstersDestroyed = 0
        
        monstersDestroyed += 1
        
        
        //if the player kills 30 monsters they win
        if monstersDestroyed > 30 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOver = GameOver(size: self.size, won:true)
            view?.presentScene(gameOver, transition: reveal)
        }
    }
    
    //remove monster from game if they hit player and check for game over condition
    func monsterDidCollideWithPLayer(monster:SKSpriteNode, player:SKSpriteNode){
        print("ouch!")
        monster.removeFromParent()
        
        var timesHit = 0
        
        timesHit += 1
        
        if timesHit > 3 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOVer = GameOver(size:self.size, won:false)
            view?.presentScene(gameOVer, transition: reveal)
        }
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        
        //passes the two bodies that hit and sort them by category bit to check if something should be done when a collission occur
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //check if two bodies that collided are monster and projectile if they are call the appropiate method
        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0)) && (secondBody.categoryBitMask & PhysicsCategory.projectile != 0) {
            if let monster = firstBody.node as? SKSpriteNode,
                let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        //check if the two bodies that hit are a monster and player
        if ((firstBody.categoryBitMask & PhysicsCategory.player != 0)) && (secondBody.categoryBitMask & PhysicsCategory.monster != 0) {
            if let player = firstBody.node as? SKSpriteNode,
                let monster = secondBody.node as? SKSpriteNode {
                monsterDidCollideWithPLayer(monster: monster, player: player)
            }
        
    }
    }
}
