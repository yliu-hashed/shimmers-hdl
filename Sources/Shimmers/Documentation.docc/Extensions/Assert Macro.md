# ``Shimmers/assert(_:type:_:)``

## Overview

The ``assert(_:type:_:)`` macro is used to ensure a signal is valid (being always true).
During synthesis, Shimmers will attempt to prove its validity.
Synthesis will fail if this value is falsifiable.
Similarly, this macro turned into Swift's `precondition` during runtime.

### Typical Usages

Assertion is a way of **Formal Verification**.

For example, the following function models a counter.
It is not designed with `up` and `down` both enabled.
You can ensure the callers of this code will never run into this condition
by asserting that `up` and `down` are not both enabled.

```swift
mutating func cycle(up: Bool, down: Bool) -> UInt8 {
    #assert(!(up && down), "Only one of up or down can be enabled.")
    if up {
        value &+= 1
    } else if down {
        value &-= 1
    }
}
```

You can optionally add a type and a message.

```swift
#assert(type: "counter_usage", "Counter cannot count up and down at the same time.")
```
