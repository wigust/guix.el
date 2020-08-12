;;; guix-ui-package-tests.el --- Test suite for guix-ui-package.  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Oleg Pykhalov

;; Package-Requires: ((el-mock "1.25.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:
(require 'ert)
(require 'el-mock)
(require 'guix-ui-package)

(ert-deftest guix-ui-package-installed-packages-test ()
  (with-mock
   (stub guix-output-list-get-entries =>
         '(((id . "139789064696928:out")
            (output . "out")
            (installed . t)
            (package-id . 139789064696928)
            (name . "emacs")
            (version . "26.3")
            (synopsis . "The extensible, customizable, self-documenting text editor\n\n")
            (hidden)
            (known-status . known)
            (superseded))
           ((id . "139789100328352:out")
            (output . "out")
            (installed . t)
            (package-id . 139789100328352)
            (name . "emacs-academic-phrases")
            (version . "0.1-1.0823ed8")
            (synopsis . "Bypass that mental block when writing your papers\n\n")
            (hidden)
            (known-status . known)
            (superseded))))
   (should (progn
            (guix-installed-packages)
            (= (length "\n\n")
               (seq-count (lambda (string)
                            (eq ?\n string))
                          (buffer-string)))))))

(provide 'guix-ui-package-tests)
;;; guix-ui-package-tests.el ends here
