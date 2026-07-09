;;; pearl-paren-style.el --- Toggle Lisp paren style  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: lisp, tools, convenience
;; URL: https://github.com/OverbearingPearl/pearl-paren-style

;;; Commentary:

;; Toggle between compact and dangling paren styles.
;; M-x pearl-paren-style-toggle

;;; Code:

(require 'cl-lib)

(defgroup pearl-paren-style nil
  "Toggle Lisp paren style."
  :group 'lisp)

(defcustom pearl-paren-style-default 'compact
  "Default style when detection is ambiguous."
  :type '(choice (const compact) (const dangling)))

(defun pearl-paren-style--in-string-or-comment-p ()
  "Return non-nil if point is inside a string or comment."
  (let ((syn (syntax-ppss)))
    (or (nth 3 syn) (nth 4 syn))))

(defun pearl-paren-style--detect ()
  "Return current style: `compact', `dangling', or nil."
  (save-excursion
    (goto-char (point-min))
    (let ((compact 0) (dangling 0))
      (while (search-forward ")" nil t)
        (unless (pearl-paren-style--in-string-or-comment-p)
          (backward-char)
          (let ((open-pos (nth 1 (syntax-ppss))))
            ;; Only count multi-line parens
            (when (and open-pos (/= (line-number-at-pos open-pos) (line-number-at-pos)))
              (if (looking-back "^\\s-*" (line-beginning-position))
                  (cl-incf dangling)
                (cl-incf compact))))
          (forward-char)))
      (cond ((>= dangling compact) 'dangling)
            ((>= compact dangling) 'compact)))))

(defun pearl-paren-style--to-dangling ()
  "Convert buffer to dangling style.
Single-line parens like (foo) remain unchanged."
  (save-excursion
    (goto-char (point-min))
    (while (search-forward ")" nil t)
      (unless (pearl-paren-style--in-string-or-comment-p)
        (backward-char)
        ;; Skip if already on its own line
        (unless (looking-back "^\\s-*" (line-beginning-position))
          ;; Use syntax-ppss instead of backward-list to avoid scan-error
          (let ((open-pos (nth 1 (syntax-ppss))))
            ;; Only convert if opening paren is on a different line
            (when (and open-pos (/= (line-number-at-pos open-pos) (line-number-at-pos)))
              (let ((col (save-excursion (goto-char open-pos) (current-column))))
                (insert "\n")
                (indent-to col)))))
        (forward-char)))))

(defun pearl-paren-style--to-compact ()
  "Convert buffer to compact style."
  (save-excursion
    (goto-char (point-min))
    (while (search-forward ")" nil t)
      (unless (pearl-paren-style--in-string-or-comment-p)
        (backward-char)
        ;; Check if ) is at the beginning of a line (after optional whitespace)
        (let ((line-start (line-beginning-position)))
          (when (and (>= (point) line-start)
                     (looking-back "^\\s-*" line-start))
            ;; Delete from end of previous line to current position
            (delete-region (1- line-start) (point))))
        (forward-char)))))

;;;###autoload
(defun pearl-paren-style-toggle ()
  "Toggle paren style between compact and dangling."
  (interactive)
  (pcase (pearl-paren-style--detect)
    ('compact (pearl-paren-style--to-dangling))
    ('dangling (pearl-paren-style--to-compact))
    (_ (message "Unknown style, no toggle performed"))))

;;;###autoload
(defun pearl-paren-style-compact ()
  "Convert to compact style (closing parens on same line)."
  (interactive)
  (pearl-paren-style--to-compact)
  (message "Converted to compact style"))

;;;###autoload
(defun pearl-paren-style-dangling ()
  "Convert to dangling style (closing parens on separate lines)."
  (interactive)
  (pearl-paren-style--to-dangling)
  (message "Converted to dangling style"))

;;;###autoload
(defun pearl-paren-style-convert (style)
  "Convert to STYLE ('compact or 'dangling)."
  (interactive
   (list (intern (completing-read "Convert to: " '("compact" "dangling") nil t))))
  (pcase style
    ('compact (pearl-paren-style--to-compact))
    ('dangling (pearl-paren-style--to-dangling))
    (_ (user-error "Unknown style: %s" style))))

;;;###autoload
(defun pearl-paren-style-run-tests ()
  "Run all tests for pearl-paren-style."
  (interactive)
  (require 'ert)
  (ert-delete-all-tests)
  (let* ((this-file (symbol-file 'pearl-paren-style-run-tests))
         (dir (file-name-directory this-file)))
    ;; Unload old code
    (when (featurep 'pearl-paren-style)
      (unload-feature 'pearl-paren-style t))
    ;; Reload source files (force load .el, ignore .elc)
    (load (expand-file-name "pearl-paren-style" dir) nil t)
    ;; Load test files
    (load (expand-file-name "test-pearl-paren-style" dir) nil t))
  (ert t))

(provide 'pearl-paren-style)
;;; pearl-paren-style.el ends here
