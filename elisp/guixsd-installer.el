;;; guix-ui-package.el --- Interface for installing GuixSD  -*- lexical-binding: t -*-

;; Copyright © 2017 Oleg Pykhalov <go.wigust@gmail.com>

;; This file is part of Emacs-Guix.

;; Emacs-Guix is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Emacs-Guix is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Emacs-Guix.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides an interface for installing GNU GuixSD.

;;; Code:

(defcustom guixsd-about-buffer-name "*Guix About*"
  "Buffer name for '\\[guix-about]'."
  :type 'string
  :group 'guix)

(defvar guixsd-about-specifications
  `("\

                     The Guix System Distribution

                                   Liberating.  GuixSD is an advanced
                                   distribution of the GNU operating system
 :                               . developed by the GNU Project which respects
 S:                            S   the freedom of computer users.
  : 8  . . :8         t . . .  ;
     %888.   ;       :   SX8@      Dependable.  The GNU Guix package manager,
          t 8       %  .           in addition to standard package management
           .8 8     .              features, supports transactional upgrades
           .88     t  :            and roll-backs, unprivileged package
            .  t   .8              management, per-user profiles, and more.
             .  % .  8
             8   8 8               Hackable.  It provides Guile Scheme APIs,
              .  X  8              including high-level embedded domain-
              8 8@8                specific languages (EDSLs) to define
                                   packages and whole-system configurations.

                 "
    "                     "
    :link ("https://www.gnu.org/software/guix/"
           ,(lambda (button)
              (browse-url (button-label button)))
           "\n")
    "\n\n"

    "Info: " :link ("System Installation Manual"
                    ,(lambda (_button)
                       (info "(guix) System Installation")))
    "\n"
    "Chat: " :link ("#guix at freenode.net" ,(lambda (_button) (guix-help-irc))) "\n"
    "Mail: " :link ("help-guix@gnu.org" ,(lambda (_button) (guix-help-email))) "\n"

    "\n\n"

    "Installation:\n\n"
    "- Partition an installation disk with "
    :link ("cfdisk" ,(lambda (_button) (cfdisk))) ".\n"

    "- List network interfaces with "
    :link ("ifconfig" ,(lambda (_button) (ifconfig))) ".\n"

    "- Turn on network interface with "
    :link ("ifconfig INTERFACE up" ,(lambda (_button) (ifconfig-up))) ".\n"

    "- Check Internet connection with "
    :link ("ping" ,(lambda (_button) (ping-www-gnu-org))) ".\n"

    "\n\n"

    "Or run Bash and do yourself...: " :link ("M-x shell" ,(lambda (_button) (shell)))
    "\n")
  "Text to show with '\\[guixsd-about]' command.
This is not really a text, it is a list of arguments passed to
`fancy-splash-insert'.")

(defcustom partitioning-program
  (executable-find "cfdisk")
  "Name of the 'qemu' executable."
  :type 'string
  :group 'guixsd-installer)

;; TODO: apply: Wrong type argument: stringp, nil
(defun ifconfig-up (&optional interface)
  "Run ifconfig up and display diagnostic output."
  (interactive (list (read-from-minibuffer "Interface: ")))
  (let ((ifconfig-program-options (list interface "up")))
    (net-utils-run-simple
     (format "*%s*" ifconfig-program)
     ifconfig-program
     ifconfig-program-options)))

(defun ping-www-gnu-org ()
  "Ping www.gnu.org."
  (ping "www.gnu.org"))

(defun cfdisk ()
  "Run cfdisk."
  (term partitioning-program))

(defun guix-help-email ()
  "Send an email message to Guix help mailing list."
  (compose-mail "help-guix@gnu.org"))

;; TODO: Does not want to autojoin.
(defun guix-irc ()
  "Connect to Guix IRC channel with ERC."
  (let ((erc-autojoin-channels-alist (quote (("freenode.net" "#guix")))))
    (erc :server "irc.freenode.net")))

(defun guixsd-about-insert-content ()
  "Insert GuixSD 'about' info into the current buffer."
  (apply #'fancy-splash-insert guixsd-about-specifications)
  (goto-char (point-min))
  (forward-line 3))

(defun guixsd-about-show ()
  "Display 'About' buffer with fancy GuixSD logo if available.
Unlike `guixsd-about', this command always recreates
`guixsd-about-buffer-name' buffer."
  (interactive)
  (guix-help-display-buffer guixsd-about-buffer-name
                            #'guixsd-about-insert-content))

;;;###autoload
(defun guixsd-about ()
  "Display 'About' buffer with fancy GuixSD logo if available.
Switch to `guixsd-about-buffer-name' buffer if it already exists."
  (interactive)
  (guix-switch-to-buffer-or-funcall
   guixsd-about-buffer-name #'guixsd-about-show))

(provide 'guixsd-installer)

;;; guixsd-installer.el ends here
