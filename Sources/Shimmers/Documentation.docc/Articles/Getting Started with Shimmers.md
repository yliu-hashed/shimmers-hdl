# Getting Started with Shimmers

Learn to set up and generate a simple circuit with Shimmers.

## Overview

This guide walks through creating a simple circuit using Shimmers, simulating its behavior in Swift, and generating it into Verilog netlists.

We will be creating a simple combinational circuit that evaluates a majority voting condition.

## Adding Shimmers as a Dependency

Begin by creating a regular Swift Package. Add `Shimmers` as a dependency of our package,
and then include `Shimmers` as a dependency for our executable target.
Our "Package.swift" will look like this:

```swift
// swift-tools-version:6.2
let package = Package(
    name: "VoteCounter",
    dependencies: [
        .package(url: "https://github.com/yliu-hashed/shimmers-hdl.git")
    ],
    targets: [
        .executableTarget(
            name: "VoteCounter",
            dependencies: [
                .product(name: "Shimmers", package: "Shimmers")
            ]
        )
    ]
)
```

> Important:
Since `Shimmers` relies on macros, you should use the exact Swift version that Shimmers supports.

## Making a Wire Type

First, we need a custom ``Wire`` type to represent the vote condition.
The vote can **win** when the majority accepts, or **tie** when the number of people who accept and reject is the same.

We will define a Swift struct with the `win` and `tie` members,
then we'll add the ``HardwareWire(flatten:)`` macro to this struct.

```swift
import Shimmers

@HardwareWire
struct VoteResult {
    var win: Bool
    var tie: Bool
}
```

> Note:
This struct has a bit-level layout in hardware.
If `VoteResult` is in a ports, the order of the ports will match the order of the members.
If `VoteResult` is flattened, the order of the ports will be declared from LSB to MSB.

## Building Our First Circuit

Then, we need to describe the process of counting the votes.
This can be done by writing a static function that receives the votes and returns a `VoteResult`.

```swift
import Shimmers

@HardwareWire
struct VoteResult {
    var win: Bool
    var tie: Bool

    @TopLevel(name: "vote_counter")
    static func count(votes: Bus<4, Bool>) -> VoteResult {
        var acceptCount: Int = 0
        var rejectCount: Int = 0
        for i in votes.indices {
            if votes[i] {
                acceptCount += 1
            } else {
                rejectCount += 1
            }
        }
        return VoteResult(
            win: acceptCount > rejectCount,
            tie: acceptCount == rejectCount
        )
    }
}
```

Observe that this is just a regular Swift function.
This function counts the number of accepts and rejects by successive addition,
and compares the number of accepts and rejects to determine if the vote is **win** or **tie**.

> Note:
Everything should be active high.
A value of `true` means logic high.

> Experiment:
My counting function is inefficient. Can you think of a more clever way to rewrite this?

The ``Bus`` type is an alias of Swift's ``Swift/InlineArray``.
This is done to appeal to the hardware community. 
Similarly, ``Bit`` is an alias of ``Swift/Bool``, which is not used here. 

The ``TopLevel(name:isSequential:)`` is an attached macro that annotates that our `count(votes:)` function is the entry point of this design.
Everything in this function will be the content of the exported module.
This module will have a 10 bits of input for votes, and 2-bit outputs for the vote result. 

> Important:
Shimmers accepts most of Swift's way of coding as hardware constructions.
For example, the counting function can be rewritten as an initializer of `VoteResult`.
However, the top-level macro only accepts specific types of functions, which do not include initializers.
You can use custom initializers, but just cannot be top-level.

## Use the Driver to Generate Verilogs

The ``SynthDriver`` class is used to drive the generator.
In secret, the ``HardwareWire(flatten:)`` macro already expanded our design into generators.
We just need the ``SynthDriver`` to use them.

First, create a URL class that declares your desired path to store the Verilog files.
Then, create a default ``SynthOptions``.
Lastly, create an instance of ``SynthDriver``.
Since these are executable code, you should put them in an `async` function, or "main.swift".

```swift
let workingDir = URL(filePath: "target path of generate content")

let options = SynthOptions()

let driver = SynthDriver(
    directory: workingDir,
    with: options
)
```

Then, let's generate a Verilog module.
First, enqueue our top-level module as a job.
Refers to our top-level module using the ``topLevel(name:of:)`` expression macro.
Provide the **exact** name of the module, and the struct it's from.

```swift
await driver.enqueue(#topLevel(name: "vote_counter", of: VoteResult.self))
```

Then, wait for the synthesis to be done, and print out all the synthesis messages.

```swift
await driver.waitForAll()
let allMessages = await driver.messages
for message in allMessages {
    print(message)
}
```

Sometimes, synthesis will encounter errors and warnings.
Those anomalies (typically) will not cause the program to crash.
Instead, the messages are stored and can be queried.
This allows future complex tooling to be built on top.

> Warning:
You should always query messages even if synthesis appears to be completed successfully.
Shimmers improves performance by proving assertions (formal verifications) in separate threads from synthesis threads.
These assertions can complete even **after** the Verilog modules are written to disk.

The generated Verilog file will have the following shape:

```verilog
`ifndef __VOTE_US_COUNTER
`define __VOTE_US_COUNTER
`default_nettype none
module \vote_counter (
  input CLK,
  input            i_votes_0,
  input            i_votes_1,
  input            i_votes_2,
  input            i_votes_3,
  output           o_win,
  output           o_tie
  );
  // contents redacted
endmodule;
`endif // __VOTE_US_COUNTER
```

## Simulating the Design

The circuits you write in Shimmers are just some regular Swift code.
Simulating the circuit is just about the code you already wrote.

For example, you can create a unit test by using [Swift Testing](https://github.com/swiftlang/swift-testing).
But in here, I will show you a dumb way of testing your code: just run it in "main.swift". First, comment out all the driver code in the last section.
Then, add the following:

```swift
let result1 = VoteResult.count(votes: [true, false, true, false])
print(result1) // prints: Result(win: false, tie: true)

let result2 = VoteResult.count(votes: [false, true, true, true])
print(result2) // prints: Result(win: true, tie: false)

let result3 = VoteResult.count(votes: [false, false, false, true])
print(result3) // prints: Result(win: false, tie: false)
```

In [Swift Testing](https://github.com/swiftlang/swift-testing), a test case would look like this:

```swift
@Test func test1() {
    let result = VoteResult.count(votes: [true, false, true, false])
    #expect(result.win == false)
    #expect(result.tie == true)
}
```

That's all about it. Swift is a compiled language, and thus simulating like this should be swift (pun).
Furthermore, it's right to feel that the simulation is trivial.
By writing Swift code, you can more easily reason about its behavior,
which makes writing correct hardware much easier.

> Tip:
Swift has a good debug infrastructure.
If you use a competent IDE for Swift, you can get code stepping and variable inspection.
This power is lacking in Hardware design, but Shimmers gets it for free, as your design is just regular Swift.

> Warning:
At this moment, simulating by just running your Swift code **does not** replace functional RTL-level simulation.
Shimmers is new, and the generated hardware could be wrong.
We are still working hard to make sure that Shimmers is fully correct. 

## See Also

- <doc:Building-Combinational-Circuits-with-Shimmers>
- <doc:Building-Sequential-Circuits-with-Shimmers>
