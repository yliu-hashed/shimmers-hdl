# ``Shimmers/never(type:_:)``

## Overview

Just like the ``assert(_:type:_:)`` macro, the ``never(type:_:)`` macro is a assertion.

This macro turned into Swift's `fatalError()` during runtime.
This allows simulations to check that the code path can never be executed.
Similarly, during synthesis, Shimmers will attempt to prove it's never executed.
Synthesis will fail if it can.

For example, the following code for a simple ALU is not designed to execute a store instruction.
Thus, it must be ensured formally that any code that uses this ALU
must not give it load and store instructions.

```swift
func alu(opcode: Opcode, lhs: UInt8, rhs: UInt8) -> UInt8 {
    switch opcode {
    case .add:
        return lhs &+ rhs
    case .sub:
        return lhs &- rhs
    case .nand:
        return ~(lhs & rhs)
    case .xor:
        return lhs ^ rhs
    case .load, .store:
        #never
    }
}
```

You can optionally add a type and a message.

```swift
#never(type: "alu_usage", "ALU cannot be used for non-arithmetic instructions.")
```

> Note:
The default type of a ``never(type:_:)`` macro is ``AssertionType/never``.
