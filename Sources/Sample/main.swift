
import SwiftUnwind

struct Foo { }

let symbolicator = Symbolicator()

func + (lhs: Foo, rhs: Foo) {
  var stack = CallStack().makeIterator()
  let _ = stack.next() /// This frame
  let caller = stack.next()!
  print("""
    dsymutil "\(CommandLine.arguments[0])"
    dwarfdump --lookup=\(caller.addressForSymbolication(using: symbolicator)) <path-to-dSYM>
    """)
}

Foo() + Foo()
