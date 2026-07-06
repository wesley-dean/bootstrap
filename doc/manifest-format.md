# Package Manifest Format

The bootstrap package manifest is a plain UTF-8 text file that describes
package requirements.  It is intentionally small so that a manifest can be
read, reviewed, and maintained without learning a large configuration
language.

Each logical line contains at most one package requirement.  Blank lines
are ignored.  Lines whose first non-whitespace character is `#` are
comments.  Inline comments begin with `#` and are removed before parsing.

Supported requirement forms are:

```text
git
openssl >= 3.0
foo == 1.2.3
bar = 2.0
baz > 1.0
```

Whitespace around package names and operators is ignored.  The parser
normalizes requirements into Manifest Entry records containing:

```text
package|operator|version|source|line_number
```

For package-only requirements, the operator and version fields are empty.
The source and line-number fields preserve provenance so later dry-run and
explain output can identify the manifest line that produced each planned
action.

The parser validates manifest syntax only.  It does not check whether a
package exists, compare versions, plan installations, or call a package
manager.

During resolution, backend-specific package checks decide whether a planned
package can be satisfied by the selected package manager.  For APT, package
existence means the package is known to configured APT metadata, and version
constraints are compared against the APT candidate version using native Debian
package comparison semantics.
