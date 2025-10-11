# Building Sequential Circuits with Shimmers

Learn how to use mutable functions in Swift to build sequential hardware.

## Overview

Learn about the unique ways Shimmers handles sequential circuits.
We begin by building a simple state machine to get a hang of `mutable` functions.
Then, we move on to common patterns, like pipelines, pipeline stalls, and value forwarding.

## Mutable Function

Shimmers can't build flip-flops explicitly, since it goes against our design philosophy.
Allowing the insertion of flip-flops anywhere in a function breaks the illusion that circuits are "functions".

Instead, we begin with the fundamental observation that all sequential circuits can be described by combinational circuits that describe how values change.
In other words, a sequential circuit is just a `struct` with a `mutating` function.
This allows us to describe a circuit fully on what it does, instead of what it looks like.

The following is a counter that just counts up and wraps back around due to overflow.

```swift
@HardwareWire
struct Counter {
    var count: UInt8 = 0

    @TopLevel(name: "counter", isSequential: true)
    mutating func clock() -> UInt8 {
        count &+= 1
        return count
    }
}
```

The `count` variable is the state, and the `clock()` function changes the state.
This should feel like writing `always` blocks in Verilog and writing `process` blocks in VHDL.

![](fsm-1.png)

> Note:
Notice that there is no "non-blocking" assignment.
All assignments in SHDL are blocking in that the value you use is the value modified earlier.
Thus, the return value is the incremented value.

The ``TopLevel(name:isSequential:)`` macro marks the top-level function to be generated with a sequential wrapper.
There is nothing different between a combinational mutable function and a sequential one other than how Shimmers generates the output netlist.

## State Machine

A state machine can be built in the same way as those in other HDLs.
Simply store some state variable, and use it each cycle.
For example, the following state machine detects if a signal is kept enabled for at least 10 cycles.

```swift
@HardwareWire
struct StateMachine {
    var count: UIntN<4> = 0

    @TopLevel(name: "fsm", isSequential: true)
    mutating func clock(enable: Bool) -> Bool {
        let result = count == 10
        if enable {
            count = min(10, count + 1)
        } else {
            count = 0
        }
        return result
    }
}
```

![](fsm-2.png)

> Tip:
You can also use enums to create discrete states.
Learn more about it in ``HardwareWire(flatten:)``.

## Pipelining

Pipelining in Shimmers will feel unnatural at first because hardware designers are used to using non-blocking assignments to move data between pipelines.
In Shimmers, pipelining is done by moving pipeline data from one stage to the next manually.
The code below calculates y=x\*5/2.

![](pipe-1.png)

```swift
@HardwareWire
struct Pipeline {
    var buf1: UInt8 = 0
    var buf2: UInt8 = 0
    var buf3: UInt8 = 0

    @TopLevel(name: "pipe", isSequential: true)
    mutating func clock(input: UInt8) -> UInt8 {
        let result = buf3
        buf3 = buf2 / 3 
        buf2 = buf1 * 5
        buf1 = input
        return result
    }
}
```

> Tip:
Observe that the pipeline is best advanced in reverse.
This allows one stage to use the buffered result before the previous stage overwrites it.
Advancing the pipeline from the front can also work, but it requires using temporary variables to hold the buffered results.

For more complicated pipelines, structs can be used to separate the behavior of each stage.
Each struct will contain each pipeline buffer and a method to advance the pipeline into the next buffer.

```swift
@HardwareWire
struct Buffer1 {
    var data: UInt8
    ...
    mutating func advance(to nextBuffer: inout Buffer2) {
        nextBuffer.data = data * 5 
    }
}
```

A main mutating function on a main struct can be created to orchestrate the pipeline as a whole.
This allows for better abstraction and separation of behavior.

```swift
@HardwareWire
struct Pipeline {
    var buf1 = Buffer1()
    var buf2 = Buffer2()
    var buf3 = Buffer3()

    @TopLevel(name: "pipe", isSequential: true)
    mutating func clock(input: UInt8) -> UInt8 {
        let result = buf3.getResult()
        buf2.advance(to: &buf3)
        buf1.advance(to: &buf2)
        buf1.set(input)
        return result
    }
}
```

### Pipeline Stall

Most of the time, the pipeline isn't perfect.
To handle pipeline stalls, simply stop moving the earlier stages when a later stage stalls.
For example, if buf2 cannot advance into buf3, simply return early.
The `advance(to:)` function of buf2 is assumed to be modified to return a boolean representing whether the operation is completed (did not stall).

```swift
@TopLevel(name: "pipe", isSequential: true)
mutating func clock(input: UInt8) -> UInt8 {
    let result = buf3.getResult()
    let noStall = buf2.advance(to: &buf3)
    guard noStall else { return result }
    buf1.advance(to: &buf2)
    buf1.set(input)
    return result
}
```

The `advance(to:)` function of buf2 needs to be designed such that it informs `buf3` of itself stalling.
The internals of buf3 must also be able to represent invalid data (pipeline bubble).
For example, buf3 can be changed to hold an `Optional` type.

```swift
@HardwareWire
struct Buffer3 {
    var data: UInt8?
    ...
}
```

Then, buf2 can be modified to move data to buf3 if it can, and write `nil` to buf3 if it cannot.

```swift
@HardwareWire
struct Buffer2 {
    var data: UInt8
    ...
    mutating func advance(to nextBuffer: inout Buffer3) -> Bool {
        let stalled = ...
        if stalled { // stall condition
            nextBuffer.data = nil
            return false
        }
        // normal condition
        nextBuffer.data = ... // normal data
        return true
    }
}
```

Cascading guard and return statements can be built to handle multiple stall conditions.
For example, every stage can be made to stall.

```swift
@TopLevel(name: "pipe", isSequential: true)
mutating func clock(input: UInt8) -> UInt8 {
    let result = buf3.getResult()
    guard buf2.advance(to: &buf3) else { return result }
    guard buf1.advance(to: &buf2) else { return result }
    guard buf1.set(input) else { return result }
    return result
}
```

> Important:
In the example, when stalling happens, the input value is dropped.
Typically, an input drop needs to be communicated to the rest of the design.
This is typically done by adding a Boolean return value as "acknowledgment".
If the pipeline is designed to drop some input, it is essential to inform the user of your design that the input will be dropped.

### Value Forwarding

Value forwarding can be handled by keeping the value of later stages around after advancement is done.
For example, suppose now buf1's `advance(to:)` method needs a value from buf1's `advance(to:)` method.
The buf1's advance function can just return the forward value, and buf2's advance function can take the value as an additional argument.

```swift
@TopLevel(name: "pipe", isSequential: true)
mutating func clock(input: UInt8) -> UInt8 {
    let result = buf3.getResult()
    let forwardValue = buf2.advance(to: &buf3)
    buf1.advance(to: &buf2, with: forwardValue)
    buf1.set(input) 
    return result
}
```

> Note:
Forwarding from an earlier to a later stage can be done too. There are two ways to do it.
First, you can advance the pipeline front to back instead of back to front.
This requires you to hold temporary values of pipeline buffers.
Second, you can split the forwarder's stage into two functions, one that runs early to just compute the forwarding value, and one to advance the pipeline normally.
