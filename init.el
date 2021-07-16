;;; Startup
;; Minimize garbage collection during startup
(setq gc-cons-threshold most-positive-fixnum)

;; Lower threshold back to 8 MiB (default is 800kB)
(add-hook 'emacs-startup-hook
	  (lambda ()
	    (setq gc-cons-threshold (expt 2 23))))
;;; PACKAGE LIST
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
	("org" . "https://orgmode.org/elpa/")
	("elpa" . "https://elpa.gnu.org/packages/")))

;;; BOOTSTRAP USE-PACKAGE
(package-initialize)

(setq use-package-always-ensure t)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;;; ASYNC

;;;; Emacs look SIGNIFICANTLY less often which is a good thing.
;;;; asynchronous bytecode compilation and various other actions makes

(use-package async
  :ensure t
  :defer t
  :init
  (dired-async-mode 1)
  (async-bytecomp-package-mode 1)
  :custom (async-bytecomp-allowed-packages '(all)))

;;; MY STUFF
(setq gv/is-termux
      (string-suffix-p
       "Android" (string-trim (shell-command-to-string "uname -a"))))

(defun gv/read ()
  "text to speech"
  (interactive)
  (async-shell-command
   (concat "tts.sh '" (x-get-clipboard)"'")))
(defun gv/sudo-save ()
  "save this file as super user"
  (interactive)
  (if (not buffer-file-name)
      (write-file (concat "/sudo:root@localhost:" (read-file-name "File:")))
    (write-file (concat "/sudo:root@localhost:" buffer-file-name))))

(defun gv/stars ()
  "prompt user on of my github stars or my repos"
  (interactive)
  (start-process-shell-command "Stars" nil "stars"))

;;; Modal Bindings
;; Vim style undo
(use-package undo-fu
  :init (global-unset-key (kbd "C-/"))
  :bind (;; I hate it when I accidentl
	 ("C-/" . undo-fu-only-undo)
	 ("C-?" . undo-fu-only-redo)))
(use-package undo-fu-session
  :after undo-fu
  :init
  (global-undo-fu-session-mode))

(use-package crux
  :bind (("C-a" . crux-move-beginning-of-line)
	 ;; Remove whitespace when killing at the end of a line
	 ("C-k" . crux-kill-and-join-forward)
	 ("C-c C-e" . crux-eval-and-replace)
	 ;; Since C-j is so similar
	 ("C-S-o" . crux-smart-open-line-above)
	 ("C-o" . crux-smart-open-line)
	 ("C-c v" . crux-swap-windows)))

;; TODO look into `repeat-mode' in emacs 28
;; for visual selection style use C-x SPC
(use-package god-mode
  :defer t
  :bind (("<escape>" . god-mode-all)
	 ("C-x ["    . previous-buffer)
	 ("C-x ]"    . next-buffer)
	 ("C-c C-d"  . cd)
	 ("C-z"      . repeat)
	 ("M-g C-n"  . isearch-repeat-forward)
	 ("M-g C-p"  . isearch-repeat-backward)
	 :map god-local-mode-map
	 ("{" . pop-global-mark)
	 ("}" . unpop-to-mark-command)
	 ("f" . forward-word) ; move FASTER
	 ("b" . backward-word)
	 ("]" . forward-list)
	 ("[" . backward-list)
	 ("v" . set-mark-command)
	 :map minibuffer-local-map
	 ;; I don't use god-mode in the minibuffer
	 ("<escape>" . 'keyboard-escape-quit))
  :config
  ;; exclude eaf from god mode
  (add-to-list 'god-exempt-major-modes 'eaf-mode)
  (add-to-list 'god-exempt-major-modes 'exwm-mode)
;;;; Mark Ring
    (defun unpop-to-mark-command ()
    "Unpop off mark ring. Does nothing if mark ring is empty."
    (interactive)
    (when mark-ring
      (let ((pos (marker-position (car (last mark-ring)))))
	(if (not (= (point) pos))
	    (goto-char pos)
	  (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
	  (set-marker (mark-marker) pos)
	  (setq mark-ring (nbutlast mark-ring))
	  (goto-char (marker-position (car (last mark-ring))))))))
;;;; Cursor shape
  (defun my-god-mode-update-cursor-type ()
    (setq cursor-type (if (or god-local-mode buffer-read-only) 'box 'bar)))
  (add-hook 'post-command-hook #'my-god-mode-update-cursor-type)
;;;; Fix terminal escape
  ;; For whatever reason terminals have trouble recognizing escape
  ;; form emacs properly. Found this solution at
  ;; https://github.com/emacsorphanage/god-mode/issues/43
  (defvar gv/fast-keyseq-timeout 200)

  (defun gv/-tty-ESC-filter (map)
    (if (and (equal (this-single-command-keys) [?\e])
	     (sit-for (/ gv/fast-keyseq-timeout 1000.0)))
	[escape] map))

  (defun gv/-lookup-key (map key)
    (catch 'found
      (map-keymap (lambda (k b) (if (equal key k) (throw 'found b))) map)))

  (defun gv/catch-tty-ESC ()
    "Setup key mappings of current terminal to turn a tty's ESC into `escape'."
    (when (memq (terminal-live-p (frame-terminal)) '(t pc))
      (let ((esc-binding (gv/-lookup-key input-decode-map ?\e)))
	(define-key input-decode-map
	  [?\e] `(menu-item "" ,esc-binding :filter gv/-tty-ESC-filter)))))

  (gv/catch-tty-ESC))

(use-package multiple-cursors
  :bind (("C-<" . mc/mark-previous-like-this)
	 ("C->" . mc/mark-next-like-this)
	 ("C-x C->" . mc/mark-all-like-this)))
;;; Extending Selection
;; Expand region is useful for adding iw aw style selection to emacs
;; TODO find a better alternative so I can put this in usepackage

(define-key global-map (kbd "C-c a") (make-sparse-keymap))
(define-key global-map (kbd "C-c i") (make-sparse-keymap))
(use-package expand-region
  :bind (("C-;"      . er/expand-region)
	 ("C-c a w"  . er/mark-word)
	 ("C-c a \"" . er/mark-outside-quotes)
	 ("C-c a q"  . er/mark-outside-quotes)
	 ("C-c a )"  . er/mark-outside-pairs)
	 ("C-c a b"  . er/mark-outside-pairs)
	 ("C-c a t"  . er/mark-outer-tag)
	 ("C-c i w"  . er/mark-word)
	 ("C-c i \"" . er/mark-inside-quotes)
	 ("C-c i q"  . er/mark-inside-quotes)
	 ("C-c i )"  . er/mark-inside-pairs)
	 ("C-c i b"  . er/mark-inside-pairs)
	 ("C-c i t"  . er/mark-inner-tag)))

;;; TERMINAL SETTINGS
(if (display-graphic-p)
    (set-face-background 'default "#000000")
  (progn (set-face-background 'default "undefinded")
	 (add-to-list 'term-file-aliases
		      '("st-256color" . "xterm-256color"))
	 (xterm-mouse-mode t))
	(global-set-key (kbd "<mouse-4>") 'next-line)
	(global-set-key (kbd "<mouse-5>") 'previous-line))

;;; COMPLETION
(use-package vertico
  :init
  (use-package marginalia
    :custom
    (marginalia-annotators
     '(marginalia-annotators-heavy marginalia-annotators-light nil))
    :init
    (marginalia-mode))
;;;; Out Of Order Compleiton
  (use-package orderless
    :commands (orderless)
    :custom (completion-styles '(orderless)))
;;;; Extra Completion Functions
  ;; Note that M-sn is used for searghing ang
  (use-package consult
    :bind (("C-c l"	. consult-line)
	   ("C-c i"	. consult-imenu)
	   ("C-c o"	. consult-outline)
	   ("C-x C-k C-k" . consult-kmacro))
    :custom
    (completion-in-region-function #'consult-completion-in-region)
    :config
    (add-hook 'completion-setup-hook #'hl-line-mode))
;;;; Fuzzy Finding
  (use-package affe
    :bind (("C-c n" . gv/notegrep)
	   ("C-c f" . affe-find)
	   ("C-c g" . affe-grep))
    :commands (affe-grep affe-find)
    :config
    ;; only exclude git files
    (setq affe-find-command
	  (concat "find  "
		  "-not -path '*/\\.nnn*' -not -path '*/\\.git*' "
		  "-type f"))
    ;; Configure Orderless
    (setq affe-regexp-function #'orderless-pattern-compiler
	  affe-highlight-function #'orderless--highlight)

    ;; Manual preview key for `affe-grep'
    (consult-customize affe-grep :preview-key (kbd "M-."))
    (defun gv/notegrep ()
      (interactive)
      (affe-grep org-directory)))
  (vertico-mode)
  :config
  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
	'(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t))

;;; THEMEING
(use-package ujelly-theme
  :ensure nil
  :config
  (load-theme 'ujelly t)
  (set-frame-parameter (selected-frame) 'alpha '(90 90))
  (add-to-list 'default-frame-alist '(alpha 90 90))
  (set-face-attribute 'region nil :background "#666" :foreground "#ffffff")

  ;; (set-face-attribute 'mode-line nil :foreground "#bdc3ce" :background "#000")
  (set-face-attribute 'default nil :background "#000" :foreground "#eee"))

;;; Aligning Text
(use-package align
  :ensure nil
  :bind ("C-x C-a" . align-regexp)
  :config
  (defadvice align-regexp (around align-regexp-with-spaces activate)
    (let ((indent-tabs-mode nil))
      ad-do-it)))

;;; WRITING
(use-package writegood-mode
  :hook (flyspell-mode . writegood-mode))
(use-package flyspell-correct
  :bind ("C-c DEL" . flyspell-correct-previous)
  :hook ((org-mode mu4e-compose-mode mail-mode git-commit-mode)
	 . turn-on-flyspell))

;;; ORG
(if gv/is-termux
    (setq org-directory "~/storage/shared/Dropbox/Documents/org")
  (setq org-directory "~/Documents/org"))
(use-package org
  :pin org
  :ensure org-plus-contrib
  :commands (org-capture org-agenda)
  :bind (("C-c y" . org-store-link)
	 ("C-c c" . org-capture)
	 ("C-c a" . org-agenda))
  :config
;;;; Archive Completed Tasks
  (defun my-org-archive-done-tasks ()
    (interactive)
      (org-map-entries 'org-archive-subtree "/DONE" 'file)
      (org-map-entries 'org-archive-subtree "/CANCELLED" 'file))
;;;; Better defaults
  (setq org-ellipsis " ▾"
	org-hide-emphasis-markers t
	org-special-ctrl-a/e t
	org-src-fontify-natively t
	org-fontify-quote-and-verse-blocks t
	org-src-tab-acts-natively t
	org-edit-src-content-indentation 2
	org-hide-block-startup nil
	org-src-preserve-indentation nil
	org-startup-folded 'content
	org-cycle-separator-lines 2)

  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-todo-keywords
	'((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
	  (sequence "BACKLOG(b)" "PLAN(p)" "READY(r)" "ACTIVE(a)" "REVIEW(v)" "WAIT(w@/!)" "HOLD(h)" "|" "DELEGATED(D)" "CANCELLED(c)")))

;;;; Agenda Views
  (setq org-agenda-custom-commands
	'(("d" "Today's Tasks"
	   ((agenda "" ((org-agenda-span 1)
			(org-agenda-overriding-header "Today's Tasks")))))
	  ;; ("d" "Dashboard"
	  ;;  ((agenda "" ((org-deadline-warning-days 7)))
	  ;;   (todo "NEXT"
	  ;;	  ((org-agenda-overriding-header "Next Tasks")))
	  ;;   (tags-todo "agenda/ACTIVE" ((org-agenda-overriding-header "Active Projects")))))

	  ("n" "Next Tasks"
	   ((todo "NEXT"
		  ((org-agenda-overriding-header "Next Tasks")))))

	  ("W" "Work Tasks" tags-todo "+work")

	  ;; Low-effort next actions
	  ("e" tags-todo "+TODO=\"NEXT\"+Effort<15&+Effort>0"
	   ((org-agenda-overriding-header "Low Effort Tasks")
	    (org-agenda-max-todos 20)
	    (org-agenda-files org-agenda-files)))))
;;;; Capture
  (setq org-default-notes-file (concat org-directory "/refile.org"))
  (setq org-capture-templates
	'(("t" "Todo" entry (file (lambda () (concat org-directory "/refile.org")))
	   "* TODO %?\nDEADLINE: %T\n  %a")
	  ("M" "movie" entry (file+headline (lambda () (concat org-directory "/Work.org")) "Meetings")
	   "* Meeting with  %?\nSCHEDULED: %T\n")
	  ("m" "Meeting" entry (file+headline (lambda () (concat org-directory "/Work.org")) "Meetings")
	   "* Meeting with  %?\nSCHEDULED: %T\n")
	  ("r" "Refund" entry (file+olp (lambda () (concat org-directory "/Work.org"))
					"Work" "Refunds")
	   "* TODO Refund %?\n%?  %a\n")
	  ("w" "Waitlist" entry (file+olp (lambda () (concat org-directory "/Work.org"))
					  "Work" "Waitlist")
	   "* %?\n%? %a\n")
	  ("v" "Video Idea" entry (file+olp (lambda () (concat org-directory "/youtube.org"))
					    "YouTube" "Video Ideas")
	   "* %?\n%? %a\n")
	  ("c" "Cool Thing" entry (file+opl+datetree (lambda () (concat org-directory "/archive.org")))
	   "* %?\nEntered on %U\n  %i\n  %a")))
;;;; Refile targets
  (setq org-refile-targets
	'(("Work.org"    :maxlevel . 3)
	  ("archive.org" :maxlevel . 3)
	  ("mylife.org"  :maxlevel . 3)))
  (advice-add 'org-refile :after 'org-save-all-org-buffers)
;;;; Font Sizes
  (dolist (face '((org-level-1 . 1.05)
		  (org-level-2 . 1.05)
		  (org-level-3 . 1.05)
		  (org-level-4 . 1.05)))
    (set-face-attribute (car face) nil :font "RobotoMono Nerd Font" :weight 'medium :height (cdr face))))

;;;; Drag And Drop
(use-package org-download
  :unless gv/is-termux
  :bind ("s-i" . org-download-screenshot)
  :hook ((org-mode dired-mode) . org-download-enable)
  :init
  (setq org-agenda-files (seq-filter (lambda (x) (not (string-match "completed.org" x)))
				     (directory-files-recursively org-directory "\\.org$")))
  (setq-default org-download-screenshot-method "gnome-screenshot -a -f %s")
  (setq-default org-download-image-dir "./pic"))
;;;; Better Looking Bullets
(use-package org-superstar
  :when (display-graphic-p)
  :hook (org-mode . org-superstar-mode))

;;;; Templates
(use-package org-tempo
  :ensure nil
  :defer t
  :config
  (add-to-list 'org-structure-template-alist '("sh"  . "src sh"))
  (add-to-list 'org-structure-template-alist '("el"  . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("vim"  . "src vim")))
;;;; Indentation
(use-package org-indent
  :ensure nil
  :defer t)

;;; Git
(use-package magit
  :bind ("C-x g" . magit-status)
  :commands magit)

(use-package diff-hl
  :unless gv/is-termux
  :defer t
  :init (global-diff-hl-mode))
;;; Completion
(use-package company
  :defer t
  :config
  (global-company-mode nil)
  (setq company-idle-delay 0.1
	company-minimum-prefix-length 1))

;;; VTERM AND ESHELL
(use-package vterm
  :commands vterm
  :custom (vterm-max-scrollback 10000))

(use-package esh-autosuggest
  :hook eshell-mode) ;company for eshell

(use-package em-alias
  :ensure nil
  :hook eshell-mode
  :config
  (add-hook 'eshell-mode-hook
	    (lambda ()
	      (eshell/alias "e" "find-file $1")
	      (eshell/alias "ee" "find-file-other-window $1"))))

(use-package fish-completion
  :hook eshell-mode
  :when (executable-find "fish")
  :config (global-fish-completion-mode))

;;; LANGS
(use-package fennel-mode
  :mode "\\.fnl\\'")
(use-package racket-mode
  :mode "\\.rkt\\'")

;;; TREE-SITTER
;; Tree-sitter support
(use-package tree-sitter
  :commands (tree-sitter-mode))
;; install the tree-sitter grammars
(use-package tree-sitter-langs
  :after tree-sitter)

;;; LSP
(use-package eglot
  :commands eglot
  :hook ((java-mode c-mode-common) . eglot-ensure)
  :config
  (defconst my/eclipse-jdt-home "/usr/share/java/jdtls/plugins/org.eclipse.equinox.launcher.gtk.linux.x86_64_1.2.200.v20210406-1409.jar")

(defun my/eclipse-jdt-contact (interactive)
  (let ((cp (getenv "CLASSPATH")))
    (setenv "CLASSPATH" (concat cp ":" my/eclipse-jdt-home))
    (unwind-protect
        (eglot--eclipse-jdt-contact nil)
      (setenv "CLASSPATH" cp))))

(setcdr (assq 'java-mode eglot-server-programs) #'my/eclipse-jdt-contact)
  (add-to-list 'eglot-server-programs '(c-mode . ("ccls")))
  (add-to-list 'eglot-server-programs '(java-mode . ("jdtls"))))

;; As the built-in project.el support expects to use vc-mode hooks to
;; find the root of projects we need to provide something equivalent
;; for it.
(use-package project
  ;; Cannot use :hook because 'project-find-functions does not end in -hook
  ;; Cannot use :init (must use :config) because otherwise
  ;; project-find-functions is not yet initialized.
  :ensure nil
  :defer t
  :config
  (defun my-git-project-finder (dir)
    "Integrate .git project roots."
    (let ((dotgit (and (setq dir (locate-dominating-file dir ".git"))
		       (expand-file-name dir))))
      (and dotgit
	   (cons 'transient (file-name-directory dotgit)))))
  (add-hook 'project-find-functions 'my-git-project-finder)) ; [built-in] Project Managment

;;; BUFFER MANAGMENT
(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :hook (ibuffer-mode . hl-line-mode)
  :config
  (setq ibuffer-expert t)
  (setq ibuffer-show-empty-filter-groups nil)
  ;; Use human readable Size column instead of original one
  (define-ibuffer-column size-h
    (:name "Size" :inline t)
    (cond
     ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
     ((> (buffer-size) 100000) (format "%7.0fk" (/ (buffer-size) 1000.0)))
     ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
     (t (format "%8d" (buffer-size)))))

;; Modify the default ibuffer-formats
  (setq ibuffer-formats
	'((mark modified read-only " "
		(name 18 18 :left :elide)
		" "
		(size-h 9 -1 :right)
		" "
		(mode 16 16 :left :elide)
		" "
		filename-and-process)))
  (setq ibuffer-saved-filter-groups
      '(("home"
	 ("Qutebrowser" (name . "qutebrowser"))
	 ("emacs-config" (or (filename . ".emacs.d")
			     (filename . "emacs-config")))
	 ("Org" (or (mode . org-mode)
		    (filename . "OrgMode")))
	 ("Web Dev" (or (mode . html-mode)
			(mode . css-mode)))
	 ("Magit" (name . "\*magit"))
	 ("Help" (or (name . "\*Help\*")
		     (name . "\*Apropos\*")
		     (name . "\*info\*")))
	 ("Browser" (mode . eaf-mode)))))
  (add-hook 'ibuffer-mode-hook
	  '(lambda ()
	     (ibuffer-switch-to-saved-filter-groups "home")))) ; [built-in] Powerful interface for managing buffers

;;; ISEARCH
(use-package isearch
  :ensure nil
  :commands (isearch-forward isearch-backward)
  :config
  (setq search-whitespace-regexp ".*?"))
;;; DEFAULTS
(use-package emacs
  :ensure nil
  :config
  (push '(truncation nil nil) ;; no truncation indicators
        fringe-indicator-alist)
  (set-frame-font "Liberation Mono 14" nil t)
  (set-frame-font "RobotoMono Nerd Font 14" nil t)
;;;; Backups
  (setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
	vc-make-backup-files t
	version-control t
	kept-old-versions 0
	kept-new-versions 10
	delete-old-versions t
	backup-by-copying t)
;;;; Defaults
  (setq delete-by-moving-to-trash t
	create-lockfiles nil
	auto-save-default nil
	inhibit-startup-screen t
	ring-bell-function 'ignore)
;;;; UTF-8
  (prefer-coding-system 'utf-8)
  (setq locale-coding-system 'utf-8)
  (set-language-environment "UTF-8")
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (set-selection-coding-system 'utf-8)
;;;; Remove Extra Ui
  (blink-cursor-mode -1)
  (menu-bar-mode -1)               ; To disable the menu bar, place the following line in your .emacs file:
  (unless gv/is-termux
    (scroll-bar-mode -1))          ; To disable the scroll bar, use the following line:
  (tool-bar-mode -1)               ; To disable the toolbar, use the following line:
  (fset 'yes-or-no-p 'y-or-n-p)    ; don't ask to spell out "yes"
  (show-paren-mode 1)              ; Highlight parenthesis
  (setq x-select-enable-primary t) ; use primary as clipboard in emacs
  ;; avoid leaving a gap between the frame and the screen
  (setq-default frame-resize-pixelwise t)
;;;; Vim like scrolling
  (setq scroll-step            1
	scroll-conservatively  10000)
  ;; move by logical lines rather than visual lines (better for macros)
  (setq line-move-visual nil))

(use-package autorevert
  :ensure nil
  :defer t
  :init (global-auto-revert-mode t))

;; Good speed and allow scrolling through large images (pixel-scroll).
;; Note: Scroll lags when point must be moved but increasing the number
;;       of lines that point moves in pixel-scroll.el ruins large image
;;       scrolling. So unfortunately I think we'll just have to live with
;;       this.
(use-package pixel-scroll
  :ensure nil
  :defer t
  :unless gv/is-termux
  :config
  (pixel-scroll-mode)
  (setq pixel-dead-time 0 ; Never go back to the old scrolling behaviour.
	;; Scroll by number of pixels instead of lines (t = frame-char-height pixels).
	pixel-resolution-fine-flag t
	;; Distance in pixel-resolution to scroll each mouse wheel event.
	mouse-wheel-scroll-amount '(1)
	;; Progressive speed is too fast for me.
	mouse-wheel-progressive-speed nil))

(use-package savehist
  :defer t
  :init (savehist-mode t)) ; Save command history

(use-package hippie-exp
  :bind ([remap dabbrev-expand] . hippie-expand)
  :commands (hippie-expand)
  :config
  (setq hippie-expand-try-functions-list
	'(try-expand-dabbrev
	  try-expand-dabbrev-all-buffers
	  try-expand-dabbrev-from-kill
	  try-complete-lisp-symbol-partially
	  try-complete-lisp-symbol
	  try-complete-file-name-partially
	  try-complete-file-name
	  try-expand-all-abbrevs
	  try-expand-list
	  try-expand-line)))

;;; FOLDING
;;;; Cycle Headings With Bicycle
(use-package outline
  :ensure nil
  :bind (:map outline-minor-mode-map
	      ("C-c C-n" . outline-next-visible-heading)
	      ("C-c C-p" . outline-previous-visible-heading)
	      ("C-c C-f" . outline-forward-same-level)
	      ("C-c C-b" . outline-backward-same-level)
	      ("C-c C-a" . outline-show-all)
	      ("C-c C-o" . outline-hide-other)
	      ("C-c C-u" . outline-up-heading)))

(use-package bicycle
  :after god-mode
  :hook outline-minor-mode-hook
  :bind (:map outline-minor-mode-map
	 ("C-<tab>" . bicycle-cycle)
	 ("<backtab>" . bicycle-cycle-global)
	 :map god-local-mode-map
	 ("<tab>" . bicycle-cycle)))

(use-package outline-minor-faces
  :hook (emacs-lisp-mode . outline-minor-faces-add-font-lock-keywords))


;;;; Setup Folding For Programming
(use-package prog-mode
  :ensure nil
  :config
  (add-hook 'emacs-lisp-mode-hook 'prettify-symbols-mode)
  (add-hook 'prog-mode-hook 'outline-minor-mode)
  (add-hook 'prog-mode-hook 'hs-minor-mode))

;;; EXTRA UI
;;;; Beacon
(use-package beacon
  :defer t
  :init (beacon-mode 1)); Highlight cursor postion after movement
;;;; Display hex colors in emacs
(use-package rainbow-mode
  :defer t
  :init (rainbow-mode t))

;;; DIRED
(use-package dired
  :ensure nil
  :config
  (setq dired-listing-switches "-aghoA --group-directories-first")
  (add-hook 'dired-mode-hook #'hl-line-mode)
;;;;; Hide . and .. in dired
  (setq dired-omit-files
	(rx (or (seq bol (? ".") "#")
		(seq bol "." eol)
		(seq bol ".." eol))))

  (add-hook 'dired-mode-hook 'dired-omit-mode)
  (add-hook 'dired-mode-hook 'dired-hide-details-mode)
;;;;; xdg-open integration
  (require 'dired-x)
  (defun gv/dired-xdg-open ()
    "Open the file at point with xdg-open."
    (interactive)
    (let ((file (dired-get-filename nil t)))
      (message "Opening %s..." file)
      (call-process "xdg-open" nil 0 nil file)
      (message "Opening %s done" file)))
  (define-key dired-mode-map (kbd "O") 'gv/dired-xdg-open))

;;; EMAIL
(use-package mu4e
  :unless gv/is-termux
  :load-path "/usr/share/emacs/site-lisp/mu4e"
  :ensure nil
  :commands (mu4e mu4e-compose-new)
  :bind ("C-x m" . mu4e-compose-new)
  :config
  ;; This is set to 't' to avoid mail syncing issues when using mbsync
  (setq mu4e-change-filenames-when-moving t)

  ;; Show full email address
  (setq mu4e-view-show-addresses 't)

  ;; where to put attachemnts
  (setq mu4e-attachment-dir  "~/Downloads")

  ;; use mu4e for e-mail in emacs
  (setq mail-user-agent 'mu4e-user-agent)

  (setq mu4e-maildir "~/.local/share/mail")

  ;; This prevents saving the email to the Sent folder since gmail will do this for us on their end.
  (setq mu4e-sent-messages-behavior 'delete)
  (setq message-kill-buffer-on-exit t)

;;;; Attachment reminders
  (use-package message-attachment-reminder)

;;;; mbsync and msmtp setup
  (setq mu4e-get-mail-command "mailsync"
	sendmail-program "/usr/bin/msmtp"
	message-sendmail-extra-arguments '("--read-envelope-from")
	send-mail-function 'smtpmail-send-it
	message-sendmail-f-is-evil t
	message-send-mail-function 'message-send-mail-with-sendmail)

  ;;images in emails
  (setq mu4e-view-show-images t)
;;;; Abbreviations
  (define-abbrev-table 'mu4e-compose-mode-abbrev-table
    '(("sin" "Sincerely, \nGavin Jaeger-Freeborn" nil 1)))
  (add-hook 'mu4e-compose-mode-hook #'abbrev-mode)
  (add-to-list 'auto-mode-alist '("^/tmp/neomutt.*\\'" . mail-mode))

;;;; Accounts
  (setq mu4e-contexts
	(list
	 ;; Personal account
	 (make-mu4e-context
	  :name "Personal"
	  :match-func
	  (lambda (msg)
	    (when msg
	      (string-prefix-p "/personal" (mu4e-message-field msg :maildir))))
	  :vars '((user-mail-address                . "gavinfreeborn@gmail.com")
		  (user-full-name                   . "Gavin Jaeger-Freeborn")
		  (mu4e-drafts-folder               . "/personal/[Gmail].Drafts")
		  (mu4e-sent-folder                 . "/personal/[Gmail].Sent Mail")
		  (mu4e-refile-folder               . "/personal/[Gmail].All Mail")
		  (mu4e-trash-folder                . "/personal/[Gmail].Trash")))

	 ;; Info Work account
	 (make-mu4e-context
	  :name "Info"
	  :match-func
	  (lambda (msg)
	    (when msg
	      (string-prefix-p "/info" (mu4e-message-field msg :maildir))))
	  :vars '((user-mail-address                . "info@flatwaternorth.ca")
		  (user-full-name                   . "Gavin Jaeger-Freeborn")
		  (mu4e-drafts-folder               . "/info/[Gmail].Drafts")
		  (mu4e-sent-folder                 . "/info/[Gmail].Sent Mail")
		  (mu4e-refile-folder               . "/info/[Gmail].All Mail")
		  (mu4e-trash-folder                . "/info/[Gmail].Trash")))

	 ;; Coach Work account
	 (make-mu4e-context
	  :name "Coach"
	  :match-func
	  (lambda (msg)
	    (when msg
	      (string-prefix-p "/coach" (mu4e-message-field msg :maildir))))
	  :vars '((user-mail-address                . "coach@flatwaternorth.ca")
		  (user-full-name                   . "Gavin Jaeger-Freeborn")
		  (mu4e-drafts-folder               . "/coach/[Gmail].Drafts")
		  (mu4e-sent-folder                 . "/coach/[Gmail].Sent Mail")
		  (mu4e-refile-folder               . "/coach/[Gmail].All Mail")
		  (mu4e-trash-folder                . "/coach/[Gmail].Trash")))))
;;;; Contacts
  (setq mail-personal-alias-file  "~/.config/mutt/aliases")
  (setq mu4e-org-contacts-file  (concat org-directory "/contacts.org"))
  (add-to-list 'mu4e-headers-actions
	       '("org-contact-add" . mu4e-action-add-org-contact) t)
  (add-to-list 'mu4e-view-actions
	       '("org-contact-add" . mu4e-action-add-org-contact) t)
;;;; Bookmarks
  (setq mu4e-bookmarks '((:name "To Handle"
				:query "((flag:flagged AND (NOT flag:replied)) OR (NOT flag:seen)) AND (NOT groff)" :key 116)
			 (:name "Today's messages"
				:query "date:today..now" :key 118)
			 (:name "Last 7 days"
				:query "date:7d..now" :hide-unread t :key 119)
			 (:name "Messages with images"
				:query "mime:image/*" :key 112)))) ; email client depends on mu command

;;; PASS
(use-package password-store
  :commands (password-store-copy
	     password-store-insert
	     password-store-generate))

;; Authenticte with auth-source-pass
(use-package auth-source-pass
  :after password-store
  :config
  (auth-source-pass-enable))
;;; Winner Mode
(use-package winner
  :ensure nil
  :bind (( "s-/" . winner-undo)
	 ( "s-?" . winner-redo)
	 ( "s-u" . winner-undo)
	 ( "s-r" . winner-redo))
  :config
  :init (winner-mode 1)) ; window managment undo

;;; MODELINE
(unless gv/is-termux
  (require 'battery))
(defun simple-mode-line-render (left right)
  "Return a string of `window-width' length.
Containing LEFT, and RIGHT aligned respectively."
  (let ((available-width
	 (- (window-total-width)
	    (+ (length (format-mode-line left))
	       (length (format-mode-line right))))))
    (append left
	    (list (format (format "%%%ds" available-width) " "))
	    right)))
(set-face-attribute 'header-line nil
		    :box '(:line-width 10 :color "#000"))
(set-face-attribute 'header-line nil
		    :background  "#0F0F0F")
(setq-default mode-line-format nil)
(setq-default left-margin-width 2)
(setq-default right-margin-width 2)
(set-window-buffer nil (current-buffer))
(setq-default header-line-format
      '((:eval
	 (format-mode-line
	  (simple-mode-line-render
	  ;; Left
	  '(" "
	    (:eval (propertize (if (buffer-modified-p) "● " "  " ) 'face 'error))
	    " %b"
	    ;; value of current line number
	    " %l:%c"
	    (:eval (propertize (concat " %p" " " (if god-local-mode " 😇 " "  ") " (%m) ") 'face 'shadow))
	    )
	  ;; Right
	  '((:eval (propertize (format-time-string "%a, %b %d %I:%M%p")'face 'font-lock-keyword-face))
	    " "
	    (:eval (unless gv/is-termux (battery-format "[%p]" (funcall battery-status-function))) )
	    "    "))))))

;;; Server Setup
(use-package server
  :ensure nil
  :defer t
  :config
  (unless (server-running-p)
    (server-start)))
;;; Extras
(use-package quelpa-use-package)
(use-package eaf
  :unless gv/is-termux
  :defer t
  :load-path "~/.emacs.d/site-lisp/emacs-application-framework" ; Set to "/usr/share/emacs/site-lisp/eaf" if installed from AUR
  :init
  (use-package epc :defer t :ensure t)
  (use-package ctable :defer t :ensure t)
  (use-package deferred :defer t :ensure t)
  (use-package s :defer t :ensure t)
  :custom
  (eaf-browser-continue-where-left-off t)
  :config
  (setq eaf-browser-default-search-engine "duckduckgo")
  (setq eaf-browser-enable-adblocker "true")
  (eaf-bind-key scroll_up "C-n" eaf-pdf-viewer-keybinding)
  (eaf-bind-key scroll_down "C-p" eaf-pdf-viewer-keybinding)
  (eaf-bind-key take_photo "p" eaf-camera-keybinding)
  (eaf-bind-key nil "M-q" eaf-browser-keybinding))

;;;; Better PDFs
;https://github.com/politza/pdf-tools
; annotate pdfs with c-c c-a
; hl with c-c c-a h
; for help M-x pdf-tools-help RET
(use-package pdf-tools
  :mode "\\.pdf\\'"
  :config
  ;; pdf auto refresh
  (add-hook 'doc-view-mode-hook 'auto-revert-mode))
(use-package transmission
  :defer t)
;;;; proced [built-in] htop alternative
(use-package proced
  :ensure nil
  :commands proced
  :config
  (setq proced-auto-update-flag t
	proced-auto-update-interval 2
	proced-decend t))
(setenv "LAUNCHER" "emenu -p ")
;;;; stuff to ignore
