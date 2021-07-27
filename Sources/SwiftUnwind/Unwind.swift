
import CLibUnwind
import Darwin
import MachO.dyld

public struct CallStack: Sequence {
  
  public init() {
    var context = unw_context_t()
    let result = unw_getcontext(&context)
    precondition(result == 0)
    self.context = context
  }
  private var context: unw_context_t
  
  public struct Frame {
    public struct Address: CustomStringConvertible {
      let value: UInt
      
      public var description: String {
        let unpadded = String(value, radix: 16)
        precondition(unpadded.count <= 16)
        return "0x\(String(repeating: "0", count: 16 - unpadded.count))\(unpadded)"
      }
    }
    
    /**
     - note: The instruction pointer sometimes referred to as the program counter
     */
    public var instructionPointerValue: UInt {
      var word = unw_word_t()
      /// The following operation should not modify the cursor
      var cursor = self.cursor
      let result = unw_get_reg(&cursor, unw_regnum_t(UNW_REG_IP), &word)
      precondition(result == 0)
      return UInt(word)
    }
    fileprivate let cursor: unw_cursor_t
    
    public var nameAndOffset: (name: String, offset: UInt) {
      /// This following operation should not modify the cursor
      var cursor = self.cursor
      var offset = unw_word_t()
      let name = String(
        unsafeUninitializedCapacity: 1 << 10,
        initializingUTF8With: { buffer in
          buffer.withMemoryRebound(to: Int8.self) { buffer in
            let result = unw_get_proc_name(&cursor, buffer.baseAddress, buffer.count, &offset)
            switch Int(result) {
            case 0:
              break
            case UNW_ENOINFO:
              fatalError()
            case UNW_ENOMEM:
              fatalError()
            case UNW_EUNSPEC:
              fallthrough
            default:
              fatalError()
            }
            return strnlen(buffer.baseAddress!, buffer.count)
          }
        })
      return (name, UInt(offset))
    }
  }
  
  public func makeIterator() -> Iterator {
    var cursor = unw_cursor_t()
    /// The following operation should not modify the context
    var context = self.context
    let result = unw_init_local(&cursor, &context)
    precondition(result == 0)
    return Iterator(cursor: cursor)
  }
  public struct Iterator: IteratorProtocol {
    public mutating func next() -> Frame? {
      guard !isAtEnd else { return nil }
      
      let result = unw_step(&cursor)
      if result < 0 {
        fatalError()
      } else {
        isAtEnd = result == 0
      }
      return Frame(cursor: cursor)
    }
    
    var isAtEnd: Bool = false
    var cursor: unw_cursor_t
  }
}
