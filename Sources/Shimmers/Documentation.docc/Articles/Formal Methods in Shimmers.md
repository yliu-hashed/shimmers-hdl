# Formal Methods in Shimmers

Take advantage of Shimmers' built-in formal tools to create verified hardware.

## Overview

Shimmers uses Formal methods to guarantee that the circuits you write are correct.
This can be done both implicitly and explicitly.

We will explore the built-in implicit assertions in Shimmers, creating custom formal points to reason about a design, and controlling proof effort by selectively disabling formal points. 

## Installing the Kissat Solver

Shimmers needs to use an external SAT solver to prove formal problems.
At this moment, only the [Kissat](https://github.com/arminbiere/kissat) solver is supported.
To install [Kissat](https://github.com/arminbiere/kissat), follow the instructions in their repo.

> Note:
In the future, Shimmers will support more solvers and may even have an in-house solver.
We are not affiliated with kissat.

To allow Shimmers to use the solver, first save the path of your Kissat binary,
and create a URL that points to the Kissat binary.

```swift
let kissatLoc = URL(filePath: "path to the kissat solver")
```

Then, pass in `kissatLoc` to the ``SynthOptions`` initializer,
and then use these options to initialize the driver.

```swift
let options = SynthOptions(kissatURL: kissatLoc)

let driver = SynthDriver(
    directory: workingDir,
    with: options
)
```

> Important:
Many key features of Shimmers, like loop unrolling, rely on the existence of Kissat.
Without Kissat, you will see this warning message:
"Solving skipped. Kissat binary not found."
This indicates that you have not provided a Kissat binary to the driver.

### Implicit Assertions

Shimmers honors the safety provided by Swift.
Since Shimmers aims to mirror the runtime behavior of Swift in hardware, it translates the safety features of Swift to formal proofs during hardware generation.

There are many places where Swift crashes at runtime, such as integer overflows.
For every place that Swift may terminate on an error, Shimmers will prove that the derived circuit can never encounter such an error.
These include, but are not limited to:

* Integer arithmetic overflow, underflow, and divide by zero
* Integer conversion overflow
* Array access out of bounds
* Force wrapping optionals

When generating designs in Shimmers, synthesis will only complete successfully if these operations are proven to be impossible.
For example, the following top-level code will fail to synthesize:

```swift
@HardwareFunction @TopLevel
func math(a: UInt8, b: UInt8) -> UInt8 {
    return a + b
}
```

This is because some combinations of input will cause the `a+b` to overflow.
However, the following code will synthesize without any errors:

```swift
@HardwareFunction @TopLevel
func math(a: UInt8, b: UInt8) -> UInt8 {
    return (a % 10) + (b % 10)
}
```

This is because the modulo limits the domain of addition below the overflow limit, and an unsigned modulo can never overflow on its own.

> Tip:
Sometimes, overflowing by wrapping is necessary.
You use Swift's wrapping operators like `&+` to perform wrapping arithmetic.
Doing this not only avoids overflow checks but also tells the readers of your source code that wrapping is the intended design.

## Explicit Formal Macros

Sometimes, you need to add custom assertions to ensure your design behaves as expected.
You can accomplish this by using three explicit formal macros.

### Assert Macro

The ``assert(_:type:_:)`` macro is used to ensure something is always true.
 
The addition of assertions ensures that the circuit is always correct by proving that a specific property of the circuit is always true.

For example, suppose a circuit controls a robot.
Its control system can command it to move left or right, but not both.
By adding an assertion, Shimmers can ensure that any caller cannot move the robot in both directions simultaneously.

```swift
@HardwareWire
struct Robot {
    ...
    mutating func move(left: Bool, right: Bool) {
        #assert(!(left && right), "Robot cannot move left and right at the same time.")
        ...
    }
    ...
}
```

```swift
robot.move(left: true, right: true)  // fail
robot.move(left: true, right: false) // pass
```

The checks are not limited to constants.
For example, the following usage of `move(left:right:)` will pass, because `left` and `right` are mutually exclusive by construction.

```swift
func control(robot: inout Robot, direction: Bool) {
    robot.move(left: direction, right: !direction)
}
```

### Never Macro

The ``never(type:_:)`` macro is an assertion on code paths.
It ensures that a code path can never be executed.

> Note:
`#assert(false)` and `#never` are equivalent.

This allows our robot example to be written with much cleaner logic.
We can just call `#never` when the situation is supposed to never happen.

```swift
@HardwareWire
struct Robot {
    ...
    mutating func move(left: Bool, right: Bool) {
        if left && right { #never }
        ...
    }
    ...
}
```

### Assume Macro

The ``assume(_:type:_:)`` macro is used to establish a premise. 
It assumes the condition is always true for later assertions.

```swift
@HardwareFunction @TopLevel
func work(x: Int8) {
    #assume(x > 3) // pass, plausable
    #assert(x > 3) // pass, always holds under assumption
}
```

For example, suppose we make a top-level function that takes the direction control as a knob.
The physical design of the knob ensures mutual exclusion, and passes the one-hot encoding into our design as the wires `knobLeft`, `knobRight`, and `knobIdle`.

```swift
@HardwareWire
struct Robot {
    ...
    @TopLevel(name: "operator_control_panel", isSequential: true)
    mutating func clock(knobLeft: Bool, knobRight: Bool, knobIdle: Bool) {
        #assume(!(knobLeft && knobRight))
        if !knobIdle {
            move(left: knobLeft, right: knobRight)
        }
    }
    ...
}
```

The `#assume` macro here is used to establish the mutually exclusive conditions manually.
Without this assumption, Shimmers will assume each boolean is a free variable, and the assertion in `move(left:right:)` will fail.

Note that Shimmers will prove that the premise is plausible and assume it's true for all later reasonings.
This means if the premise is impossible, Shimmers will still give an error.

For example, if `x>3` is assumed to be true, then `x<3` must be impossible, and cannot be assumed to be true.

```swift
@HardwareFunction @TopLevel
func work2(x: Int8) {
    #assume(x > 3) // pass, plausable
    #assume(x < 3) // fail, contradictory to x > 3
}
```

## Automatic Conditions

All the formal features in Shimmers are code-path dependent.
They are evaluated on the conditions of their current scopes.
For example, the following assertions will always pass:

```swift
if x > 4 {
    #assert(x > 3) // pass
}
```

This is because `x>4` implies `x>3`. When the `if` block executes, `x` must be bigger than 3.
It does not matter if `x` is never above 3. It just has to be above 3 if it is above 4.

---

Similarly, the following assertion will fail. 

```swift
if x > 4 {
    #assert(x < 7) // fail
}
```

This is because when `x>4` is true, `x<7` can be false (e.g., `x=8`).

These implicit control path conditions are also preserved between function calls.
If a function asserts a condition, but some other code calls this function in a way that violates that condition, synthesis will fail.
For example, the following `foo(_:)` will not pass synthesis:

```swift
func foo(_ x: UInt8) {
    bar(x % 3)
}

func bar(_ x: UInt8) {
    #assert(x >= 3)
}
```

This is because when `foo()` calls `bar()`, the argument `x` is smaller than 3,
which violates the assertion of `x>3`.

> Important:
The use of ``Detached()`` macro isolates the decorated function from the contexts of the rest of the synthesis.

## Loop Unrolling

In Shimmers, we allow loops on arbitrary conditions.
You can write a loop, and Shimmers will figure out how long to unroll the loop body.
This is done by unrolling one step at a time until the condition is unsatisfiable.
For example, the following codes compute the smallest multiple of the input that's above 10.

```swift
func compute(input: Int) -> Int {
    var value = input
    while value < 10 {
        value = value + input
    }
    return value
}
```

Suppose the supplied input is between 1 and 10, the loop is going to unroll 10 times, as on the 10th time, even the smallest input (of 1) can reach 10.
This feature gives designers the ability to express a circuit.

However, if the caller of this function has the possibility of supplying the value 0, then Shimmers will fail to unroll the loop after trying it for a long time.

---

Loop unrolling can sometimes take a large amount of computational power.
You can typically convert a `while` loop into a `for` loop with definitive bounds.
If you must unroll on a complex condition, you can manually restrict its domain by using the ``assert(_:type:_:)`` or the ``assume(_:type:_:)`` macro.

```swift
func compute(input: Int) -> Int {
    #assert(input > 0)
    var value = input
    while value < 10 {
        value = value + input
    }
    return value
}
```

This can reduce the search difficulty for the underlying SAT solver.
Furthermore, you can give loop hints in the form of a comment directly after the opening brace of the loop body.

```swift
//:HINT ITR (<min>,<max>)
```

For example, consider the following code that computes the first doubling of the input above 10.
Furthermore, suppose the usage of this function will only supply the input bigger than 3.

```swift
func compute(input: Int) -> Int {
    var value = input
    while value < 10 { //:HINT ITR (0, 2)
        value = value + input
    }
    return value
}
```

If you know the input is always bigger than 3, you will know that the loop never runs more than 2 times.
This is because for a minimum input of 4, unrolling 2 times gives 4+4+4=12, which is the first one above 10.
Then, you can add the hint of `(0,2)` to this loop.
This restricts Shimmers to only unroll at most 2 times.

Shimmers will still prove the condition on each of the 2 unrolls, as a caller may only use 0 or 1 unrolls.
If you are sure that all the users who use this loop will supply values that use all 2 iterations, you can use the condition `(2,2)`. This will force Shimmers to unroll the loop exactly 2 times. 

> Warning:
It is your responsibility to ensure that any usage of a hinted loop never exceeds the hinted upper bound.
An overrun of any hinted upper bound will cause undefined behavior.
For example, if you hint at 2 iterations, but supply 2 as the input to the generated circuit, you will incorrectly get 6 as the output.

## Skipping Formal

For all explicit formal macros, you can add a type and a message.
You can choose an existing type, like ``AssertionType/overflowMath``,
or use a custom type by initializing it with a string literal.

```swift
#assert(overflow, type: .overflowMath, "Division overflowed")
#assert(x <= 16, type: "oversize", "Too large to fit")
```

This allows any type of formal macros to be disabled during synthesis.
When constructing a ``SynthOptions``, provide a list of assertion types to be disabled.

```swift
let options = SynthOptions(
    kissatURL: kissatURL,
    disabledAssertions: [.bound, .overflowMath, "oversize"]
)
```

Then, during synthesis, these formals will be skipped.

> Warning:
Since Shimmers uses the RTL netlist during synthesis to perform on-the-fly Formal Verifications, the result of the formal should be correct.
However, please be aware that Shimmers is a new framework, and many parts are untested.
We are still working hard to make sure that Shimmers is fully correct. 
