import AVFoundation
import CoreImage
import CoreMediaIO

func fail(_ code: Int32, _ reason: String) -> Never {
    FileHandle.standardError.write(Data("iphone-shot: \(reason)\n".utf8))
    exit(code)
}

guard CommandLine.arguments.count == 2, !CommandLine.arguments[1].hasPrefix("-") else {
    fail(64, "usage: iphone-shot <output.png>")
}
let path = CommandLine.arguments[1]

guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
    fail(3, "not authorized: this terminal has no Camera permission")
}

var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
var allow: UInt32 = 1
CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, UInt32(MemoryLayout<UInt32>.size), &allow)

func phone() -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(
        deviceTypes: [.external], mediaType: .muxed, position: .unspecified
    ).devices.first
}

var found = phone()
for _ in 0..<20 where found == nil {
    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    found = phone()
}
guard let device = found, let input = try? AVCaptureDeviceInput(device: device) else {
    fail(2, "no device: no iPhone screen found (unlocked, trusted, on USB?)")
}

final class Grab: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var frames = 0
    func captureOutput(
        _ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection
    ) {
        frames += 1
        guard frames == 10, let pixels = CMSampleBufferGetImageBuffer(buffer) else { return }
        let image = CIImage(cvPixelBuffer: pixels)
        do {
            try CIContext().writePNGRepresentation(
                of: image, to: URL(fileURLWithPath: path), format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB())
        } catch {
            fail(5, "cannot write \(path): \(error.localizedDescription)")
        }
        print("\(path) \(Int(image.extent.width))x\(Int(image.extent.height))")
        exit(0)
    }
}

let session = AVCaptureSession()
let output = AVCaptureVideoDataOutput()
let grab = Grab()
output.setSampleBufferDelegate(grab, queue: DispatchQueue(label: "iphone-shot"))
session.addInput(input)
session.addOutput(output)
session.startRunning()
RunLoop.current.run(until: Date().addingTimeInterval(15))
fail(4, "no frame: \(device.localizedName) sent no video in 15 s")
