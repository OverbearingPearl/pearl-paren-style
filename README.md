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

### Commands

- `M-x pearl-paren-style-toggle`
  Toggle current buffer between compact and dangling styles based on automatic detection

- `M-x pearl-paren-style-compact`
  Force conversion to compact style (closing parens on same line as content)

- `M-x pearl-paren-style-dangling`
  Force conversion to dangling style (closing parens on separate lines, aligned with opening parens)

- `M-x pearl-paren-style-convert`
  Interactive prompt to choose specific style (compact or dangling)

### Region and File Operations

Add `-region` suffix for region operations (e.g., `pearl-paren-style-compact-region`).

Add `-files` suffix for file operations (e.g., `pearl-paren-style-dangling-files`).

### Smart Do-What-I-Mean

- `M-x pearl-paren-style-dwim`
  Context-aware conversion:
  - Active region → convert region
  - Dired with marked files → convert files
  - Otherwise → toggle entire buffer

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

;; Set annotation update delay (default: 0.1 seconds)
(setq pearl-paren-style-annotation-delay 0.1)
```

Annotations automatically update after buffer changes with a debounced delay
to maintain performance during editing.

## Configuration

```elisp
;; Set default style when detection is ambiguous (default: 'compact)
(setq pearl-paren-style-default 'compact)
```

## Testing

Run the test suite:

```elisp
M-x pearl-paren-style-run-tests
```

## License

GPL v3 or later
