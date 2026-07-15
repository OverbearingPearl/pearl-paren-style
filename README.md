# pearl-paren-style

Toggle Lisp paren style between compact and dangling layouts.

## Motivation

This package solves a specific problem in **AI-assisted coding**: Large Language Models (LLMs) frequently struggle with properly balancing parentheses when generating compact Lisp code.

While the dangling paren style (where each closing parenthesis occupies its own line) is not the conventional Lisp community standard, it provides significant advantages for AI code generation:

- **Reduced syntax errors**: AI models are less likely to miss or misplace closing parentheses when each delimiter is isolated on its own line
- **Clearer structure**: Vertical alignment makes nesting levels and block boundaries visually explicit
- **Easier debugging**: Mismatched parentheses are immediately obvious when each has its own line
- **Better diffs**: Structural changes are clearer when delimiters are separated from content

**Recommended Workflow**:

1. **Before AI coding**: Convert your codebase to dangling style (`M-x pearl-paren-style-dangling`)
2. **AI generation**: Let the AI generate or modify code in this AI-friendly format
3. **After AI coding**: Convert back to compact style (`M-x pearl-paren-style-compact`) to match community standards before committing

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
