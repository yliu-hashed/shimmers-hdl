# Synthesis Driver

Synthesize a top-level module with ``SynthDriver``.

## Overview

To generate Verilog netlists of designs in Shimmers,
create URLs of the generating path and the kissat solver.
Then, create a ``SynthOptions`` with the kissat URL,
and create an instance of ``SynthDriver``.

```swift
import Shimmers

let workingDir = URL(filePath: "target path of generate content")
let kissatLoc = URL(filePath: "path to the kissat solver")

let options = SynthOptions(kissatURL: kissatLoc)

let driver = SynthDriver(
    directory: workingDir,
    with: options
)
```

Then, use the ``topLevel(name:of:)`` macro to refer to the top-level generator, and enqueue it to be generated.
Make sure to use the **exact** name of the module, and the struct it's from.

```swift
await driver.enqueue(#topLevel(name: "vote_counter", of: VoteResult.self))
```

Then, wait for synthesis to be done, and print out all the ``SynthMessage``'s.

```swift
await driver.waitForAll()
let allMessages = await driver.messages
for message in allMessages {
    print(message)
}
```

> Tip:
You can enqueue multiple modules at a time, then wait for all of them to finish.

## Topics

### Generator Driver

- ``SynthDriver``
- ``topLevel(name:of:)``

### Warning and Errors

- ``SynthMessage``
- ``DebugLocation``
- ``DebugFrame``

### Control Synthesis

- ``SynthOptions``
- ``AssertionType``
- ``AssertionSet``
