# ``Shimmers/assume(_:type:_:)``

## Overview

Simulation runtime will check the argument is true just like ``assert(_:type:_:)``.
However, only the contradictions of this assumption is formally verified, not its truth.  

```swift
func foo(x: Int8) {
    #assume(x > 3) // allowed for synthesis even if `x > 3` may not be true
    #assert(x > 2) // this will pass, as if `x > 3` is true, so must `x > 2` 
}

func bar(x: Bool) {
    #assume(a < 2)
    #assume(a > 3) // failed due to contradiction
}
```

Assumptions are typically not needed as synthesis usually has full view of the entire circuit.
However, for top level port signals, or signals returned by detached modules,
the behavior of those signals are treated as fully free, in that it could be any value.
It is thus nessesary to ensure that the contract of those wires are never lost.

For example, the code below contains a loop determined by the input variable.
Suppose that the argument `x` is never negative actual usages of `foo`.
Without the assumption, the loop will unroll for 131 times, as the `x` could be at worst -128.
This will result in long synthesis times, and unnessesarly large circuits.
But by adding `#assume(x >= 0)`, the domain of `x` is recovered,
and the loop will only unroll 3 times.

```swift
@Detached
func foo(x: Int8) -> Int {
    #assume(x >= 0) // restrict domain of x
    var value = x
    var result = 2
    while value < 3 { // loop will only unroll for 3 times
        result *= 3
        value += 1
    }
    return result
}
```

> Note: 
In some scenerios, assumptions can reduce synthesis and subsequent formal effort,
since it restricts the problem domain.
