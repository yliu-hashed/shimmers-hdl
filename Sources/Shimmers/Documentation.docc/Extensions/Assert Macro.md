# ``Shimmers/assert(_:type:_:)``

## Overview

This macro turned into Swift's `precondition` during runtime.
This allows simulations to check that the argument is always true.
Similarly, during synthesis, Shimmers will attempt to prove it's always true.
Synthesis will fail if this value can be false.

This macro only requires a Boolean input as the asserted condition.

> Tip:
Assertions are a way of Formal Verification,
as it ensures that something must be true in the final design.

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
