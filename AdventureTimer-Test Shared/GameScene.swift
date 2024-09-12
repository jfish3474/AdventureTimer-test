import SpriteKit
import RiveRuntime
import SwiftUI
import AppKit
import Metal

class GameScene: SKScene {
    private var background: SKSpriteNode!
    private var clouds: SKSpriteNode!
    private var paperPlaneNode: SKSpriteNode!
    private var timerLabel: SKLabelNode!
    private var remainingTime: TimeInterval = 25 * 60 // 25 minutes in seconds
    private let backgroundScrollSpeed: CGFloat = 0.1
    private let cloudsScrollSpeed: CGFloat = 0.5 // Adjust this for desired cloud speed
    private var riveViewModel: RiveViewModel!
    private var hostingController: NSHostingController<AnyView>?

    override func didMove(to view: SKView) {
        // Diagnostic information
        print("Metal is supported: \(MTLCreateSystemDefaultDevice() != nil)")
        print("View's preferredFramesPerSecond: \(view.preferredFramesPerSecond)")
        print("View's ignoresSiblingOrder: \(view.ignoresSiblingOrder)")
        print("View's allowsTransparency: \(view.allowsTransparency)")
        
        if let device = MTLCreateSystemDefaultDevice() {
            print("GPU name: \(device.name)")
            print("GPU is low-power: \(device.isLowPower)")
            print("GPU is removable: \(device.isRemovable)")
        } else {
            print("Could not create Metal device")
        }

        setupBackground()
        setupClouds()
        setupPaperPlane()
        setupTimer()
    }
    
    private func setupBackground() {
        if let backgroundSprite = createScrollingSprite(imageNamed: "background", zPosition: -2) {
            background = backgroundSprite
            background.name = "background"
            addChild(background)
            
            if let secondBackground = background.copy() as? SKSpriteNode {
                secondBackground.position = CGPoint(x: background.size.width + size.width / 2, y: size.height / 2)
                secondBackground.name = "background"
                addChild(secondBackground)
            }
        } else {
            print("Failed to create background sprite.")
        }
    }
    
    private func setupClouds() {
        if let cloudsSprite = createScrollingSprite(imageNamed: "clouds", zPosition: -1) {
            clouds = cloudsSprite
            clouds.name = "clouds"
            addChild(clouds)
            
            if let secondClouds = clouds.copy() as? SKSpriteNode {
                secondClouds.position = CGPoint(x: clouds.size.width + size.width / 2, y: size.height / 2)
                secondClouds.name = "clouds"
                addChild(secondClouds)
            }
        } else {
            print("Failed to create clouds sprite.")
        }
    }
    
    private func createScrollingSprite(imageNamed: String, zPosition: CGFloat) -> SKSpriteNode? {
        #if os(iOS) || os(tvOS)
        guard let image = UIImage(named: imageNamed) else {
            print("Error: Image \(imageNamed) not found.")
            return nil
        }
        let texture = SKTexture(image: image)
        #elseif os(macOS)
        guard let image = NSImage(named: imageNamed) else {
            print("Error: Image \(imageNamed) not found.")
            return nil
        }
        let texture = SKTexture(image: image)
        #endif
        
        let sprite = SKSpriteNode(texture: texture)
        let aspectRatio = sprite.size.width / sprite.size.height
        sprite.size = CGSize(width: size.height * aspectRatio, height: size.height)
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sprite.zPosition = zPosition
        return sprite
    }
    
    private func setupPaperPlane() {
        // Load the Rive animation from a local file called "paperplane.riv"
        riveViewModel = RiveViewModel(fileName: "paperplane4")
        
        // Create a placeholder node for the paper plane
        paperPlaneNode = SKSpriteNode(color: .clear, size: CGSize(width: 100, height: 100))
        paperPlaneNode.position = CGPoint(x: 100, y: size.height / 2)
        addChild(paperPlaneNode)
        
        // Create and add the SwiftUI view
        let paperPlaneView = riveViewModel.view().frame(width: 100, height: 100)
        hostingController = NSHostingController(rootView: AnyView(paperPlaneView))
        if let hostingView = hostingController?.view {
            hostingView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            view?.addSubview(hostingView)
        } else {
            print("Failed to create hosting controller for paper plane view.")
        }
        
        // Update the position of the SwiftUI view to match the SKSpriteNode
        updatePaperPlanePosition()
    }
    
    private func updatePaperPlanePosition() {
        guard let view = self.view,
              let paperPlaneView = hostingController?.view,
              let paperPlaneNode = self.paperPlaneNode else { return }
        
        let scenePosition = paperPlaneNode.position
        let viewPosition = view.convert(scenePosition, from: self)
        paperPlaneView.frame.origin = CGPoint(x: viewPosition.x - paperPlaneView.frame.size.width / 2,
                                              y: viewPosition.y - paperPlaneView.frame.size.height / 2)
    }
    
    private func setupTimer() {
        timerLabel = SKLabelNode(fontNamed: "Arial")
        timerLabel.fontSize = 24
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width - 100, y: size.height - 50)
        timerLabel.text = formatTime(remainingTime)
        addChild(timerLabel)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Move background and clouds
        enumerateChildNodes(withName: "background") { node, _ in
            node.position.x -= self.backgroundScrollSpeed
            if node.position.x < -self.background.size.width / 2 {
                node.position.x += self.background.size.width * 2
            }
        }
        
        enumerateChildNodes(withName: "clouds") { node, _ in
            node.position.x -= self.cloudsScrollSpeed
            if node.position.x < -self.clouds.size.width / 2 {
                node.position.x += self.clouds.size.width * 2
            }
        }
        
        // Update paper plane position
        updatePaperPlanePosition()
        
        // Update timer
        remainingTime -= 1.0 / 60.0
        timerLabel.text = formatTime(remainingTime)
        
        if remainingTime <= 0 {
            // Game over logic here
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        // Remove the RiveView when the scene is removed
        hostingController?.view.removeFromSuperview()
        paperPlaneNode.removeFromParent()
    }
}
