import Foundation
import Flutter
import HaishinKit
import AVFoundation
import VideoToolbox

var imageData: CIImage?
var imageHandle: String?
class RTMPStreamHandler: NSObject, MethodCallHandler {
    private let plugin: SwiftHaishinKitPlugin
    private var instance: RTMPStream?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    init(plugin: SwiftHaishinKitPlugin, handler: RTMPConnectionHandler) {
        self.plugin = plugin
        super.init()
        let id = Int(bitPattern: ObjectIdentifier(self))
        if let registrar = plugin.registrar {
            self.eventChannel = FlutterEventChannel(name: "com.haishinkit.eventchannel/\(id)", binaryMessenger: registrar.messenger())
            self.eventChannel?.setStreamHandler(self)
        } else {
            self.eventChannel = nil
        }
        if let connection = handler.instance {
            let instance = RTMPStream(connection: connection)
            instance.addEventListener(.rtmpStatus, selector: #selector(RTMPStreamHandler.handler), observer: self)
            if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
                instance.orientation = orientation
            }
            NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
            self.instance = instance
        }
        guard let url = URL(string: "https://img1.baidu.com/it/u=413643897,2296924942&fm=253&fmt=auto&app=138&f=JPEG?w=800&h=500") else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error  in
            if let image = UIImage(data: data!) {
                imageData = CIImage(image: image)
            } else {
                print(error ?? "")
            }
        }
        .resume()
        _ = instance?.registerVideoEffect(MonochromeEffect())
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any?] else {
            return
        }
        switch call.method {
        case "RtmpStream#setAudioSettings":
            guard
                let settings = arguments["settings"] as? [String: Any?] else {
                return
            }
            if let muted = settings["muted"] as? Bool {
                instance?.audioSettings[.muted] = muted
            }
            if let bitrate = settings["bitrate"] as? NSNumber {
                instance?.audioSettings[.bitrate] = bitrate.intValue
            }
            result(nil)
        case "RtmpStream#setVideoSettings":
            guard
                let settings = arguments["settings"] as? [String: Any?] else {
                return
            }
            if let muted = settings["muted"] as? Bool {
                instance?.videoSettings[.muted] = muted
            }
            if let bitrate = settings["bitrate"] as? NSNumber {
                instance?.videoSettings[.bitrate] = bitrate.intValue
            }
            if let width = settings["width"] as? NSNumber {
                instance?.videoSettings[.width] = width.intValue
            }
            if let height = settings["height"] as? NSNumber {
                instance?.videoSettings[.height] = height.intValue
            }
            if let frameInterval = settings["frameInterval"] as? NSNumber {
                instance?.videoSettings[.maxKeyFrameIntervalDuration] = frameInterval.intValue
            }
            result(nil)
        case "RtmpStream#setCaptureSettings":
            guard
                let settings = arguments["settings"] as? [String: Any?] else {
                return
            }
            if let fps = settings["fps"] as? NSNumber {
                instance?.captureSettings[.fps] = fps.intValue
            }
            if let continuousAutofocus = settings["continuousAutofocus"] as? Bool {
                instance?.captureSettings[.continuousAutofocus] = continuousAutofocus
            }
            if let continuousExposure = settings["continuousExposure"] as? Bool {
                instance?.captureSettings[.continuousExposure] = continuousExposure
            }
            result(nil)
        case "RtmpStream#attachAudio":
            let source = arguments["source"] as? [String: Any?]
            if source == nil {
                instance?.attachAudio(nil)
            } else {
                instance?.attachAudio(AVCaptureDevice.default(for: .audio))
            }
            result(nil)
        case "RtmpStream#attachVideo":
            let source = arguments["source"] as? [String: Any?]
            if source == nil {
                instance?.attachCamera(nil)
            } else {
                var devicePosition = AVCaptureDevice.Position.back
                if let position = source?["position"] as? String {
                    switch position {
                    case "front":
                        devicePosition = .front
                    case "back":
                        devicePosition = .back
                    default:
                        break
                    }
                }
                instance?.attachCamera(DeviceUtil.device(withPosition: devicePosition))
            }
            result(nil)
        case "RtmpStream#play":
            instance?.play(arguments["name"] as? String)
            result(nil)
        case "RtmpStream#publish":
            instance?.publish(arguments["name"] as? String)
            result(nil)
        case "RtmpStream#registerTexture":
            guard
                let registry = plugin.registrar?.textures() else {
                return
            }
            if instance?.mixer.drawable == nil {
                let texture = NetStreamDrawableTexture(registry: registry)
                if let instance = instance {
                    texture.attachStream(instance)
                }
                result(texture.id)
            } else {
                if let texture = instance?.mixer.drawable as? NetStreamDrawableTexture {
                    if let width = arguments["width"] as? NSNumber,
                       let height = arguments["height"] as? NSNumber {
                        texture.bounds = CGSize(width: width.doubleValue, height: height.doubleValue)
                    }
                }
                result(nil)
            }
        case "RtmpStream#close":
            instance?.close()
        case "RtmpStream#dispose":
            instance?.removeEventListener(.rtmpStatus, selector: #selector(handler))
            instance?.close()
            instance = nil
            plugin.onDispose(id: Int(bitPattern: ObjectIdentifier(self)))
            result(nil)
        case "RtmpStream#handleImage":
            let type = arguments["name"] as? String
            imageHandle = type
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @objc
    private func handler(_ notification: Notification) {
        let event = Event.from(notification)
        var map: [String: Any?] = [:]
        map["type"] = event.type.rawValue
        map["data"] = ASObjectUtil.removeEmpty(event.data)
        eventSink?(map)
    }

    @objc
    private func on(_ notification: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        instance?.orientation = orientation
    }
}

extension RTMPStreamHandler: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}


final class MonochromeEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CIColorMonochrome")

    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        if (imageHandle == nil) {
            return image
        } else if (imageHandle == "static") {
            return imageData ?? image
        } else if (imageHandle == "filter") {
            guard let filter: CIFilter = filter else {
                return image
            }
            filter.setValue(image, forKey: "inputImage")
            filter.setValue(CIColor(red: 0.5, green: 0.5, blue: 0.5), forKey: "inputColor")
            filter.setValue(1.0, forKey: "inputIntensity")
            return filter.outputImage!
        }
        return image
    }
}
