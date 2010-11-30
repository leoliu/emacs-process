;;; emacs-process.el --- list processes by Emacs

;; Author: Leo <sdl.web@gmail.com>
;; Keywords: processes, tools

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; My attempt to move the primitive list-processes to elisp.

;;; Code:

(eval-when-compile (require 'cl))

(defvar emacs-process-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\C-k" 'emacs-process-delete)
    (define-key m "n" 'next-line)
    (define-key m "p" 'previous-line)
    (define-key m "g" 'emacs-process-list)
    (define-key m "q" 'quit-window)
    m))

(defun emacs-process-delete (name)
  (interactive
   (list (let ((def (get-text-property (point) 'process-name)))
           (completing-read (if def
                                (format "Delete process (default %s): " def)
                              "Delete process: ")
                            (mapcar 'process-name (process-list))
                            nil t nil nil def))))
  (delete-process name)
  (emacs-process-list))

(define-derived-mode emacs-process-mode fundamental-mode "Emacs Processes"
  (setq buffer-read-only t)
  (easy-menu-define
    emacs-process-menu emacs-process-mode-map "Emacs Process Menu"
    `("Processes"
      ["Next line" next-line]
      ["Previous line" previous-line]
      ["Update" emacs-process-list :help "Update process list"]
      ["Quite" quit-window]
      ,@(when (process-list)
          `(("Delete"
             ,@(mapcar (lambda (p)
                         (vector (process-name p) (list 'emacs-process-delete p)
                                 :help (format "Delete process %s" p)))
                       (process-list))))))))

(defun emacs-process-info (&optional query-only)
  "Return a list of plist of process information."
  (delete nil
          (mapcar (lambda (p)
                    (when (or (not query-only)
                              (and query-only (process-query-on-exit-flag p)))
                      (list :proc (process-name p)
                            :status (symbol-name (process-status p))
                            :buffer (let ((buf (process-buffer p)))
                                      (cond
                                       ((null buf) "(none)")
                                       ((not (buffer-live-p buf)) "(Killed)")
                                       (t (buffer-name buf))))
                            :tty (process-tty-name p)
                            :command (case (process-type p)
                                       (network (destructuring-bind
                                                    (&key server type service host
                                                          &allow-other-keys)
                                                    (process-contact p t)
                                                  (format "(network %s %s)"
                                                          (if type "datagram" "stream")
                                                          (if server
                                                              (format "server on %s" service)
                                                            (format "connection to %s" host)))))
                                       (serial (destructuring-bind
                                                   (&key port speed &allow-other-keys)
                                                   (process-contact p t)
                                                 (format "(serial port %s%s)"
                                                         (or port "?")
                                                         (if speed
                                                             (format " at %s b/s" speed)
                                                           ""))))
                                       (otherwise (mapconcat 'identity (process-command p) " "))))))
                  (process-list))))

(defun emacs-process-compute-widths (info)
  "Compute the width of each column."
  (loop for (key value) on (car info) by 'cddr
        for pwidth = (loop for i in info
                           maximize (length (plist-get i key)))
        ;; don't display column with width zero
        collect (if (zerop pwidth)
                    0
                  (max pwidth (1- (length (symbol-name key)))))))

;;; Note: the key of the plist is used as heading
(defun emacs-process-insert (info)
  (let ((widths (emacs-process-compute-widths info))
        (index 0) beg)
    (while info
      (incf index)
      (setq beg (point))
      (loop for (k v) on (car info) by 'cddr
            for h = (substring (symbol-name k) 1)
            ;; use a small nonzero value for last column
            for w in (append (butlast widths) '(1))
            for curcol = (current-column)
            unless (zerop w)
            do
            (case index
              (1 (insert (capitalize h)))
              (2 (insert (make-string (length h) ?-)))
              (otherwise (and v (insert v))))
            (indent-to (+ curcol w))
            ;; insert a space between each column
            (insert " "))
      (insert "\n")
      (when (> index 2)
        (put-text-property beg (point) 'process-name
                           (plist-get (car info) :proc))
        (pop info)))))

;;;###autoload
(defalias 'list-processes 'emacs-process-list)
;;;###autoload
(defun emacs-process-list (&optional query-only)
  "Display a list of all processes.
If optional argument QUERY-ONLY is non-nil, only processes with
the query-on-exit flag set will be listed.
Any process listed as exited or signaled is actually eliminated
after the listing is made."
  (interactive "P")
  (let ((info (emacs-process-info query-only))
        (inhibit-read-only t)
        line)
    (if info
        (with-current-buffer (get-buffer-create "*Process List*")
          (setq line (line-number-at-pos))
          (erase-buffer)
          (emacs-process-insert info)
          (set-buffer-modified-p nil)
          (emacs-process-mode)
          (goto-char (point-min))
          (forward-line (1- line))
          (display-buffer (current-buffer)))
      (when (get-buffer "*Process List*")
        (kill-buffer "*Process List*"))
      (message "Process list empty"))))

(provide 'emacs-process)
