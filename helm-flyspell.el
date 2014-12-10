;;; helm-flyspell.el -- Helm extension for correcting words with flyspell

;; Copyright (C) 2014 Andrzej Pronobis <a.pronobis@gmail.com>

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

;;; Code:

;; For lexical-let
(eval-when-compile
  (require 'cl))

;; Requires
(require 'helm)
(require 'flyspell)


(defun helm-flyspell--always-match (candidate)
  "Return true for any CANDIDATE."
  t
  )


(defun helm-flyspell--option-candidates (word)
  "Return a set of options for the given WORD."
  (let ((opts (list (cons (format "Save \"%s\"" word) 'save)
                    (cons (format "Accept (session) \"%s\"" word) 'session)
                    (cons (format "Accept (buffer) \"%s\"" word) 'buffer))))
    (unless (string= helm-pattern "")
      (setq opts (append opts (list (cons (format "Save \"%s\"" helm-pattern) 'save)
                                    (cons (format "Accept (session) \"%s\"" helm-pattern) 'session)
                                    (cons (format "Accept (buffer) \"%s\"" helm-pattern) 'buffer)
                                    ))))
    opts
    ))


(defun helm-flyspell (candidates word)
  "Run helm for the given CANDIDATES given by flyspell for the WORD."
  (helm :sources (list (helm-build-sync-source (format "Suggestions for \"%s\" in dictionary \"%s\""
                                                       word (or ispell-local-dictionary
                                                                ispell-dictionary
                                                                "Default"))
                         :candidates candidates
                         :action 'identity
                         :candidate-number-limit 9999
                         :fuzzy-match t
                         )
                       (helm-build-sync-source "Options"
                         :candidates '(lambda ()
                                        (lexical-let ((tmp word))
                                           (helm-flyspell--option-candidates tmp)))
                         :action 'identity
                         :candidate-number-limit 9999
                         :match 'helm-flyspell--always-match
                         :volatile t
                         )
                       )
        :buffer "*Helm Flyspell*"
        :prompt "Correction: "))


(defun helm-flyspell-correct ()
  "Use helm for flyspell correction.
Adapted from `flyspell-correct-word-before-point'."
  (interactive)
  ;; use the correct dictionary
  (flyspell-accept-buffer-local-defs)
  (let ((cursor-location (point))
        (word (flyspell-get-word))
        (opoint (point)))
    (if (consp word)
        (let ((start (car (cdr word)))
              (end (car (cdr (cdr word))))
              (word (car word))
              poss ispell-filter)
          ;; now check spelling of word.
          (ispell-send-string "%\n")	;put in verbose mode
          (ispell-send-string (concat "^" word "\n"))
          ;; wait until ispell has processed word
          (while (progn
                   (accept-process-output ispell-process)
                   (not (string= "" (car ispell-filter)))))
          ;; Remove leading empty element
          (setq ispell-filter (cdr ispell-filter))
          ;; ispell process should return something after word is sent.
          ;; Tag word as valid (i.e., skip) otherwise
          (or ispell-filter
              (setq ispell-filter '(*)))
          (if (consp ispell-filter)
              (setq poss (ispell-parse-output (car ispell-filter))))
          (cond
           ((or (eq poss t) (stringp poss))
            ;; don't correct word
            t)
           ((null poss)
            ;; ispell error
            (error "Ispell: error in Ispell process"))
           (t
            ;; The word is incorrect, we have to propose a replacement.
            (flyspell-do-correct (helm-flyspell (third poss) word)
                                 poss word cursor-location start end opoint)))
          (ispell-pdict-save t)))))


(provide 'helm-flyspell)
;;; helm-flyspell.el ends here
