# ``Shimmers``

Create complex digital hardware by writing regular Swift code.

## Overview

Shimmers (Synthesize Hardware In Modular Macro Expansions and Runtime in Swift) is a functional framework for creating circuits.
The principles behind Shimmers are to use functional code in Swift to describe hardware.
In other words, you specify what a circuit does, instead of what it looks like.
Shimmers allows you to describe the behavior of your circuit using regular Swift structs and functions.
Then, Shimmers macros turn them into hardware generators automatically.

Declaring a struct type that represents the latched values within a design.
Then, create a mutable driver function that changes the underlying value.
Decorate this function with Shimmers' ``TopLevel(name:isSequential:)`` Macro.

```swift
@HardwareWire
struct Counter {
    var count: UInt8 = 0

    @TopLevel(name: "counter", isSequential: true)
    mutating func clock(reset: Bool) -> UInt8 {
        let lastCount = count
        count = reset ? 0 : count &+ amount
        return lastCount
    }
}
```

This struct represents the behavior of a sequential circuit.
It is first and foremost regular Swift code, and thus simulating this hardware can be done trivially.

When you need to generate Verilog code, simply create a driver and run the generator:

```swift
let generatingDirectoryURL = URL(filePath: "target path of generate content")
let kissatURL = URL(filePath: "path to kissat solver")

let driver = SynthDriver(
    directory: generatingDirectoryURL,
    with: SynthOptions(kissatURL: kissatURL)
)

await driver.enqueue(#topLevel(name: "counter", of: Counter.self))
await driver.waitForAll()
let allMessages = await driver.messages
for message in allMessages {
    print(message)
}
```

This yields Verilog netlists that can be easily integrated into other toolchains.

> Warning:
Shimmers is new and untested.
**Do not use Shimmers for critical work!**
Contributions are welcome though.

## Topics

### Essentials

- <doc:Getting-Started-with-Shimmers>
- <doc:Building-Combinational-Circuits-with-Shimmers>
- <doc:Building-Sequential-Circuits-with-Shimmers>
- ``HardwareWire(flatten:)``
- ``HardwareFunction()``
- ``TopLevel(name:isSequential:)``

### Synthesizing Circuits

- <doc:Synthesis-Driver>
- <doc:Standard-Wire-Types>
- ``Detached()``

### Formal

- <doc:Formal-Methods-in-Shimmers>
- ``assert(_:type:_:)``
- ``assume(_:type:_:)``
- ``never(type:_:)``

### Simulating Circuits

- ``sim(_:)``

### Internal Symbols

Do not use!

- <doc:Internal-Shadows>
