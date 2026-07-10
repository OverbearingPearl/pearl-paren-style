;;; pearl-paren-style.el --- Toggle Lisp paren style  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.3
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
  (or (nth 8 (syntax-ppss))  ; inside comment or string
      (save-excursion
        (let ((pos (point)))
          (when (re-search-backward "#|" nil t)
            (let ((start (point)))
              (goto-char start)
              (when (re-search-forward "|#" nil t)
                (<= pos (point)))))))))

(defun pearl-paren-style--detect ()
  "Return current style: `compact', `dangling', or nil."
  (save-excursion
    (goto-char (point-min))
    (let ((compact 0) (dangling 0))
      (while (search-forward ")" nil t)
        (unless (pearl-paren-style--in-string-or-comment-p)
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
            ((= dangling compact) pearl-paren-style-default)))))

(defun pearl-paren-style--to-dangling ()
  "Convert buffer to dangling style.
Single-line parens like (foo) remain unchanged."
  (save-excursion
    (goto-char (point-max))
    (while (search-backward ")" nil t)
      (unless (pearl-paren-style--in-string-or-comment-p)
        (let ((line-start (line-beginning-position)))
          (unless (looking-back "^\\s-*" line-start)
            (let ((open-pos (condition-case nil
                                (scan-lists (point) -1 1)
                              (scan-error nil))))
              (when (and open-pos
                         (/= (line-number-at-pos open-pos) (line-number-at-pos))
                         (save-excursion
                           (goto-char open-pos)
                           (not (pearl-paren-style--in-string-or-comment-p))))
                ;; Compute indentation: use the column of the opening parenthesis
                (let ((indent-col (save-excursion
                                    (goto-char open-pos)
                                    (current-column))))
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
                                  (concat " " comment-text)))))))))))))))

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
                ;; Check if the previous line is a comment line
                (unless (save-excursion
                          (forward-line -1)
                          (back-to-indentation)
                          (looking-at ";"))
                  ;; Check for trailing comment
                  (let ((comment-text nil)
                        (comment-leading-spaces "")
                        (after-paren (point))
                        (line-end (line-end-position)))
                    (let ((rest-of-line (buffer-substring after-paren line-end)))

                      (save-excursion
                        (goto-char after-paren)
                        (forward-char)
                        (let ((space-start (point)))
                          (skip-chars-forward " \t" line-end)
                          (when (and (< (point) line-end)
                                     (= (char-after) ?\;))
                            (setq comment-leading-spaces (buffer-substring space-start (point)))
                            (setq comment-text (buffer-substring (point) line-end))
                            (let ((comment-start (- space-start after-paren)))
                              (setq rest-of-line (substring rest-of-line 0 comment-start))))))

                      (let ((delete-end (line-beginning-position 2)))
                        (delete-region line-start delete-end))
                      (save-excursion
                        (goto-char line-start)
                        (forward-line -1)
                        (end-of-line)
                        (insert rest-of-line)
                        (when comment-text
                          (insert (if (string-empty-p comment-leading-spaces)
                                      " "
                                    comment-leading-spaces)
                                  comment-text)))
                      (setq changed t))))))))
        (when changed
          (goto-char (point-max)))))
    ;; Delete trailing blank lines at end of buffer
    (save-excursion
      (goto-char (point-max))
      (skip-chars-backward "\n")
      (when (< (point) (point-max))
        (delete-region (point) (point-max))))))

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
