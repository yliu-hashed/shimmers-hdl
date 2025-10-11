# Standard Wire Types

Construct hardware with standard types.

## Overview

Shimmers supports many Swift's ``Wire`` types.
You can compose new ``Wire`` types by using the ``HardwareWire(flatten:)`` macro on structs and enums like this:

```swift
@HardwareWire
struct Address {
    var base: UInt16
    var offset: IntN<7>
    var valid: Bool
}
```

Furthermore, you can bitwise cast any ``Wire`` type to other ``Wire`` types using ``Wire/as(_:)``.

```swift
let rawInstruction = memory[pc]
let instruction = rawInstruction.as(Instruction.self)
```

## Topics

### Wire Type

- ``Wire``

### Booleans

- ``Swift/Bool``
- ``Bit``
- ``Swift/Optional``

### Linear Collections

- ``Swift/InlineArray``
- ``Bus``
- ``Swift/IndexingIterator``

### Arbitrary-length Integers

Use Shimmers' custom integer types to represent integers of specific lengths.

- ``IntN``
- ``UIntN``

### Swift's Integers

Swift's built-in integer types are supported, 
but all of them have byte-based sizes.

- ``Swift/Int``
- ``Swift/Int8``
- ``Swift/Int16``
- ``Swift/Int32``
- ``Swift/Int64``
- ``Swift/UInt``
- ``Swift/UInt8``
- ``Swift/UInt16``
- ``Swift/UInt32``
- ``Swift/UInt64``
