# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Getopt::EX::Hashed is a Perl module that automates hash object creation for storing command-line option values with Getopt::Long. It integrates option initialization, specification, and validation into a single declarative interface using the `has` function.

## Development Commands

### Testing
```bash
# Run all tests
prove -lvr t

# Run a single test file
prove -lv t/01_hashed.t

# Install dependencies
cpanm --installdeps --notest .
```

### Building
```bash
# Build the distribution (using Module::Build::Tiny)
perl Build.PL
./Build

# Create distribution tarball
minil dist
```

### Release
```bash
# Release to CPAN (includes building docs)
minil release
```

## Architecture

### Core Components

**lib/Getopt/EX/Hashed.pm** - The main module implementing:

1. **Metadata Storage System** (lines 53-61): Uses package-specific namespaces to store member definitions (`__Member__`) and configuration (`__Config__`) separately for each calling package, preventing collisions between different applications.

2. **`has` Function** (lines 128-149): Domain-specific language for declaring options with automatic spec compilation. Supports:
   - Option specifications with aliases
   - Default values and lazy evaluation via coderefs
   - Validation rules (must, min, max, any)
   - Custom actions via coderefs
   - Incremental updates with `+prefix`

3. **Dynamic Accessor Generation** (lines 227-243): Creates read-only or read-write (lvalue) accessor methods at object construction time. Accessors are automatically removed on object destruction to prevent conflicts.

4. **Option Spec Compilation** (lines 264-283): Transforms declarative syntax into Getopt::Long format:
   - Automatically generates dash variants for underscore names (controlled by REPLACE_UNDERSCORE/REMOVE_UNDERSCORE)
   - Merges option specs and aliases into pipe-delimited strings
   - Example: `has start => "=i s begin"` → `"start|s|begin=i"`

5. **Validation Framework** (lines 312-372): Composable validators that wrap option actions:
   - `min`/`max`: Numeric range validation
   - `must`: Custom code validators (supports arrays for multiple conditions)
   - `any`: String/regex pattern matching
   - Error messages generated via INVALID_MSG configuration

### Key Design Patterns

- **Package-Specific Metadata**: Each package that uses Getopt::EX::Hashed gets its own isolated namespace for storing declarations
- **Lazy Accessor Creation**: Accessors only created when `is => 'ro'` or `is => 'rw'` is specified
- **Hash Locking**: Uses Hash::Util to lock keys by default (LOCK_KEYS), preventing accidental access to non-existent members
- **Configuration Inheritance**: Class-level configure() settings are copied to each object instance

### Testing Strategy

Tests in `t/` directory follow a progression pattern:
- Basic functionality: 00-03
- Defaults and actions: 04-05
- Configuration: 06-07
- Validation: 08-09
- Edge cases: 10-15

Each test uses helper packages in `t/` directory (e.g., App::Foo) to simulate real-world usage patterns.

## Important Notes

- **Minimum Perl version**: v5.14.0
- **Dependencies**: List::Util (runtime), Getopt::Long (test only)
- **Build system**: Module::Build::Tiny via Minilla
- **CI**: GitHub Actions tests against Perl 5.14, 5.18, 5.28, 5.30, 5.38
- **Accessor caveat**: Problems may occur when multiple objects exist simultaneously, as accessors are stored in the package namespace
