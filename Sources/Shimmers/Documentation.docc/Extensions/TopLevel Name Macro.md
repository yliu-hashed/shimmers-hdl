# ``Shimmers/topLevel(name:of:)``

## Overview

You can use this macro to refer to a function that was marked by the ``TopLevel(name:isSequential:)`` macro by using its name and its originating struct or enum.
You should use this macro directly with ``SynthDriver/enqueue(_:)`` of ``SynthDriver`` to add a job for synthesis.

```swift
@HardwareWire
struct Counter {
    @TopLevel(name: "counter", isSequential: true)
    mutating func increment() { ... }
}
```

```swift
await driver.enqueue(#topLevel(name: "counter", of: Counter.self))
```

If the method does not have an explicitly defined name, you should always refer to it by using the function name.

```swift
@HardwareWire
struct Counter {
    @TopLevel(isSequential: true)
    mutating func increment() { ... }
}
```

```swift
await driver.enqueue(#topLevel(name: "increment", of: Counter.self))
```

You can also refer to a global ``HardwareFunction()`` by only mentioning its name.

```swift
@HardwareFunction
func add(x: Int, y: Int) { ... }
```

```swift
await driver.enqueue(#topLevel(name: "add"))
```
