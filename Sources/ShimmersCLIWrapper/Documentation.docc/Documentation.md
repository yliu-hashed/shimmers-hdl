# ``ShimmersCLIWrapper``

Wrap the hardware generation code using a universal command-line interface.

## Overview
  
Create a struct named `Command` to represent your custom command.
First, inherit the ``GeneratorsDriverCommand`` protocol. 
Then, implement the required static property ``GeneratorsDriverCommand/providingModules``, and enumerate all the top-level modules.
Finally, call the main function to run your command.

```swift
import Shimmers
import ShimmersCLIWrapper

struct Command: GeneratorsDriverCommand {
    static let providingModules: [Shimmers.TopLevelGenerator.Type] = [
        // enumerate all your targets here
        #topLevel(name: "counter", of: Counter.self),
        #topLevel(name: "cpu", of: BasicProcessor.self),
    ]
}
await Command.main()
```

You can then use this CLI as follows:

```
your-cli-name [--disable <assertions> ...] [--print-includes] [--kissat <kissat-path>] <path> <module-names> ...
```

Furthermore, you can use the `-h` flag to print the command help when you are unsure about the usage.
