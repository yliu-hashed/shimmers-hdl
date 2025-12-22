# Internal Shadows

Shimmers shadow of Swift symbols.

## Overview

Every ``Wire`` type has a shadow in the form of ``WireRef``. The ``Wire`` conforming types are for simulation in regular Swift. The ``WireRef`` conforming types are shadow structs of their non-Ref counterpart that generate the respective hardware.

You can use this page as a list of supported features in Swift that Shimmers can synthesize.

> Warning:
The ``HardwareWire(flatten:)`` macro generates wire references with the `Ref` suffix. **Do not use these types directly.**

## Topics

### Common

- ``WireRef``
- ``TopLevelGenerator``

### Arbitrary Length Integers Mirrors

- ``IntNRef``
- ``UIntNRef``

### Swift Integer Mirrors

- ``IntRef``
- ``Int8Ref``
- ``Int16Ref``
- ``Int32Ref``
- ``Int64Ref``
- ``UIntRef``
- ``UInt8Ref``
- ``UInt16Ref``
- ``UInt32Ref``
- ``UInt64Ref``

### Boolean Mirrors

- ``BoolRef``
- ``BitRef``

### Range

- ``RangeRef``

### Optionals

- ``OptionalRef``

### Inline Array

- ``InlineArrayRef``
- ``BusRef``
- ``InlineArrayIteratorRef``

### Iterators

- ``IndexingIteratorRef``

### Queue

- ``QueueRef``

### Swift Protocol Mirrors

- ``AdditiveArithmeticRef``
- ``BinaryIntegerRef``
- ``CollectionRef``
- ``ComparableRef``
- ``EquatableRef``
- ``FixedWidthIntegerRef``
- ``IteratorProtocolRef``
- ``NumericRef``
- ``RangeExpressionRef``
- ``SequenceRef``
- ``SignedNumericRef``
- ``SignedIntegerRef``
- ``StrideableRef``
- ``UnsignedIntegerRef``

- ``abs(_:)``
- ``><?><(_:_:)``
- ``><|><(_:_:)``
- ``..<(_:_:)``
