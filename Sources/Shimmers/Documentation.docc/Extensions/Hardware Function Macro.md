# ``Shimmers/HardwareFunction()``

## Overview

This macro makes a global function usable in Shimmers.
It creates a Shimmers generator in the image of the decorated global function.

> Important:
This macro can only be used on global functions.

For example, the following function can be used in Shimmers to calculate the parity of a byte:

```swift
@HardwareFunction
func parity(of value: UInt8) -> Bool {
    var parity: Bool = false
    for i in 0..<value.bitWidth {
        parity ^= value.bit(at: i)
    }
    return parity
}
```
