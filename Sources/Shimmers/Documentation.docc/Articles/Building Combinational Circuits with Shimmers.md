# Building Combinational Circuits with Shimmers

Learn about how to use functions in Swift to build combinational hardware.

## Overview

Shimmers is, first and foremost, a functional language.

Other HDLs like Verilog allow basic constructs like `wire` and `reg` to give designers the utmost freedom.
However, such freedom comes at a cost:
Circuits are defined structurally as a network without a clear indication of how values move and change.
For example, the definition of a variable is independent of where it's assigned.

Modern synthesis made this structural approach obsolete.
Downstream synthesizers and optimizers will rewrite logic beyond recognition.
They will find the best implementation for your function, regardless of its original structure.
Thus, it makes no sense to build circuits still structurally.

Shimmers emphasizes function over construction.
Instead of controlling how wires connect, you describe how values move and change using Shimmers.

We will explore hypothetical components of a simple processor and other examples to learn how combinational functions can be built.

## Pure Functions and Combinational Circuits

Intuitively, a pure function best represents a combinational cloud.
Naturally, the arguments of the function are inputs, and the return value of the function is the output.

> Note:
A pure function in programming languages refers to a function that has no states and side effects.
A pure function has the property that the same input always produces the same value.
All hardware in Shimmers is represented by functions.

An ALU is a perfect example of a pure function.
This ALU takes an opcode and two operands to perform an operation controlled by the opcode.

```swift
@HardwareFunction
func calculate(opcode: UIntN<6>, lhs: UInt32, rhs: UInt32) -> UInt32 {
    switch opcode {
    case 1:
        return lhs &+ rhs
    case 2:
        return lhs &- rhs
    case 3:
        return ~(lhs & rhs)
    case 4:
        return lhs | rhs
    ...
    }
}
```

### Other Pure Functions

Pure functions can be written in other forms.
For example, a method of a struct is a pure function. This is because a non-mutating function cannot change the struct.
When `self` is considered as an additional input, then it is just a regular pure function.

```swift
@HardwareWire
struct Instruction {
    var opcode: UIntN<6>
    var src1: UIntN<5>
    var src2: UIntN<5>

    func computeResult(with registers: Bus<16, UInt32>) -> UInt32 {
        switch opcode {
        case 1, 2, 3, 4:
            let v1 = registers[dst1]
            let v2 = registers[dst2]
            return calculate(opcode: opcode, lhs: v1, rhs: v2)
        ...
        }
    }
}
```

Similarly, a computed property is also a pure function, in that it takes `self` as the sole argument, and produces a value.

```swift
@HardwareWire
struct Instruction {
    var opcode: UIntN<6>
    var src1: UIntN<5>
    ...
    var isValid: Bool { opcode != 0 }
}
```

Lastly, an initializer is also a pure function that takes its argument as input and produces `self`.

```swift
@HardwareWire
struct Instruction {
    ...
    init(decoding raw: UInt32) {
        opcode = ...
        src1 = ...
        ...
    }
}
```

## Using Mutability

Shimmers relaxes the "pure" functional approach by allowing mutability.

The mutating function allows you to make a method that changes `self`.

```swift
@HardwareWire
struct Instruction {
    ...
    mutating func invalidate() {
        opcode = 0
        src1 = 0
        ...
    }
}
```

This function that modifies the `Instruction` is still pure if you consider `self` to be both an input and an output.
But you cannot mutate values on a whim: Mutable functions can only be called on a variable declared by a `var`.
You can use mutable variables declared by `var`.
This allows you to change them mid-function.

```swift
var inst: Instruction = ...
// any use of `inst` here gets the old value
inst.invalidate()
// any use of `inst` here gets the new value
```

This is useful for operations that require an intermediate value, such as counting something or finding the first instance of something.
For example, the following function counts the number of values that are above a given limit.

```swift
@HardwareFunction
func countOfLarge(_ values: Bus<16, UInt8>, limit: UInt8) -> UInt8 {
    var count: UInt8 = 0
    for i in values.indices {
        if values[i] > limit {
            count += 1
        }
    }
    return count
}
```

Lastly, the `inout` argument allows a function to change its inputs.
For example, the following `perform` function updates the `registers` supplied by an `inout` parameter.

```swift
@HardwareFunction
func perform(_ inst: Instruction, on registers: inout Bus<32, UInt32>) {
    let result = ...
    registers[inst.dst] = result // registers are changed here
}
```

When you call it, you must supply the registers using the `&` operator.
This visually signifies that the supplied `regFile` may be changed by the function.

```swift
@HardwareWire
struct Processor {
    var regFile: Bus<32, UInt32> = ...
    mutating func execute(_ inst: Instruction) {
        perform(inst, on: &regFile)
    }
}
```

> Warning:
Shimmers allows only local mutability for variables created within functions.
You cannot have a global variable, mutable or not.

## Control Flows

You already saw that Shimmers supports `if` and `for` statements.
We will talk about how to use other control flow statements to build hardware.

The `if` statement enables conditional execution in Swift, but in Shimmers, it is a way to multiplex results.
Shimmers also allow `guard` statements.
For example, we can use the `guard` statement to skip over processing instructions if a nop is found.

```swift
@HardwareWire
struct Processor {
    var regFile: Bus<32, UInt32> = ...
    mutating func execute(_ inst: Instruction) {
        guard inst.opcode != 0 else { return }
        perform(inst, on: &regFile)
    }
}
```

Shimmers allows loops on arbitrary conditions. The `while`, `repeat`, and `for` loops are supported.
This is done by unrolling the loop until the condition is proven to be always false.

For simple cases where the loop is over an array, the bound is trivial: just the length of the array.
But for complex cases, Shimmers will attempt to prove it formally.
For example, the following is a naive bubble sort in combinational circuits.
The sorter performs passes of pair-wise swaps until no swaps are done.

```swift
@HardwareFunction
static func bubbleSort(arr: Bus<8, Int8>) -> Bus<8, Int8> {
    var arr = arr
    while true {
        var changed: Bool = false
        for i in 0..<Int(count-1) {
            // swap if out of order
            if arr[i] > arr[i+1] {
                arr.swapAt(i, i+1)
                changed = true
            }
        }
        // stop if no change
        if !changed { break }
    }
    return arr
}
```

Shimmers will synthesize this function into a combinational circuit just fine.
Since there are 8 elements, and each pass restores at least 1 element, 7 passes can fully sort the array.
Thus, the `while` loop is going to be unrolled 7 times.

> Note:
Avoid putting complex conditions in `while` loops, as they take significant time to prove.
This feature uses the Formal capabilities in Shimmers.
You can read more about it in <doc:Formal-Methods-in-Shimmers>.

Most uses of `return`, `break`, and `continue` are supported.
For example, the following code counts over the number of even numbers before the first `0xFF`, but will always return `0` if any `0` is contained in the array.

```swift
@HardwareFunction
func goofyCount(_ values: Bus<16, UInt8>) -> UInt8 {
    var count: UInt8 = 0
    for value in values {
        guard value & 1 == 0 else { continue }
        if value != 0xFF { break }
        if value == 0 { return 0 }
        count += 1
    }
    return count
}
```

## See Also

- <doc:Building-Sequential-Circuits-with-Shimmers>
