# pearl-paren-style

Toggle Lisp paren style between compact and dangling layouts.

## Why Dangling Style for AI?

**Observation**: AI tools (Aider, Copilot) sometimes struggle with Lisp's dense `)))`.

**Hypothesis**: Separating closing parentheses onto their own lines might help by:
- Making each delimiter an atomic line for SEARCH/REPLACE
- Reducing the number of tokens the model must track on one line

**Status**: Unverified. No controlled experiments. Based on:
- General CS principle: explicit structure reduces ambiguity
- Anecdotal reports from early users (n=12)
- Sarwar et al. (2020): structural explicitness helps transformers on *unrelated tasks*

**Risk**: Zero. Fully reversible. Try it, see if it helps, ignore if not.

**Suggested Workflow**:

1. **Before AI coding**: Convert to dangling style (`M-x pearl-paren-style-dangling`)
2. **AI generation**: Let the AI work with separated delimiters
3. **After AI coding**: Convert back to compact style (`M-x pearl-paren-style-compact`) before committing

## Installation

### MELPA (Recommended)

Once available on MELPA:

```elisp
M-x package-install RET pearl-paren-style
```

### Manual

Clone and add to load path:

```elisp
(add-to-list 'load-path "/path/to/pearl-paren-style")
(require 'pearl-paren-style)
```

## Usage

### Core Commands

- `M-x pearl-paren-style-toggle`
  Auto-detect current style and toggle between compact and dangling styles.

- `M-x pearl-paren-style-compact`
  Force conversion to compact style (closing parentheses on same line as content).

- `M-x pearl-paren-style-dangling`
  Force conversion to dangling style (closing parentheses on separate lines, aligned with opening parentheses).
  When `pearl-paren-style-show-annotations` is enabled, closing parentheses display annotations showing the corresponding opening parenthesis location.

- `M-x pearl-paren-style-convert`
  Interactive prompt to choose specific style (compact or dangling).

### Region Operations

- `M-x pearl-paren-style-compact-region`
  Convert selected region to compact style.

- `M-x pearl-paren-style-dangling-region`
  Convert selected region to dangling style.

- `M-x pearl-paren-style-toggle-region`
  Toggle style in selected region based on automatic detection.

- `M-x pearl-paren-style-convert-region`
  Interactive prompt to choose style for selected region.

### File Operations

- `M-x pearl-paren-style-compact-files`
  Convert selected files or directories to compact style.
  When called interactively, prompts for files (wildcards allowed).
  In Dired mode, uses marked files.

- `M-x pearl-paren-style-dangling-files`
  Convert selected files or directories to dangling style.
  When called interactively, prompts for files (wildcards allowed).
  In Dired mode, uses marked files.

- `M-x pearl-paren-style-convert-files`
  Interactive prompt to choose style for selected files or directories.

### Annotation and Comment Conversion

- `M-x pearl-paren-style-annotations-to-comments`
  Convert all annotation overlays to permanent comment text.
  This creates comments that can be read by AI tools outside of Emacs sessions.

- `M-x pearl-paren-style-comments-to-annotations`
  Convert all annotation comments back to interactive overlay annotations.
  This restores the interactive display from permanent comments.

### Smart Do-What-I-Mean

- `M-x pearl-paren-style-dwim`
  Context-aware conversion:
  - Active region → convert region (prompts for style)
  - Dired with marked files → convert files (prompts for style)
  - Otherwise → toggle entire buffer style

### Testing

- `M-x pearl-paren-style-run-tests`
  Run the full test suite for pearl-paren-style.

## Examples

### Basic Conversion

```elisp
;; Before (compact style)
(defun example ()
  (let ((x 1))
    (when x
      (print x))))

;; After (dangling style)
(defun example ()
  (let ((x 1))
    (when x
      (print x)
    )
  )
)
```

### Annotation Display

When converting to dangling style with `pearl-paren-style-show-annotations` enabled,
closing parentheses display annotations showing the corresponding opening parenthesis:

```elisp
;; Before (compact style)
(defun example ()
  (let ((x 1))
    (when x
      (print x))))

;; After (dangling style with annotations)
(defun example ()
  (let ((x 1))
    (when x
      (print x)
    )         ← 3:4 (when x
  )           ← 1:2 (let ((x 1))
)             ← 0:0 (defun example ()
```

Annotations show:
- `← line:column (opening-text...)`
- Line and column numbers (1-based)
- First 20 characters of the opening line
- Color fades based on distance (closer = fainter, 20 lines = full color)

### Annotation to Comment Conversion

For permanent structural hints that persist across sessions and can be
read by AI tools, annotations can be converted to real comments:

```elisp
;; Convert annotations to comments
M-x pearl-paren-style-annotations-to-comments

;; Convert comments back to annotations
M-x pearl-paren-style-comments-to-annotations
```

Example conversion:

```elisp
;; Before (dangling style with annotations)
(defun example ()
  (let ((x 1))
    (when x
      (print x)
    )  ← 3:4 (when x
  )  ← 1:2 (let ((x 1))
)  ← 0:0 (defun example ()

;; After annotation-to-comment conversion
(defun example ()
  (let ((x 1))
    (when x
      (print x)
    )  ;; ← 3:4 (when x
  )  ;; ← 1:2 (let ((x 1))
)  ;; ← 0:0 (defun example ()
```

The comment prefix `;; ← ` is fixed as part of the internal protocol.

**Use Case**: When working with AI tools, converting annotations to
comments provides permanent structural hints that help the AI understand
Lisp nesting relationships, even outside of Emacs.

**Workflow Integration**:
1. Convert to dangling style with annotations (`M-x pearl-paren-style-dangling`)
2. Generate code with AI tools
3. Convert annotations to comments for permanent storage (`M-x pearl-paren-style-annotations-to-comments`)
4. Share code with others or commit to version control
5. When editing again, convert comments back to annotations for interactive editing (`M-x pearl-paren-style-comments-to-annotations`)

### Region Conversion Example

```elisp
;; Select this region and run M-x pearl-paren-style-dangling-region
(defun process (items)
  (mapcar (lambda (x)
            (when (valid-p x)
              (transform x))) items))

;; After region conversion to dangling style
(defun process (items)
  (mapcar (lambda (x)
            (when (valid-p x)
              (transform x)
            )         ; ← 3:4 (when (valid-p x)
          )           ; ← 2:2 (lambda (x)
        items)
)
```

### File Operations Example

1. Mark files in Dired mode
2. Run `M-x pearl-paren-style-dangling-files`
3. All marked .el files will be converted to dangling style
4. After AI editing, run `M-x pearl-paren-style-compact-files` to restore compact style

### Single-line Preservation

Single-line expressions remain unchanged in dangling style:

```elisp
;; Before and after (unchanged)
(mapcar #'process-item item-list)
(+ 1 2 3)
```

### Comment Handling

Comments are preserved during conversion:

```elisp
;; Before
(defun example ()
  (let ((x 1))        ; initialize
    (print x)))       ; output

;; After
(defun example ()
  (let ((x 1))        ; initialize
    (print x)         ; output
  )                   ; end let
)
```

### Annotation Configuration

```elisp
;; Enable/disable annotations (default: t)
(setq pearl-paren-style-show-annotations t)
```

Annotations inherit the current theme's comment face color. They fade based on
distance from the opening parenthesis (closer = fainter), reaching full color
at 20 lines of separation.

Note: The annotation comment prefix `;; ← ` is fixed as part of the internal
protocol and cannot be configured.

Annotations are created when converting to dangling style and removed when converting back to compact style.
They are not automatically updated during editing - use `M-x pearl-paren-style-dangling` to refresh them.

## Configuration

```elisp
;; Set default style when detection is ambiguous (default: 'compact)
(setq pearl-paren-style-default 'compact)

;; Enable/disable annotations in dangling style (default: t)
(setq pearl-paren-style-show-annotations t)
```

## Testing

Run the comprehensive test suite:

```elisp
M-x pearl-paren-style-run-tests
```

The test suite includes:
- Style detection and conversion
- Region and file operations
- Annotation and comment conversion
- Edge cases and error handling

Tests are designed to run within Emacs using ERT (Emacs Lisp Regression Testing).
The test suite reloads the source code and test files to ensure fresh execution.

## License

GPL v3 or later
