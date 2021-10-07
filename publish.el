(setq package-enable-at-startup nil)

(defconst my/current-dir
  (if load-file-name
      (file-name-directory load-file-name)
    (expand-file-name ".")))

(defconst my/emacs-dir
  ;;; Customized `user-emacs-directory', used for several separate configurations.
  (let ((user-dir (getenv "EMACS_USER_DIRECTORY")))
    (if user-dir
        user-dir
      (expand-file-name ".emacs.d" my/current-dir))))

(defconst my/org-dir
  ;;; Org files directory
  (expand-file-name "org" my/current-dir))

(setq straight-base-dir (expand-file-name "straight" my/emacs-dir))
(unless (file-exists-p straight-base-dir)
  (make-directory straight-base-dir t))
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" straight-base-dir))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(setq org-id-locations-file (expand-file-name ".org-id-locations" my/emacs-dir))
(use-package org-roam
  :straight t
  :init
  (setq org-roam-directory my/org-dir)
  (setq org-roam-db-location (expand-file-name "org-roam.db" my/org-dir))
  (setq org-roam-v2-ack t)
  (org-roam-db-autosync-mode)
  (unless (file-exists-p org-id-locations-file)
    (let ((org-id-files (org-roam--list-files org-roam-directory))
          org-agenda-files)
      (org-id-update-id-locations))))

(use-package ox-hugo
  :straight (ox-hugo :type git :host github :repo "kaushalmodi/ox-hugo"
                     :fork (:host github
                                  :repo "jethrokuan/ox-hugo")))

(defun publish (file)
  (with-current-buffer (find-file-noselect file)
    (setq org-hugo-base-dir my/current-dir)
    (org-hugo-export-wim-to-md)))

(defun publish-all ()
  (let* ((all-org-files (file-expand-wildcards (expand-file-name "*.org" my/org-dir))))
    (dolist (f all-org-files)
      (publish f))))
