# Firmware Skeleton v0.1

# Firmware Repository Outline

Source code should be kept in a general outline. *STM32CubeMX projects should be generated with "Advanced" Application Structure*. This allows any testing and Documentation to be kept seperate. 

```bash
Core/								// Contains all source code
├── Inc						// Any generated header files
│   ├── App					// User Header Files
│   │   └── SerialComms.h
│   └── main.h
├── Lib						// User Libraries (such as any peripherals)
│   └── ILI9341
│       ├── ili9341.c
│       └── ili9341.h
└── Src						// Ay generated source code files
    ├── App					// User Source Files
    │   └── SerialComms.c
    └── main.c
```

## Git

Git should be used. "Commit early, commit often". Each commit should contain a packet of work to allow cherry-picking for any parallel branches. Check out https://learngitbranching.js.org/ for a great git tutorial.

### Branching Strategy

Default branch should be named "main". Most changes should be made to the "develop(ment)" branch. See below for the branching strategy used. See (https://nvie.com/posts/a-successful-git-branching-model/) for more information on this strategy.  

![img](https://nvie.com/img/git-model@2x.png)

### .gitignore

The default `.gitignore` file is included in this repository. Add to it to any new projects.

### Sub Modules

Use of sub modules is up to the developer. They can make sharing components/libraries between projects much easer. However cloning git repos becomes more complex, and branching without the submodule can cause headaches.

## Development

Recommendation is to develop with Visual Studio Code. Most embedded toolchains include support for makefiles. 



## Unit Testing

Testing is done with the [Ceedling tool suite](http://www.throwtheswitch.org/#download-section) (Unity, CMock, Ceedling). Any firmware development should be completed using Test Driven Development guidelines outlined in [Test Driven Development for Embedded C](https://pragprog.com/titles/jgade/test-driven-development-for-embedded-c/). 

100% Line Coverage and 100% Branch Coverage should be achieved for each module tested where possible.

References for each tool can be found at the [Throw The Switch GitHub page](https://github.com/ThrowTheSwitch).

### Create Modules

```ruby
ceedling module:new[ili9341]
```

Creates a new module in the `test` folder, and generates a source and header file into the Src and Inc directories. Change if using a library.

### Testing Modules

```ruby
ceedling test:[ili9341]
```

### Coverage report

```
ceedling gcov:ili9341 utils:gcov
```

Generates a gcov test report. Report can then be found in `build/artifacts/gcov/GcovCoverageResults.html`. 

### Build Errors

Build errors are common due to Embedded systems HALs. If `stm32_hal_i2c.h` is not being included in the build, add `#include "stm32_hal_i2c.h"` to the test file. 

If the included HAL file is pulling other HALs which cause errors (such as hard-coded asm code), mock the file `#include "mock_stm32_hal_i2c.h"`.

If a deep dependency is failing to build and needs modifying, make a copy and move to `test/support` directory, the build will include this file instead.

