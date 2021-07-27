
import MachO.dyld

public extension CallStack.Frame {
  func addressForSymbolication(using symbolicator: Symbolicator) -> Address {
    var info = Dl_info()
    let result = dladdr(UnsafeRawPointer(bitPattern: instructionPointerValue), &info)
    precondition(result > 0)
    let image = symbolicator.images[String(cString: info.dli_fname)]!
    return .init(value: instructionPointerValue - image.slide)
  }
}

public struct Symbolicator {
  
  public init() {
    images = Dictionary(
      uniqueKeysWithValues:
        (0..<_dyld_image_count())
          .map {
            (
              String(cString: _dyld_get_image_name($0)),
              Image(slide: UInt(_dyld_get_image_vmaddr_slide($0)))
            )
          })
  }
  
  struct Image {
    let slide: UInt
  }
  fileprivate let images: [String: Image]
}
