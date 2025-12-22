# ``Shimmers/HardwareWire(flatten:)``

## Overview

This macro creates a Shimmers wire type in the image of the decorated struct or enum.
The attached data type will conform to ``Wire``.

> Important:
This macro will also convert any methods, computed properties, and initializers declared in the data type.
Do not attach another ``HardwareFunction()`` to each member.

For example, the following two data types can be used to describe the instructions of a simple ISA:

```swift
@HardwareWire
enum Opcode {
    case load, store
    case jump
    case add, sub
    ...
}

@HardwareWire
struct Instruction {
    var rb: UIntN<2>
    var ra: UIntN<2>
    var opcode: Opcode
}
```

### Bitwise Layout for Structs

When attached to a struct, the bit-level content of the represented wire is the concatenation of the contents of its data members arranged from LSB to MSB.
The size of such a struct wire is the sum of all its data members.

For example, the following struct has the following layout.

```swift
@HardwareWire
struct Foo {
    var a: UIntN<3>
    var b: Bool
    var c: UIntN<4>
}
```

![A bitfield diagram showing the field "a" occupying bits 0 to 2, field "b" occupying bit 3, and field "c" occupying bits 4 to 7.](field-struct)

### Bitwise Layout for Enums

When attached to an enum, the bit-level contents behave like a struct wire with two members: kind and payload.
The kind member behaves like an integer with the smallest number of bits that can represent the number of choices for the enum label.
The payload member behaves like a C-style union of the structs of all the associated types.

For example, the following enum has the following layouts depending on the case.

```swift
@HardwareWire
enum Bar {
    case a(x: UIntN<2>, y: UIntN<4>)
    case b(z: UIntN<5>)
    case c
}
```

![A bitfield diagram showing 3 vertically stacked bitfields. In all three bitfields, bits 0 to 1 are always the "kind" field, and bits 2 to 7 are always the payload field. The first row shows the enum case "a". The payload field occupies bits 0 to 1, the field "x" occupies bits 2 to 3, and the field "y" occupies bits 4 to 7. The second row shows the enum case "b". The payload field occupies bits 0 to 1, the field "z" occupies bits 2 to 6, and bit position 7 is unused. The third row shows the enum case "c". The payload field occupies bits 0 to 1, and bits 2 to 7 are unused.](field-enum)

### Additionals

You can optionally flatten any wire with the `type:` argument.
When flattened, a wire in a port is never expanded into its subfields.

```swift
@HardwareWire(flatten: true)
```

> Important:
This macro generates an additional struct as a peer of the attached struct.
The generated struct is named by adding the suffix `Ref` to the name of the attached struct.
Do not interact with structs with the `Ref` suffix directly.
