;;; org-sort.el --- In buffer option for sorting -*- lexical-binding: t; -*-

;;; Copyright: (C) 2025 Edoardo Putti

;;; Author: Edoardo Putti <edoardo.putti@gmail.com>
;;; Maintainer: edoardo.putti@gmail.com
;;; Keywords: org
;;; Version: 0.1
;;; Package-requires: ((emacs "24.4"))

;;; Commentary:

;; This package provides automatic sorting in your org buffer according to
;; an in buffer settings.  The sorting is only applied to the top-level headings.

;;; Code:

(require 'org)

(defvar org-sort-option nil "Sorting spec for org-sort-entries.
This option is controlled by in-buffer settings.  Use #+SORT: value
in your header to set this variable to value.

Allowed values are described by the following grammar:

spec := (reverse spec)
     |  (with-case spec)
     |  (property name)
     |  alphabetical
     |  creation-time
     |  deadline
     |  clock
     |  number
     |  todo
     |  priority
     |  scheduled
     |  date
     |  time

Examples:

#+SORT: (reverse alphabetical)
#+SORT: (with-case alphabetical)
#+SORT: creation-time")

(defun org-sort-set-option (&rest r)
  "Read the +SORT: spec value into variable `org-sort-option'."
  (when (derived-mode-p 'org-mode)
    (let ((alist (org-collect-keywords '("SORT"))))
      (let ((sort (cdr (assoc "SORT" alist))))
	(when sort
	  (let ((sort-spec (car (read-from-string (car sort)))))
	    (setq-local org-sort-option sort-spec)))))))

(advice-add 'org-set-regexps-and-options :after #'org-sort-set-option)

(defun org-sort-parse ()
  (let ((case-sensitive nil)
	(sorting-type nil)
	(getkey-func nil)
	(compare-func nil)
	(property nil))
    (progn
      (named-let loop ((arg org-sort-option))
	(pcase arg
	  ('alphabetical (setq sorting-type ?a))
	  ('creation-time (setq sorting-type ?c))
	  ('deadline (setq sorting-type ?d))
	  ('clock (setq sorting-type ?k))
	  ('number (setq sorting-type ?n))
	  ('todo (setq sorting-type ?o))
	  ('priority (setq sorting-type ?p))
	  ('scheduled (setq sorting-type ?s))
	  ('date (setq sorting-type ?t))
	  ('time (setq sorting-type ?t))
	  (`(reverse ,spec)
	   (progn
	     (loop spec)
	     (setq sorting-type
		   (if (char-uppercase-p sorting-type)
		       (downcase sorting-type)
		     (upcase sorting-type)))))
	  (`(with-case ,spec)
	   (progn
	     (setq case-sensitive (not case-sensitive))
	     (loop spec)))
	  (`(property ,property-name)
	   (progn
	     (setq sorting-type ?r)
	     (setq property (symbol-name property-name))))
	  ;; matches not set option
	  (_ nil)))
      (list case-sensitive sorting-type getkey-func compare-func property nil))))

(defun org-sort-run ()
  (when (and (derived-mode-p 'org-mode) org-sort-option)
    (save-excursion
      (goto-char (point-min))
      (apply #'org-sort-entries (org-sort-parse)))))

(add-hook 'before-save-hook #'org-sort-run)

(provide 'org-sort)
;;; org-sort.el ends here
