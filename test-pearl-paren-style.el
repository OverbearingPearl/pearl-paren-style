;;; test-pearl-paren-style.el --- Tests for pearl-paren-style  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 OverbearingPearl

;; Author: OverbearingPearl <OverbearingPearl@outlook.com>
;; Version: 0.1.3
;; Package-Requires: ((emacs "24.3"))
;; Keywords: lisp, tools, convenience
;; URL: https://github.com/OverbearingPearl/pearl-paren-style

;;; Commentary:

;; ERT tests for pearl-paren-style.el

;;; Code:

(require 'ert)
(require 'pearl-paren-style)

(ert-deftest test-pearl-paren-style-detect-compact ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo\n  (bar))")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'compact))))))

(ert-deftest test-pearl-paren-style-detect-dangling ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo (bar)\n  )")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'dangling))))))

(ert-deftest test-pearl-paren-style-detect-edge-cases ()
  "Test detection in various edge cases."
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo\n  (bar))")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'compact)))))

  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo (bar)\n  )")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'dangling)))))

  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo\n  (bar\n    )\n  )")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'dangling)))))

  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(foo (bar) (baz))")
    (let ((result (pearl-paren-style--detect)))
      (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) result))
        (should (eq result 'compact))))))

(ert-deftest test-pearl-paren-style-toggle-compact-to-dangling ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(let ((x 1))\n  (foo))"))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s" original result detected))
          (should (eq detected 'dangling)))))))

(ert-deftest test-pearl-paren-style-toggle-dangling-to-compact ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(let ((x 1)\n      )\n  (foo)\n  )"))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s" original result detected))
          (should (eq detected 'compact)))))))

(ert-deftest test-pearl-paren-style-toggle-roundtrip ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun f (x)\n  (+ x 1))"))
      (insert original)
      (pearl-paren-style-toggle)
      (let ((after-first (buffer-string)))
        (pearl-paren-style-toggle)
        (let ((result (buffer-string))
              (detected (pearl-paren-style--detect)))
          (ert-info ((format "Original:\n%s\nAfter first toggle:\n%s\nAfter second toggle:\n%s\nDetected: %s"
                            original after-first result detected))
            (should (eq detected 'compact))))))))

(ert-deftest test-pearl-paren-style-dangling-keeps-single-line ()
  "Single-line parens should stay compact in dangling mode."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo) (bar)"))
      (insert original)
      (pearl-paren-style-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string= result original)))))))

(ert-deftest test-pearl-paren-style-dangling-converts-multi-line ()
  "Multi-line parens should become dangling."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar))"))
      (insert original)
      (pearl-paren-style-dangling)
      (let ((result (buffer-string))
            (detected (pearl-paren-style--detect)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nDetected: %s" original result detected))
          (should (eq detected 'dangling))
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
    (let ((original "(defun foo ()\n  (let ((x 1))\n    (bar)))"))
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
    (let ((original "#| (foo\n  (bar)) |#\n(foo\n  (bar))"))
      (insert original)
      (let ((detected (pearl-paren-style--detect)))
        (ert-info ((format "Buffer:\n%s\nDetected: %s" (buffer-string) detected))
          (should (eq detected 'compact)))))))

(ert-deftest test-pearl-paren-style-compact-after-comment-line ()
  "Should not merge ) into previous line if it's a comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  ;; comment\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p ";; comment" result))
          (should (string= result original)))))))

(ert-deftest test-pearl-paren-style-compact-multi-level-with-comment ()
  "Should compact multi-level dangling parens with comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar\n    (baz\n      (qux\n      )\n    )  ; comment\n  )\n)"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; comment" result))
          ;; Check that comment is on the same line as closing parens
          (goto-char (point-min))
          (search-forward ";")
          (beginning-of-line)
          (let ((line (thing-at-point 'line)))
            (ert-info ((format "Line with comment: '%s'" line))
              (should (string-match-p "; comment" line)))
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
    (let ((original "(foo\n  (bar)) ; blabla, something may contains ')'"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; blabla, something may contains ')'" result))
          (goto-char (point-max))
          (search-backward ";")
          (should (looking-at "; blabla, something may contains ')'")))))))

(ert-deftest test-pearl-paren-style-compact-with-paren-in-comment ()
  "Should handle ) in comment correctly when converting to compact."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar\n    )  ; blabla, something may contains ')'\n  )\n)"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p "; blabla, something may contains ')'" result))
          (goto-char (point-max))
          (search-backward ";")
          (should (looking-at "; blabla, something may contains ')'")))))))

(ert-deftest test-pearl-paren-style-comment-with-left-paren-only ()
  "Should handle ( in comment correctly."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; blabla, something may contains '('\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; blabla, something may contains '('") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; blabla, something may contains '('") result2)))))))

(ert-deftest test-pearl-paren-style-comment-with-unbalanced-parens ()
  "Should handle unbalanced parentheses in comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)) ; blabla, something may contains '(()' but not balanced\n"))
      (insert original)
      (pearl-paren-style--to-dangling)
      (let ((result1 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-dangling:\n%s" original result1))
          (should (string-match-p (regexp-quote "; blabla, something may contains '(()' but not balanced") result1))))
      (delete-region (point-min) (point-max))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result2 (buffer-string)))
        (ert-info ((format "Original:\n%s\nAfter to-compact:\n%s" original result2))
          (should (string-match-p (regexp-quote "; blabla, something may contains '(()' but not balanced") result2)))))))

(ert-deftest test-pearl-paren-style-multiline-comment-with-parens ()
  "Should handle parentheses in multi-line comments."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "#| (foo\n  (bar)) |#\n(foo\n  (bar))"))
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
    (let ((original "(foo\n  ;; comment 1\n  ;; comment 2\n  ;; comment 3\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p ";; comment 1" result))
          (should (string-match-p ";; comment 2" result))
          (should (string-match-p ";; comment 3" result))
          ;; Should not merge ) with comment lines
          (should (string= result original)))))))

(ert-deftest test-pearl-paren-style-compact-with-mixed-lines ()
  "Should handle mixed code and comment lines before )."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(foo\n  (bar)\n  ;; comment\n  )"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string-match-p ";; comment" result))
          ;; Should NOT merge ) with (bar) line because there's a comment line between them
          (should (string= result original)))))))

(ert-deftest test-pearl-paren-style-no-extra-blank-lines ()
  "Should not create extra blank lines when converting to dangling."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(ert-deftest test-foo ()\n  (should t))"))
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
    (let ((original "(ert-deftest test-pearl-paren-style-detect-compact ()\n  (with-temp-buffer\n    (emacs-lisp-mode)\n    (insert \"(foo\\n  (bar))\")\n    (let ((result (pearl-paren-style--detect)))\n      (ert-info ((format \"Buffer: %s\\nDetected: %s\" (buffer-string) result))\n        (should (eq result 'compact))\n      )\n    )\n  )\n)"))
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
    ;; Use multi‑level nested dangling code, which is the scenario most prone to blank lines
    (let ((original "(ert-deftest test-foo ()\n  (with-temp-buffer\n    (emacs-lisp-mode)\n    (let ((result (pearl-paren-style--detect)))\n      (ert-info ((format \"Buffer: %s\" (buffer-string)))\n        (should (eq result 'compact))\n      )\n    )\n  )\n)"))
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
          ;; Verify exact line count: original 11 lines, after compact should be 6 lines (all closing parentheses merged into corresponding lines)
          (should (= (count-lines (point-min) (point-max)) 6)))))))

(ert-deftest test-pearl-paren-style-roundtrip-preserves-comment-spacing ()
  "Toggle should preserve spacing before trailing comments."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun foo ()\n  (bar))  ; two spaces before comment\n"))
      (insert original)
      (pearl-paren-style-toggle) ; to dangling
      (pearl-paren-style-toggle) ; back to compact
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s" original result))
          (should (string= result original)))))))

(ert-deftest test-pearl-paren-style-dangling-to-compact-with-comment-line ()
  "Test case for the bug where dangling to compact conversion incorrectly handles comments.
When converting from dangling to compact style, if there's a comment on the same line as
a closing parenthesis, the conversion should properly merge the parentheses with the comment."
  (with-temp-buffer
    (emacs-lisp-mode)
    (let ((original "(defun test-bug ()\n  (let ((stats '(1 2 3 4 5 6 7 8)))\n    (list\n      (nth 7 stats)  ; L6\n    )\n  )\n)\n")
          (expected "(defun test-bug ()\n  (let ((stats '(1 2 3 4 5 6 7 8)))\n    (list\n      (nth 7 stats)  ; L6\n      )))\n"))
      (insert original)
      (pearl-paren-style--to-compact)
      (let ((result (buffer-string)))
        (ert-info ((format "Original:\n%s\nResult:\n%s\nExpected:\n%s" original result expected))
          (should (string= result expected)))))))

(provide 'test-pearl-paren-style)
;;; test-pearl-paren-style.el ends here
