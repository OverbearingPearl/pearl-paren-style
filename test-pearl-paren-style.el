;;; test-pearl-paren-style.el --- Tests for pearl-paren-style  -*- lexical-binding: t; -*-
;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: lisp, tools, convenience
;; URL: https://github.com/OverbearingPearl/pearl-paren-style

;;; Commentary:

;; ERT tests for pearl-paren-style.el

;;; Code:

(require 'ert)
(require 'pearl-paren-style)

(ert-deftest test-detect-compact ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo\n  (bar))")
    (should (eq (pearl-paren-style--detect) 'compact))))

(ert-deftest test-detect-dangling ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo (bar)\n  )")
    (should (eq (pearl-paren-style--detect) 'dangling))))

(ert-deftest test-toggle-compact-to-dangling ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(let ((x 1))\n  (foo))")
    (pearl-paren-style-toggle)
    (should (eq (pearl-paren-style--detect) 'dangling))))

(ert-deftest test-toggle-dangling-to-compact ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(let ((x 1)\n      )\n  (foo)\n  )")
    (pearl-paren-style-toggle)
    (should (eq (pearl-paren-style--detect) 'compact))))

(ert-deftest test-toggle-roundtrip ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun f (x)\n  (+ x 1))")
    (pearl-paren-style-toggle)
    (pearl-paren-style-toggle)
    (should (eq (pearl-paren-style--detect) 'compact))))

(ert-deftest test-dangling-keeps-single-line ()
  "Single-line parens should stay compact in dangling mode."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo) (bar)")
    (pearl-paren-style-dangling)
    (should (string= (buffer-string) "(foo) (bar)"))))

(ert-deftest test-dangling-converts-multi-line ()
  "Multi-line parens should become dangling."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo\n  (bar))")
    (pearl-paren-style-dangling)
    (should (eq (pearl-paren-style--detect) 'dangling))))

(ert-deftest test-dangling-alignment ()
  "Closing paren should align with opening paren."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun foo ()\n  (let ((x 1))\n    (bar)))")
    (pearl-paren-style-dangling)
    ;; Verify last ) aligns with (defun at column 0
    (goto-char (point-max))
    (search-backward ")")
    (beginning-of-line)
    (should (looking-at ")$"))  ; Column 0

    ;; Verify inner ) aligns with (let at column 2
    (search-backward ")")
    (beginning-of-line)
    (should (looking-at "  )$"))))  ; Column 2

(provide 'test-pearl-paren-style)
;;; test-pearl-paren-style.el ends here
