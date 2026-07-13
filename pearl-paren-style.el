;;; pearl-paren-style.el --- Toggle Lisp paren style  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.6
;; Package-Requires: ((emacs "24.4"))
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
  (or (nth 8 (syntax-ppss))  ; inside comment or string
      (save-excursion
        (let ((pos (point)))
          (when (re-search-backward "#|" nil t)
            (let ((start (point)))
              (goto-char start)
              (when (re-search-forward "|#" nil t)
                (<= pos (point)))))))))

(defun pearl-paren-style--line-has-comment-p ()
  "Return non-nil if current line has a comment (starting with ;)."
  (save-excursion
    (beginning-of-line)
    (let ((line-end (line-end-position)))
      (when (search-forward ";" line-end t)
        ;; Verify it's really a comment, not inside string or character literal
        (nth 4 (syntax-ppss))  ; returns non-nil if in comment
        ))))

(defun pearl-paren-style--line-has-code-p ()
  "Return non-nil if current line has actual code (not just parens and whitespace)."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (while (and (not (eolp))
                (or (= (char-after) ?\()
                    (= (char-after) ?\))))
      (forward-char)
      (skip-chars-forward " \t"))
    (not (eolp))))

(defun pearl-paren-style--calculate-compact-indent (pos)
  "Calculate proper indentation for line at POS in compact style.
Uses `calculate-lisp-indent' to determine the correct indentation
column for the current line, based on Lisp syntax."
  (condition-case err
      (save-excursion
        (goto-char pos)
        (beginning-of-line)
        (let ((indent (calculate-lisp-indent)))
          (cond
           ((null indent)  ; nil means use default
            (current-indentation))
           ((and (integerp indent) (>= indent 0))
            indent)
           (t
            ;; For negative values or other special cases, use current indentation
            (current-indentation)))))
    (error
     (save-excursion
       (goto-char pos)
       (beginning-of-line)
       (current-indentation)))))

(defun pearl-paren-style--detect ()
  "Return current style: `compact', `dangling', or nil."
  (save-excursion
    (goto-char (point-min))
    (let ((compact 0) (dangling 0) (has-parens nil))
      (while (search-forward ")" nil t)
        (unless (pearl-paren-style--in-string-or-comment-p)
          (setq has-parens t)
          (backward-char)
          (let ((open-pos (condition-case nil
                              (scan-lists (point) -1 1)
                            (scan-error nil)))
                (closing-paren-pos (point)))
            ;; Only count multi-line parens
            (when (and open-pos
                       (/= (line-number-at-pos open-pos) (line-number-at-pos))
                       (save-excursion
                         (goto-char open-pos)
                         (not (eq (char-before) ?\)))))
              ;; Simplified: check if the closing parenthesis is at line start (only whitespace before it)
              (if (save-excursion
                    (beginning-of-line)
                    (skip-chars-forward " \t")
                    (= (point) closing-paren-pos))
                  (cl-incf dangling)
                (cl-incf compact))))
          (forward-char)))
      (cond ((> dangling compact) 'dangling)
            ((> compact dangling) 'compact)
            ((> dangling 0) 'dangling)  ; equal but non-zero, prefer dangling
            ((> compact 0) 'compact)    ; only compact exists
            (has-parens 'compact)       ; all parens are single-line
            (t nil))                    ; no parens found
      )))

(defun pearl-paren-style--to-dangling ()
  "Convert buffer to dangling style.
Single-line parens like (foo) remain unchanged."
  (save-excursion
    (goto-char (point-max))
    (while (search-backward ")" nil t)
      (unless (pearl-paren-style--in-string-or-comment-p)
        (let ((line-start (line-beginning-position))
              (current-col (current-column)))
          (let ((open-pos (condition-case nil
                              (scan-lists (point) -1 1)
                            (scan-error nil))))
            (when (and open-pos
                       (/= (line-number-at-pos open-pos) (line-number-at-pos))
                       (save-excursion
                         (goto-char open-pos)
                         (not (eq (char-before) ?\)))))
              (let ((indent-col (save-excursion
                                  (goto-char open-pos)
                                  (current-column))))
                ;; Check if already correctly positioned (on its own line, correct indent)
                (if (and (looking-back "^\\s-*" line-start)
                         (= current-col indent-col))
                    ;; Already correct: do nothing
                    nil
                  ;; Need to adjust position
                  (if (looking-back "^\\s-*" line-start)
                      ;; At line start but wrong indent: fix indent
                      (progn
                        (delete-horizontal-space)
                        (indent-to indent-col))
                    ;; Not at line start: move to new line
                    (let* ((end-of-line (line-end-position))
                           comment-text)
                      (save-excursion
                        (forward-char)
                        (let ((after-paren (point)))
                          (skip-chars-forward " \t" end-of-line)
                          (when (and (< (point) end-of-line)
                                     (= (char-after (point)) ?\;))
                            (setq comment-text (buffer-substring after-paren end-of-line))
                            (delete-region after-paren end-of-line))))
                      (let ((closing-paren ")"))
                        (delete-char 1)
                        (delete-region (point) (line-end-position))
                        (insert "\n")
                        (indent-to indent-col)
                        (insert closing-paren)
                        (when comment-text
                          (insert (if (string-match-p "^[ \t]" comment-text)
                                      comment-text
                                    (concat " " comment-text))))))))))))))))

(defun pearl-paren-style--to-compact ()
  "Convert buffer to compact style."
  (save-excursion
    (goto-char (point-max))
    (let ((changed t))
      (while changed
        (setq changed nil)
        (while (search-backward ")" nil t)
          (unless (pearl-paren-style--in-string-or-comment-p)
            (let ((line-start (line-beginning-position)))
              (when (and (>= (point) line-start)
                         (looking-back "^\\s-*" line-start)
                         (save-excursion
                           (condition-case nil
                               (let ((open-pos (scan-lists (point) -1 1)))
                                 (when open-pos
                                   (goto-char open-pos)
                                   (not (looking-back ")" (1- (point))))))
                             (scan-error nil))))
                ;; Check if the direct previous line has a comment.
                ;; If so, we cannot merge ) to that line to avoid ) being commented out.
                (if (save-excursion
                      (forward-line -1)
                      (pearl-paren-style--line-has-comment-p))
                    ;; Previous line has comment, adjust current line indentation
                    ;; using Lisp indentation rules
                    (let* ((target-indent (pearl-paren-style--calculate-compact-indent (point)))
                           (current-indent
                            (save-excursion
                              (beginning-of-line)
                              (skip-chars-forward " \t")
                              (current-column))))
                      (when (and target-indent
                                 (/= current-indent target-indent))
                        (save-excursion
                          (beginning-of-line)
                          (delete-horizontal-space)
                          (indent-to target-indent))
                        (setq changed t)))
                  ;; No comment on previous line, proceed with merge
                  (let ((comment-text nil)
                        (comment-leading-spaces "")
                        (after-paren (point))
                        (line-end (line-end-position))
                        (rest-of-line "")
                        (open-pos (condition-case nil
                                      (scan-lists (point) -1 1)
                                    (scan-error nil))))

                    ;; Extract content from closing paren to end of line
                    (setq rest-of-line (buffer-substring after-paren line-end))

                    (save-excursion
                      (goto-char after-paren)
                      (forward-char)  ; Move after the closing paren
                      (let ((space-start (point)))
                        (skip-chars-forward " \t" line-end)
                        (when (and (< (point) line-end)
                                   (= (char-after) ?\;))
                          (setq comment-leading-spaces (buffer-substring space-start (point)))
                          (setq comment-text (buffer-substring (point) line-end))
                          ;; If there is a comment, rest-of-line should only contain the closing paren
                          (setq rest-of-line ")"))))

                    ;; Delete current line (including the closing paren)
                    (let ((delete-end (line-beginning-position 2)))
                      (delete-region line-start delete-end))

                    ;; Insert closing paren (and comment) into previous line
                    (save-excursion
                      (goto-char line-start)
                      (forward-line -1)
                      (end-of-line)
                      ;; If previous line already has content, ensure proper indentation
                      (let ((current-col (current-column)))
                        (insert rest-of-line)
                        (when comment-text
                          (insert (if (string-empty-p comment-leading-spaces)
                                      " "
                                    comment-leading-spaces)
                                  comment-text))))
                    (setq changed t)))))))
        (when changed
          (goto-char (point-max)))))
    ;; Delete trailing blank lines at end of buffer, but ensure file ends with newline
    (save-excursion
      (goto-char (point-max))
      (skip-chars-backward "\n")
      (when (< (point) (point-max))
        (delete-region (point) (point-max))
        (insert "\n")))))

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
