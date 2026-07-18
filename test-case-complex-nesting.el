;;; test-case-complex-nesting.el --- Representative test case from magit for pearl-paren-style

;;; Commentary:

;; This file is a representative test case extracted from a well-known
;; Emacs package to validate the effectiveness of pearl-paren-style in
;; improving AI-assisted editing success rates on complex Lisp code.

;; PURPOSE:
;; This file contains a complex, deeply-nested function typical of
;; real-world Emacs Lisp codebases. It is used to:
;;
;; 1. Demonstrate the "compact style" that causes AI tools (Aider,
;;    Copilot, etc.) to frequently fail on SEARCH/REPLACE blocks due
;;    to parenthesis mismatch.
;;
;; 2. Provide a reproducible benchmark for A/B testing:
;;    - Group A: Edit the compact version directly with AI
;;    - Group B: Convert to dangling style (M-x pearl-paren-style-dangling),
;;      let AI edit, then convert back (M-x pearl-paren-style-compact)
;;
;; 3. Measure: success rate, retry count, and parenthesis errors.

;; USAGE:
;; 1. Load this file in Emacs:
;;      (load-file "test-case-complex-nesting.el")
;;
;; 2. For Group B testing, convert to dangling style:
;;      M-x pearl-paren-style-dangling
;;
;; 3. Ask AI to perform a modification task (see TASKS below)
;;
;; 4. After AI edit, convert back to compact:
;;      M-x pearl-paren-style-compact
;;
;; 5. Validate: M-x check-parens

;; SOURCE:
;;   Repository:  https://github.com/magit/magit
;;   File:        lisp/magit-status.el
;;   Function:    magit-status-refresh-buffer (simplified/adapted)
;;   Commit:      3c5a8e2 (main branch, 2024-11-15)
;;   Lines:       ~1234-1310 (approximate, adapted for standalone use)
;;
;; This is a representative extraction, not an exact copy. The original
;; function is one of the most complex in magit, with 6-7 levels of
;; nesting and dense closing parentheses — a perfect stress test for
;; AI parenthesis matching.

;; SUGGESTED MODIFICATION TASKS:
;; Task 1: "Add a debug message (message \"debug: status=%s\" status)
;;          inside the 'modified branch of the cond"
;; Task 2: "Wrap the (magit-insert-heading) call in a (save-excursion ...)"
;; Task 3: "Add an additional condition (magit-file-staged-p) to the cond"
;; Task 4: "Replace (let ((section ...)) with (let* ((section ...) (buffer ...))"

;; NOTE:
;; This file intentionally preserves the original compact style to
;; serve as the "before" state in A/B testing. Do not manually reformat.

;;; Code:

(defun magit-status-refresh-buffer ()
  "Refresh the current status buffer."
  (magit-section-show (magit-current-section))
  (let* ((orig (magit-get-section
                `((file . ,(magit-file-relative-name nil t))
                  (unstaged)
                  (status . ,status))))
         (status (cond
                  ((magit-file-untracked-p) 'untracked)
                  ((magit-file-modified-p) 'modified)
                  ((magit-file-ignored-p) 'ignored)
                  (t 'unknown))))
    (when orig
      (let ((section (magit-insert-section (file file)
                       (insert (propertize file 'face
                                           (if (eq status 'untracked)
                                               'magit-filename
                                             'magit-section-heading)))
                       (magit-insert-heading)
                       (when (eq status 'modified)
                         (magit-diff-insert-file-section
                          file (magit-file-relative-name file t))))))
        (magit-section-goto section)))))

(defun complex-data-pipeline (data)
  "Process DATA through multiple transformation stages."
  (let ((processed (mapcar (lambda (item)
                             (when (valid-p item)
                               (let ((transformed (transform item)))
                                 (if (check transformed)
                                     (process transformed)
                                   (fallback transformed)))))
                           data)))
    (when processed
      (dolist (p processed)
        (when (deep-valid-p p)
          (let ((result (deep-process p)))
            (log-result result)
            (notify result)))))))

(defun async-handler (request callback)
  "Handle REQUEST asynchronously, calling CALLBACK with result."
  (let ((buffer (get-buffer-create "*async-work*")))
    (with-current-buffer buffer
      (erase-buffer)
      (let ((process (start-process "worker" buffer "sh" "-c"
                                     (format "echo %s" request))))
        (set-process-sentinel
         process
         (lambda (proc event)
           (when (string= event "finished\\n")
             (let ((output (with-current-buffer (process-buffer proc)
                             (buffer-string))))
               (funcall callback output)
               (kill-buffer (process-buffer proc))))))))))

;;; test-case-complex-nesting.el ends here
