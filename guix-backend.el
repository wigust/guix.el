;;; guix-backend.el --- Communication with Geiser

;; Copyright © 2014 Alex Kost

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides the code for interacting with Guile using Geiser.

;;; Code:

(require 'guix-utils)
(require 'geiser-mode)

(defvar guix-helper-file
  (expand-file-name
   "guix-helper.scm"
   (file-name-directory (or load-file-name
                            (locate-library "guix"))))
  "Scheme file used for getting info about packages.")

(defvar guix-guile-program (or geiser-guile-binary "guile")
  "Name of the guile executable used for Guix REPL.
May be either a string (the name of the executable) or a list of
strings of the form:

  (NAME . ARGS)

Where ARGS is a list of arguments to the guile program.")


;;; REPL

(defcustom guix-repl-startup-time 30000
  "Time, in milliseconds, to wait for Guix REPL to startup.
Same as `geiser-repl-startup-time' but is used for Guix REPL.
If you have a slow system, try to increase this time."
  :type 'integer
  :group 'guix)

(defcustom guix-repl-buffer-name "*Guix REPL*"
  "Default name of a Geiser REPL buffer used for Guix."
  :type 'string
  :group 'guix)

(defcustom guix-after-start-repl-hook ()
  "Hook called after Guix REPL is started."
  :type 'hook
  :group 'guix)

(defvar guix-repl-buffer nil
  "Geiser REPL buffer used for communicating with Guix.")

(defun guix-start-repl ()
  "Start Geiser REPL configured for Guix."
  ;; A mix of the code from `guix-geiser-repl--start-repl' and
  ;; `geiser-repl--to-repl-buffer'.
  (message "Starting Geiser REPL for Guix ...")
  (let ((impl 'guile)
        (geiser-guile-binary guix-guile-program)
        (geiser-guile-init-file guix-helper-file)
        (geiser-repl-startup-time guix-repl-startup-time)
        (repl (get-buffer-create guix-repl-buffer-name)))
    (with-current-buffer repl
      (geiser-repl-mode)
      (geiser-impl--set-buffer-implementation impl)
      (geiser-repl--autodoc-mode -1)
      (goto-char (point-max))
      (let* ((prompt-re (geiser-repl--prompt-regexp impl))
             (deb-prompt-re (geiser-repl--debugger-prompt-regexp impl))
             (prompt (geiser-con--combined-prompt prompt-re deb-prompt-re)))
        (or prompt-re
            (error "Oh no! Guix REPL has not been started"))
        (geiser-repl--start-scheme impl nil prompt)
        (geiser-repl--quit-setup)
        (geiser-repl--history-setup)
        (add-to-list 'geiser-repl--repls (current-buffer))
        (geiser-repl--set-this-buffer-repl (current-buffer))
        (setq geiser-repl--connection
              (geiser-con--make-connection (get-buffer-process (current-buffer))
                                           prompt-re
                                           deb-prompt-re))
        (geiser-repl--startup impl nil)
        (geiser-repl--autodoc-mode 1)
        (geiser-company--setup geiser-repl-company-p)
        (add-hook 'comint-output-filter-functions
                  'geiser-repl--output-filter
                  nil
                  t)
        (set-process-query-on-exit-flag (get-buffer-process (current-buffer))
                                        geiser-repl-query-on-kill-p)
        (setq guix-repl-buffer repl)
        (message "Guix REPL has been started.")
        (run-hooks 'guix-after-start-repl-hook)))))

(defun guix-get-repl-buffer ()
  "Return Guix REPL buffer; start REPL if needed."
  (or (get-buffer-process guix-repl-buffer)
      (guix-start-repl))
  guix-repl-buffer)

(defun guix-switch-to-repl ()
  "Switch to Guix REPL."
  (interactive)
  (geiser-repl--switch-to-buffer (guix-get-repl-buffer)))


;;; Evaluating expressions

(defun guix-make-guile-expression (fun &rest args)
  "Return string containing a guile expression for calling FUN with ARGS."
  (format "(%S %s)" fun
          (mapconcat (lambda (arg)
                       (concat (and (or (symbolp arg) (listp arg))
                                    "'")
                               (prin1-to-string arg)))
                     args
                     " ")))

(defun guix-eval (str &optional wrap)
  "Evaluate guile expression STR.
If WRAP is non-nil, wrap STR into (begin ...) form.
Return a list of strings with result values of evaluation."
  (with-current-buffer (guix-get-repl-buffer)
    (let* ((wrapped (if wrap (geiser-debug--wrap-region str) str))
           (code `(:eval (:scm ,wrapped)))
           (ret (geiser-eval--send/wait code)))
      (if (geiser-eval--retort-error ret)
          (error "Error in evaluating guile expression: %s"
                 (geiser-eval--retort-output ret))
        (cdr (assq 'result ret))))))

(defun guix-eval-read (str &optional wrap)
  "Evaluate guile expression STR.
For the meaning of WRAP, see `guix-eval'.
Return elisp expression of the first result value of evaluation."
  ;; Parsing scheme code with elisp `read' is probably not the best idea.
  (read (replace-regexp-in-string
         "#f\\|#<unspecified>" "nil"
         (replace-regexp-in-string
          "#t" "t" (car (guix-eval str wrap))))))


;;; Getting packages info

(defvar guix-search-type-alist
  '((name             . find-packages-by-spec)
    (regexp           . find-packages-by-regexp)
    (all-available    . all-available-packages)
    (newest-available . newest-available-packages))
  "Alist of available search options.
Each association has a form:

  (TYPE . FUN)

TYPE is a search type.
FUN is a name of guile function used for searching.")

(defun guix-get-packages (type vals)
  "Search for Guix packages and return results.

TYPE is a search type from `guix-search-type-alist'.
It defines a search function which is called with VALS as
arguments.

Returning value is a list of the form of `guix-packages'."
  (let ((fun (guix-get-key-val type guix-search-type-alist)))
    (or fun (error "Wrong search type '%S'" type))
    (let ((packages (guix-eval-read
                     (apply #'guix-make-guile-expression fun vals))))
      (or packages (error "Packages not found")))))

(provide 'guix-backend)

;;; guix-backend.el ends here