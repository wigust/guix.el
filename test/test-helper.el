;;; test-helper.el --- Test suite helpers.            -*- lexical-binding: t; -*-

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
(let ((default-directory (if (string-suffix-p "test/" default-directory)
                             (file-name-directory (directory-file-name default-directory))
                           default-directory))
      (load-path (cons (concat (directory-file-name default-directory) "/elisp")
                       load-path)))
  (load (concat (directory-file-name default-directory)
                "/test/guix-ui-package-tests.el")))

(provide 'test-helper)
;;; test-helper.el ends here
