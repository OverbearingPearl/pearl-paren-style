;;; test-pearl-paren-style.el --- Tests for pearl-paren-style  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.6
;; Package-Requires: ((emacs "24.4"))
;; Keywords: lisp, tools, convenience
;; URL: https://github.com/OverbearingPearl/pearl-paren-style

;;; Commentary:

;; ERT tests for pearl-paren-style.el

;;; Code:

(require 'ert)
(require 'pearl-paren-style)

(ert-deftest test-pearl-paren-style-detect-compact ()
  "Detect compact style when closing paren is on the same line as content."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar))")
          (expected-style 'compact))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-detect-dangling ()
  "Detect dangling style when closing paren is on its own line."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo (bar)\n  )")
          (expected-style 'dangling))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-detect-edge-cases ()
  "Test detection in various edge cases."
  ;; Nested compact form
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar))")
          (expected-style 'compact))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style))))))

  ;; Single dangling paren
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo (bar)\n  )")
          (expected-style 'dangling))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style))))))

  ;; Multiple dangling parens
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar\n    )\n  )")
          (expected-style 'dangling))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style))))))

  ;; Single line multiple forms
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo (bar) (baz))")
          (expected-style 'compact))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-toggle-compact-to-dangling ()
  "Toggle from compact to dangling style."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(let ((x 1))\n  (foo))")
          (expected-style 'dangling))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s\nExpected: %s"
                            original result detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-toggle-dangling-to-compact ()
  "Toggle from dangling to compact style."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(let ((x 1)\n      )\n  (foo)\n  )")
          (expected-style 'compact))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s\nExpected: %s"
                            original result detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-toggle-roundtrip ()
  "Toggle twice should return to original compact style."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun example (x)\n  (+ x 1))")
          (expected-style 'compact))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((after-first (buffer-string)))
        (pearl-paren-style-toggle)
        (let ((result (buffer-string))
              (detected (pearl-paren-style--detect)))
          (ert-info ((format "Original:\n%s\nAfter first toggle:\n%s\nAfter second toggle:\n%s\nDetected: %s\nExpected: %s"
                              original after-first result detected expected-style))
            (should (eq detected expected-style))))))))

(ert-deftest test-pearl-paren-style-dangling-keeps-single-line ()
  "Single-line parens should stay compact in dangling mode."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo) (bar)")
          (expected "(foo) (bar)"))
      (insert original)
      (pearl-paren-style-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected: %s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-dangling-converts-multi-line ()
  "Multi-line parens should become dangling."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar))")
          (expected-style 'dangling))
      (insert original)
      (pearl-paren-style-dangling)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s\nExpected style: %s"
                            original result detected expected-style))
          (should (eq detected expected-style))
          ;; Check there are no extra blank lines
          (should (string-match-p ")$" result))
          (should (= (count-lines (point-min) (point-max)) 3))
          ;; Check that the second line ends with )
          (goto-char (point-min))
          (forward-line 1)
          (end-of-line)
          (backward-char)
          (should (looking-at ")")))))))

(ert-deftest test-pearl-paren-style-dangling-alignment ()
  "Closing paren should align with opening paren."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun outer ()\n  (let ((x 1))\n    (inner)))"))
      (insert original)
      (pearl-paren-style-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Verify last ) aligns with (defun at column 0
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at ")$"))  ; Column 0

          ;; Verify inner ) aligns with (let at column 2
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at "  )$")))))))

(ert-deftest test-pearl-paren-style-detect-in-multiline-comment ()
  "Parentheses inside multi-line comments should be ignored."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "#| (ignored\n  (parens)) |#\n(foo\n  (bar))")
          (expected-style 'compact))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected: %s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-compact-after-comment-line ()
  "Should not merge ) into previous line if it's a comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  ;; comment\n  )")
          (expected "(foo\n  ;; comment\n )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string-match-p ";; comment" result))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-compact-multi-level-with-comment ()
  "Should compact multi-level dangling parens with comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(outer\n  (middle\n    (inner\n      )\n    )  ; end comment\n  )\n)")
          (expected "(outer\n  (middle\n    (inner)))  ; end comment\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string-match-p "; end comment" result))
          ;; Check that comment is on the same line as closing parens
          (goto-char (point-min))
          (search-forward ";")
          (beginning-of-line)
          (let ((line (thing-at-point 'line)))
            (ert-info ((format "Line with comment: '%s'" line))
              (should (string-match-p "; end comment" line)))
            ;; Check that there are multiple ) on the line with comment
            (save-excursion
              (beginning-of-line)
              (let ((count 0)
                    (line-end (line-end-position)))
                (while (search-forward ")" line-end t)
                  (save-excursion
                    (backward-char)
                    (unless (pearl-paren-style--in-string-or-comment-p)
                      (cl-incf count))))
                (should (> count 1))))))))))

(ert-deftest test-pearl-paren-style-dangling-with-end-comment ()
  "Should handle ) followed by comment correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; end comment"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; end comment" result))
          (goto-char (point-max))
          (search-backward ";")
          (should (looking-at "; end comment")))))))

(ert-deftest test-pearl-paren-style-dangling-with-paren-in-comment ()
  "Should handle ) in comment correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; note: function returns ')'"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; note: function returns ')'" result))
          (goto-char (point-max))
          (search-backward ";")
          (should (looking-at "; note: function returns ')'")))))))

(ert-deftest test-pearl-paren-style-compact-with-paren-in-comment ()
  "Should handle ) in comment correctly when converting to compact."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar\n    )  ; note: returns ')'\n  )\n)"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; note: returns ')'" result))
          (goto-char (point-max))
          (search-backward ";")
          (should (looking-at "; note: returns ')'")))))))

(ert-deftest test-pearl-paren-style-comment-with-left-paren-only ()
  "Should handle ( in comment correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; note: open paren '('\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; note: open paren '('") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; note: open paren '('") result2)))))))

(ert-deftest test-pearl-paren-style-comment-with-unbalanced-parens ()
  "Should handle unbalanced parentheses in comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; unbalanced '(()' in comment\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; unbalanced '(()' in comment") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; unbalanced '(()' in comment") result2)))))))

(ert-deftest test-pearl-paren-style-multiline-comment-with-parens ()
  "Should handle parentheses in multi-line comments."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "#| (ignored\n  (parens)) |#\n(foo\n  (bar))"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          ;; Check that multi-line comment still exists (content may be modified)
          (should (string-match-p "#|" result1))
          (should (string-match-p "|#" result1))
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at ")$"))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p "#|" result2))
          (should (string-match-p "|#" result2))
          (should (string-match-p "(foo\n  (bar))" result2)))))))

(ert-deftest test-pearl-paren-style-compact-with-consecutive-comments ()
  "Should not merge ) into previous consecutive comment lines."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  ;; comment 1\n  ;; comment 2\n  ;; comment 3\n  )")
          (expected "(foo\n  ;; comment 1\n  ;; comment 2\n  ;; comment 3\n )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string-match-p ";; comment 1" result))
          (should (string-match-p ";; comment 2" result))
          (should (string-match-p ";; comment 3" result))
          ;; Should not merge ) with comment lines
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-compact-with-mixed-lines ()
  "Should handle mixed code and comment lines before )."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)\n  ;; comment\n  )")
          (expected "(foo\n  (bar)\n  ;; comment\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string-match-p ";; comment" result))
          ;; Should NOT merge ) with (bar) line because there's a comment line between them
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-no-extra-blank-lines ()
  "Should not create extra blank lines when converting to dangling."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun example ()\n  (do-something))"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Check the number of lines in result
          (should (= (count-lines (point-min) (point-max)) 3))
          ;; Check that no line is empty
          (goto-char (point-min))
          (while (not (eobp))
            (should-not (looking-at "^\\s-*$"))
            (forward-line 1))
          ;; Check that the last line ends with )
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at "\\s-*)$"))
          (goto-char (point-min))
          (should-not (re-search-forward "\n\n" nil t)))))))

(ert-deftest test-pearl-paren-style-no-extra-blank-lines-after-toggle ()
  "Should not create extra blank lines when toggling from dangling to compact."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun outer ()\n  (let ((x 1))\n    (inner\n      (nested)\n    )\n  )\n)")
          (expected-lines 6))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Check there are no extra blank lines
          (should-not (string-match-p "\n\n\n" result))
          ;; Check that line count is same as or less than original
          (let ((original-lines (with-temp-buffer
                                  (insert original)
                                  (count-lines (point-min) (point-max))))
                (result-lines (count-lines (point-min) (point-max))))
            (should (<= result-lines original-lines)))
          ;; Check that the last line is not empty
          (goto-char (point-max))
          (forward-line -1)
          (should-not (looking-at "^\\s-*$")))))))

(ert-deftest test-pearl-paren-style-compact-no-dangling-lines ()
  "Converting to compact should not leave any empty lines from deleted paren lines."
  (with-temp-buffer
    (emacs-lisp-mode)
    ;; Use multi-level nested dangling code, which is the scenario most prone to blank lines
    (let ((original "(defun outer ()\n  (let ((x 1))\n    (middle\n      (inner\n        )\n      )\n    )\n  )")
          (expected-lines 4))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Verify there are no blank lines (lines containing only whitespace from start to end)
          (goto-char (point-min))
          (while (not (eobp))
            (should-not (looking-at "^\\s-*$"))
            (forward-line 1))
          ;; Verify there are no consecutive newlines (i.e., no blank lines)
          (should-not (string-match-p "\n\n" result))
          ;; Verify the last line indeed ends with ) and has no newline or whitespace after it
          (goto-char (point-max))
          (skip-chars-backward " \t\n")
          (should (eq (char-before) ?\)))
          ;; Verify exact line count after compact
          (should (= (count-lines (point-min) (point-max)) expected-lines)))))))

(ert-deftest test-pearl-paren-style-roundtrip-preserves-comment-spacing ()
  "Toggle should preserve spacing before trailing comments."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun example ()\n  (do-something))  ; two spaces before comment\n")
          (expected "(defun example ()\n  (do-something))  ; two spaces before comment\n"))
      (insert original)
      (pearl-paren-style-toggle) ; to dangling
      (pearl-paren-style-toggle) ; back to compact
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-dangling-to-compact-with-comment-line ()
  "Test case for the bug where dangling to compact conversion incorrectly handles comments.
When converting from dangling to compact style, if there's a comment on the same line as
a closing parenthesis, the conversion should properly merge the parentheses with the comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun example ()\n  (let ((data '(1 2 3)))\n    (process\n      (get-item data)  ; retrieve item\n    )\n  )\n)\n")
          (expected "(defun example ()\n  (let ((data '(1 2 3)))\n    (process\n      (get-item data)  ; retrieve item\n      )))\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-dangling-multi-level-with-comments ()
  "Dangling conversion with comments on multiple closing paren lines."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(outer\n  (middle\n    (inner\n    )  ; close middle\n  )  ; close outer\n)")
          (expected "(outer\n  (middle\n    (inner\n    )  ; close middle\n  )  ; close outer\n)"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-compact-merges-paren-line-with-trailing-comment ()
  "Compact conversion should merge a ) line that has a trailing comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar\n    )\n  )  ; close foo\n")
          (expected "(foo\n  (bar))  ; close foo\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-comment-with-many-left-parens ()
  "Comment containing many unbalanced left parens."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; ((((((\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; ((((((") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; ((((((") result2)))))))

(ert-deftest test-pearl-paren-style-comment-with-many-right-parens ()
  "Comment containing many unbalanced right parens."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; ))))))\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; ))))))") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; ))))))") result2)))))))

(ert-deftest test-pearl-paren-style-comment-with-mixed-unbalanced-parens ()
  "Comment containing mixed unbalanced parens like ()())(."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; ()())(()\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; ()())((") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; ()())((") result2)))))))

(ert-deftest test-pearl-paren-style-dangling-code-plus-comment-before-paren ()
  "When previous line is code+comment, ) should not merge but go to its own line."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)  ; side effect\n)")
          (expected "(foo\n  (bar)  ; side effect\n)"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-string-with-parens-ignored ()
  "Parentheses inside string literals should not affect conversion."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar \"some (parens) here\"))"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "\"some (parens) here\"" result))
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at "\\s-*)$")))))))

(ert-deftest test-pearl-paren-style-empty-lines-before-paren ()
  "Empty lines between code and closing paren should be removed or preserved correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)\n\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Should not leave blank lines from deleted paren lines
          (should-not (string-match-p "\n\n" result)))))))

(ert-deftest test-pearl-paren-style-deep-nested-comments-every-level ()
  "Deep nesting with comments at every closing level."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n    (c\n      )\n    )  ; end c\n  )  ; end b\n)  ; end a\n")
          (expected-compact "(a\n  (b\n    (c)))  ; end c\n)  ; end a\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected-compact))
          ;; The innermost comment should merge with its code line
          (should (string-match-p "; end c" result))
          ;; The outer comments should remain on their own lines
          (should (string-match-p "; end a" result)))))))

(ert-deftest test-pearl-paren-style-detect-empty-buffer ()
  "Detect in empty buffer should return nil."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "")
          (expected-style nil))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original: '%s'\nDetected: %s\nExpected:\n%s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-detect-only-comments ()
  "Detect in buffer with only comments should return nil."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original ";; just a comment\n;; another comment")
          (expected-style nil))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected:\n%s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-detect-mixed-style ()
  "Detect mixed style should prefer dangling when any dangling exists."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)))\n(baz\n  (qux)\n)")
          (expected-style 'dangling))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nDetected: %s\nExpected:\n%s"
                            original detected expected-style))
          (should (eq detected expected-style)))))))

(ert-deftest test-pearl-paren-style-char-literal-parens ()
  "Character literals ?\\( and ?\\) should not be treated as structural parens."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(list ?\\( ?\\))"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "?\\\\(" result))
          (should (string-match-p "?\\\\)" result)))))))

(ert-deftest test-pearl-paren-style-char-literal-semicolon ()
  "Character literal ?\; should not be treated as comment start."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(list ?\\; ?a)\n(foo\n  (bar)\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Should merge ) with (bar) line despite ?\; on previous line
          (should (string-match-p (regexp-quote "(list ?\\; ?a)") result))
          (should (string-match-p "(foo\n  (bar))" result)))))))

(ert-deftest test-pearl-paren-style-char-literal-semicolon-in-code ()
  "Character literal ?\; in code should not prevent compact conversion."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun test ()\n  (let ((x ?\\;))\n    (process x)\n  )\n)")
          (expected "(defun test ()\n  (let ((x ?\\;))\n    (process x)))\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string-match-p "?\\\\;" result))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-docstring-with-parens ()
  "Parentheses inside docstrings should be ignored."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun example ()\n  \"Returns (values a b).\"\n  (do-something))"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "\"Returns (values a b).\"" result))
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at "\\s-*)$")))))))

(ert-deftest test-pearl-paren-style-multiline-string-with-parens ()
  "Parentheses inside multi-line strings should be ignored."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(message \"line1\nwith (parens)\nline3\")"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "\"line1" result))
          (should (string-match-p "with (parens)" result))
          (should (string-match-p "line3\"" result)))))))

(ert-deftest test-pearl-paren-style-compact-mixed-paren-lines-with-comments ()
  "Some ) lines have comments, some do not."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n  )  ; close b\n)  ; close a\n")
          (expected "(a\n  (b)  ; close b\n  )  ; close a\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-deep-nesting ()
  "Very deep nesting should convert correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n    (c\n      (d\n        (e\n          (f\n            (g\n              (h\n                (i\n                  (j\n                  )\n                )\n              )\n            )\n          )\n        )\n      )\n    )\n  )\n)")
          (expected-lines 10))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (= (count-lines (point-min) (point-max)) expected-lines))
          (goto-char (point-max))
          (skip-chars-backward " \t\n")
          (should (eq (char-before) ?\))))))))

(ert-deftest test-pearl-paren-style-dangling-align-column-zero ()
  "Closing paren at column 0 should stay at column 0."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(top-level\n  (nested\n  )\n)"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          ;; Check the last line (closing paren of top-level)
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at ")$"))  ; Should be at column 0

          ;; Check the inner closing paren (closing nested)
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at "  )$")))))  ; Should be at column 2
    ))

(ert-deftest test-pearl-paren-style-compact-multi-level-nested-with-comment ()
  "Compact conversion with multi-level nested parentheses and comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n    (c\n      (d\n        (foo (bar))\n      )\n    )\n  )  ;; comment\n)")
          (expected "(a\n  (b\n    (c\n      (d\n        (foo (bar)))))  ;; comment\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-dangling-multi-level-nested-with-comment ()
  "Dangling conversion with multi-level nested parentheses and comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n    (c\n      (d\n        (foo (bar)))))  ;; comment\n)")
          (expected "(a\n  (b\n    (c\n      (d\n        (foo (bar))\n      )\n    )\n  )  ;; comment\n)"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected)))))))

(ert-deftest test-pearl-paren-style-dangling-deep-nested-indent ()
  "Deep nested dangling should align outermost paren with its opener."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(a\n  (b\n    (c\n      (d\n        (foo (bar)))))  ;; comment\n    )")
          (expected "(a\n  (b\n    (c\n      (d\n        (foo (bar))\n      )\n    )\n  )  ;; comment\n)"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s"
                            original result expected))
          (should (string= result expected))
          ;; Verify outermost ) aligns with (a at column 0
          (goto-char (point-max))
          (search-backward ")")
          (beginning-of-line)
          (should (looking-at ")$")))))))

(ert-deftest test-pearl-paren-style-check-balanced-p ()
  "Test bracket balance checking."
  (with-temp-buffer
    (emacs-lisp-mode)
    ;; Balanced code
    (insert "(defun test ()\n  (list 1 2 3))")
    (should (pearl-paren-style--check-balanced-p))

    ;; Unbalanced code
    (erase-buffer)
    (insert "(defun test ()\n  (list 1 2 3)") ; missing closing paren
    (should-not (pearl-paren-style--check-balanced-p))

    ;; Balanced region
    (erase-buffer)
    (insert "(foo (bar))\n(unbalanced (code")
    (should (pearl-paren-style--check-balanced-p 1 13)) ; first line only
    (should-not (pearl-paren-style--check-balanced-p 14 (point-max))) ; second line
    ))

(ert-deftest test-pearl-paren-style-check-balanced-p-region ()
  "Test bracket balance checking with region arguments."
  (with-temp-buffer
    (emacs-lisp-mode)
    ;; Test with explicit beg/end arguments
    (insert "(foo (bar))\n(unbalanced (code")
    (should (pearl-paren-style--check-balanced-p 1 13)) ; first line only
    (should-not (pearl-paren-style--check-balanced-p 14 (point-max))) ; second line

    ;; Test with nil arguments (should check whole buffer)
    (erase-buffer)
    (insert "(balanced (code))")
    (should (pearl-paren-style--check-balanced-p)) ; no arguments

    ;; Test with region that has unbalanced parens
    (erase-buffer)
    (insert "(foo (bar)\n(unbalanced")
    (should-not (pearl-paren-style--check-balanced-p 1 (point-max)))

    ;; Test edge case: empty region
    (erase-buffer)
    (insert "(foo (bar))")
    (should (pearl-paren-style--check-balanced-p 1 1)) ; empty region should be balanced
    ))

(ert-deftest test-pearl-paren-style-compact-region ()
  "Convert selected region to compact style."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun test ()\n  (let ((x 1))\n    (foo)\n  )\n)")
    (goto-char (point-min))
    (forward-line 1) ; move to second line
    (set-mark (point))
    (forward-line 3) ; select lines 2-4 (complete let expression)
    (activate-mark)
    (call-interactively 'pearl-paren-style-compact-region)
    (let ((result (buffer-string)))
      (should (string-match-p "(defun test ()" result))
      (should (string-match-p "  (let ((x 1))\n    (foo))" result))
      (should (string-match-p ")" result)))))

(ert-deftest test-pearl-paren-style-dangling-region ()
  "Convert selected region to dangling style."
  (with-temp-buffer
    (emacs-lisp-mode)
    ;; Use balanced code: independent let expression
    (insert "(let ((x 1))\n  (foo)\n  (bar))\n")
    (goto-char (point-min))
    (set-mark (point))
    (forward-line 3) ; select all lines
    (activate-mark)
    (call-interactively 'pearl-paren-style-dangling-region)
    (let ((result (buffer-string)))
      (should (string-match-p "(let ((x 1))\n  (foo)\n  (bar)\n)" result)))))

(ert-deftest test-pearl-paren-style-toggle-region ()
  "Toggle style in selected region."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun test ()\n  (let ((x 1))\n    (foo)\n  )\n)")
    (goto-char (point-min))
    (forward-line 1) ; move to second line
    (set-mark (point))
    (forward-line 3) ; select lines 2-4 (complete let expression)
    (activate-mark)
    (let ((original (buffer-string)))
      (call-interactively 'pearl-paren-style-toggle-region)
      (let ((result (buffer-string)))
        (should-not (string= result original))
        ;; Should have converted dangling to compact
        (should (string-match-p "  (let ((x 1))\n    (foo))" result))))))

(ert-deftest test-pearl-paren-style-convert-region ()
  "Convert region with style selection."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun test ()\n  (let ((x 1))\n    (foo)\n  )\n)")
    (goto-char (point-min))
    (forward-line 1) ; move to second line
    (set-mark (point))
    (forward-line 3) ; select lines 2-4 (complete let expression)
    (activate-mark)
    ;; Test will mock the interactive prompt
    (cl-letf (((symbol-function 'completing-read)
               (lambda (_prompt _collection &optional _predicate _require-match _initial-input _hist _def _inherit-input-method)
                 "compact")))
      ;; Call function directly, not call-interactively
      (pearl-paren-style-convert-region 'compact (region-beginning) (region-end))
      (let ((result (buffer-string)))
        (should (string-match-p "  (let ((x 1))\n    (foo))" result))))))

(ert-deftest test-pearl-paren-style-dwim-region ()
  "DWIM should call convert-region when region is active."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun test ()\n  (let ((x 1))\n    (foo)\n  )\n)")
    (goto-char (point-min))
    (forward-line 1) ; move to second line
    (set-mark (point))
    (forward-line 3) ; select lines 2-4 (complete let expression)
    (activate-mark)
    ;; Mock the interactive prompt
    (cl-letf (((symbol-function 'completing-read)
               (lambda (_prompt _collection &optional _predicate _require-match _initial-input _hist _def _inherit-input-method)
                 "compact")))
      ;; DWIM will call call-interactively, so we need to simulate interactive call
      (cl-letf (((symbol-function 'call-interactively)
                 (lambda (command)
                   (when (eq command 'pearl-paren-style-convert-region)
                     (pearl-paren-style-convert-region 'compact (region-beginning) (region-end))))))
        (pearl-paren-style-dwim)
        (let ((result (buffer-string)))
          (should (string-match-p "  (let ((x 1))\n    (foo))" result)))))))

(ert-deftest test-pearl-paren-style-dwim-buffer ()
  "DWIM should call toggle when no region is active."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun test ()\n  (let ((x 1))\n    (foo)))\n")
    (let ((original (buffer-string)))
      (call-interactively 'pearl-paren-style-dwim)
      (let ((result (buffer-string)))
        (should-not (string= result original))
        ;; Should have toggled to dangling
        (should (string-match-p "  (let ((x 1))\n    (foo)\n  )" result))))))

(ert-deftest test-pearl-paren-style-file-processing ()
  "Test file processing functions with temporary files."
  (let* ((temp-dir (make-temp-file "pearl-test-" t))
         (file1 (expand-file-name "test1.el" temp-dir))
         (file2 (expand-file-name "test2.el" temp-dir))
         (subdir (expand-file-name "subexec" temp-dir))
         (file3 (expand-file-name "test3.el" subdir)))

    ;; Create directory structure
    (make-directory subdir t)

    ;; Create test files
    (with-temp-file file1
      (insert "(defun test1 ()\n  (list 1 2 3))"))

    (with-temp-file file2
      (insert "(defun test2 ()\n  (let ((x 1))\n    (foo)\n  )\n)"))

    (with-temp-file file3
      (insert "(defun test3 ()\n  (progn\n    (a)\n    (b)\n  )\n)"))

    ;; Test processing single file
    (should (pearl-paren-style--process-file file1 'dangling))
    (with-temp-buffer
      (insert-file-contents file1)
      (should (string-match-p "  (list 1 2 3)\n)" (buffer-string))))

    ;; Test processing multiple files
    (let ((files (list file1 file2)))
      (cl-letf (((symbol-function 'y-or-n-p) (lambda (_) t)))
        (pearl-paren-style-convert-files 'compact files))
      (with-temp-buffer
        (insert-file-contents file2)
        (should (string-match-p "  (let ((x 1))\n    (foo))" (buffer-string)))))

    ;; Test directory recursion
    (let ((files (list temp-dir)))
      (cl-letf (((symbol-function 'y-or-n-p) (lambda (_) t)))
        (pearl-paren-style-convert-files 'dangling files))
      (with-temp-buffer
        (insert-file-contents file3)
        (should (string-match-p "    (a)\n    (b)\n  )" (buffer-string)))))

    ;; Cleanup
    (delete-directory temp-dir t)))

(provide 'test-pearl-paren-style)
;;; test-pearl-paren-style.el ends here
