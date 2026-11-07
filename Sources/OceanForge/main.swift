import AppKit
import SceneKit
import SwiftUI
import QuartzCore

@main
struct OceanForgeApp: App {
    var body: some Scene {
        WindowGroup { SandboxView().frame(minWidth: 900, minHeight: 600) }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct SandboxView: View {
    @State private var reset = UUID()
    @State private var paused = false
    var body: some View {
        ZStack(alignment: .top) {
            OceanView(reset: reset, paused: paused).ignoresSafeArea()
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("OCEANFORGE").font(.system(size: 19, weight: .black, design: .rounded)).tracking(3)
                        Text("SHIP & OCEAN SANDBOX").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2).foregroundColor(.cyan)
                    }
                    Spacer()
                    Button(paused ? "RESUME" : "PAUSE") { paused.toggle() }
                    Button("RESET") { reset = UUID(); paused = false }
                }.buttonStyle(ForgeButton()).padding(20)
                Spacer()
                HStack {
                    Label("DRAG TO ORBIT", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    Spacer()
                    Label("SCROLL TO ZOOM", systemImage: "magnifyingglass")
                    Spacer()
                    Label("CLICK WATER FOR RIPPLES", systemImage: "water.waves")
                }.font(.system(size: 10, weight: .bold, design: .monospaced)).padding(18)
                    .background(Color.black.opacity(0.55))
            }
        }.preferredColorScheme(.dark)
    }
}

struct ForgeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 10, weight: .heavy, design: .monospaced))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Color.cyan.opacity(configuration.isPressed ? 0.35 : 0.12))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.cyan.opacity(0.6)))
            .foregroundColor(.white).cornerRadius(5)
    }
}

struct OceanView: NSViewRepresentable {
    let reset: UUID
    let paused: Bool
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = World.scene()
        v.backgroundColor = NSColor(red: 0.015, green: 0.045, blue: 0.075, alpha: 1)
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = false
        v.antialiasingMode = .multisampling4X
        v.delegate = context.coordinator
        v.isPlaying = true
        context.coordinator.view = v
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.click(_:)))
        v.addGestureRecognizer(click)
        return v
    }
    func updateNSView(_ v: SCNView, context: Context) {
        if context.coordinator.reset != reset {
            v.scene = World.scene()
            context.coordinator.reset = reset
            context.coordinator.start = CACurrentMediaTime()
        }
        v.isPlaying = !paused
    }
    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        weak var view: SCNView?
        var reset = UUID()
        var start = CACurrentMediaTime()
        @objc func click(_ g: NSClickGestureRecognizer) {
            guard let v = view, g.state == .ended else { return }
            let hits = v.hitTest(g.location(in: v), options: [:])
            guard let p = hits.first(where: { $0.node.name == "ocean" })?.worldCoordinates,
                  let scene = v.scene else { return }
            World.ripple(p, scene)
        }
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let root = renderer.scene?.rootNode.childNode(withName: "ship", recursively: false) else { return }
            let t = time - start
            root.position.y = 0.16 + Float(sin(t * 0.8) * 0.12 + sin(t * 1.65) * 0.035)
            root.eulerAngles.z = Float(sin(t * 0.52) * 0.035)
            root.eulerAngles.x = Float(cos(t * 0.7) * 0.022)
            for n in renderer.scene?.rootNode.childNodes.filter({ $0.name == "ripple" }) ?? [] {
                let age = CGFloat(time - (n.userData?["born"] as? Double ?? time))
                let s = Float(1 + age * 1.5)
                n.scale = SCNVector3(s, 1, s)
                n.opacity = max(0, 1 - age / 2.1)
                if age > 2.1 { n.removeFromParentNode() }
            }
        }
    }
}

enum World {
    static func scene() -> SCNScene {
        let scene = SCNScene()
        let ambient = SCNLight(); ambient.type = .ambient; ambient.intensity = 450
        let a = SCNNode(); a.light = ambient; scene.rootNode.addChildNode(a)
        let sun = SCNLight(); sun.type = .directional; sun.intensity = 1300
        let s = SCNNode(); s.light = sun; s.eulerAngles = SCNVector3(-0.9, 0.5, 0)
        scene.rootNode.addChildNode(s)

        let camera = SCNCamera(); camera.fieldOfView = 50
        let cam = SCNNode(); cam.camera = camera; cam.position = SCNVector3(9, 7, 12)
        cam.look(at: SCNVector3(0, 0.7, 0)); scene.rootNode.addChildNode(cam)

        let plane = SCNPlane(width: 200, height: 200)
        let water = SCNMaterial()
        water.diffuse.contents = NSColor(red: 0.012, green: 0.16, blue: 0.23, alpha: 1)
        water.metalness.contents = 0.42; water.roughness.contents = 0.2
        plane.materials = [water]
        let sea = SCNNode(geometry: plane); sea.name = "ocean"
        sea.eulerAngles.x = -.pi / 2; scene.rootNode.addChildNode(sea)

        let ship = makeShip(); ship.name = "ship"; ship.position.y = 0.16
        scene.rootNode.addChildNode(ship)
        return scene
    }

    static func makeShip() -> SCNNode {
        let root = SCNNode()
        func addBox(_ name: String, _ size: SCNVector3, _ pos: SCNVector3, _ color: NSColor, _ chamfer: CGFloat = 0.04) {
            let g = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: chamfer)
            let m = SCNMaterial(); m.diffuse.contents = color; m.metalness.contents = 0.32; m.roughness.contents = 0.38
            g.materials = [m]
            let n = SCNNode(geometry: g); n.name = name; n.position = pos; root.addChildNode(n)
        }
        addBox("red steel hull", SCNVector3(8.2, 1.15, 2.0), SCNVector3(0, 0.15, 0), NSColor(red: 0.48, green: 0.065, blue: 0.045, alpha: 1), 0.2)
        addBox("deck", SCNVector3(7.95, 0.16, 1.88), SCNVector3(0, 0.79, 0), NSColor(red: 0.72, green: 0.68, blue: 0.57, alpha: 1))
        addBox("bridge", SCNVector3(1.7, 1.05, 1.35), SCNVector3(0.95, 1.36, 0), NSColor(white: 0.83, alpha: 1), 0.07)
        addBox("bridge windows", SCNVector3(1.73, 0.27, 1.38), SCNVector3(0.95, 1.65, 0), NSColor(red: 0.025, green: 0.12, blue: 0.17, alpha: 1), 0.01)
        for x: Float in [-3.05, 3.05] {
            addBox("raised deck", SCNVector3(1.6, 0.4, 1.85), SCNVector3(x, 1.05, 0), NSColor(red: 0.66, green: 0.63, blue: 0.54, alpha: 1))
        }
        for x: Float in [-1.25, -0.35] {
            let f = SCNCylinder(radius: 0.23, height: 1.0)
            f.firstMaterial?.diffuse.contents = NSColor(red: 0.88, green: 0.28, blue: 0.045, alpha: 1)
            let n = SCNNode(geometry: f); n.position = SCNVector3(x, 1.35, 0); root.addChildNode(n)
            let cap = SCNCylinder(radius: 0.25, height: 0.12)
            cap.firstMaterial?.diffuse.contents = NSColor(white: 0.12, alpha: 1)
            let c = SCNNode(geometry: cap); c.position = SCNVector3(x, 1.9, 0); root.addChildNode(c)
        }
        for side: Float in [-1, 1] {
            for i in 0..<13 {
                let p = SCNCylinder(radius: 0.075, height: 0.035)
                p.firstMaterial?.diffuse.contents = NSColor(white: 0.025, alpha: 1)
                let n = SCNNode(geometry: p)
                n.position = SCNVector3(-3.65 + Float(i) * 0.6, 0.2, side * 1.015)
                n.eulerAngles.x = .pi / 2; root.addChildNode(n)
            }
        }
        let mast = SCNCylinder(radius: 0.035, height: 2.2)
        mast.firstMaterial?.diffuse.contents = NSColor(white: 0.82, alpha: 1)
        let m = SCNNode(geometry: mast); m.position = SCNVector3(2.7, 2, 0); root.addChildNode(m)
        return root
    }

    static func ripple(_ p: SCNVector3, _ scene: SCNScene) {
        let g = SCNTorus(ringRadius: 0.38, pipeRadius: 0.018)
        g.firstMaterial?.diffuse.contents = NSColor.cyan
        g.firstMaterial?.emission.contents = NSColor.cyan.withAlphaComponent(0.35)
        let n = SCNNode(geometry: g); n.name = "ripple"; n.eulerAngles.x = .pi / 2
        n.position = SCNVector3(p.x, 0.025, p.z); n.userData = ["born": CACurrentMediaTime()]
        scene.rootNode.addChildNode(n)
    }
}
