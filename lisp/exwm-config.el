(use-package exwm
  :unless my/is-termux
  :ensure t
  :init
  (setq exwm-workspace-number 2)
  :config
  (setq exwm-manage-force-tiling t)
 ;;;; Hooks
  (defun my/exwm-titles ()
    (pcase exwm-class-name
      ("qutebrowser" (exwm-workspace-rename-buffer (format "%s" exwm-title)))
      ("mpv" (exwm-workspace-rename-buffer (format "%s" exwm-title)))
      ("libreoffice-writer" (exwm-workspace-rename-buffer (format "Writer: %s" exwm-title)))
      ("libreoffice-calc" (exwm-workspace-rename-buffer (format "Calc: %s" exwm-title)))
      ("St" (exwm-workspace-rename-buffer (format "%s" exwm-title)))))

  (add-hook 'exwm-update-class-hook
            (lambda ()
              (exwm-workspace-rename-buffer exwm-class-name)))

  (add-hook 'exwm-update-title-hook #'my/exwm-titles)

  ;; Hide the mode-line on all floating X windows
  (add-hook 'exwm-floating-setup-hook
            (lambda ()
              (exwm-layout-hide-mode-line)))
;;;; Functions
;;;; Global Key Bindings
  (add-hook 'exwm-manage-finish-hook
            (lambda ()
              (when (and exwm-class-name
                         (or (string= exwm-class-name "Google-chrome")
                             (string= exwm-class-name "discord")))
                (exwm-input-set-local-simulation-keys `(([?\C-b] . [left])
							([?\C-f] . [right])
                                                        ([?\M-b] . ,(kbd "C-<left>"))
                                                        ([?\M-f] . ,(kbd "C-<right>"))
                                                        ([?\M-d] . ,(kbd "C-<delete>"))
                                                        ([?\C-p] . [up])
                                                        ([?\C-n] . [down])
                                                        ([?\C-a] . [home])
                                                        ([?\C-j] . [?\C-k])
                                                        ([?\C-s] . [?\C-f])
                                                        ([?\C-e] . [end])
                                                        (,(kbd "C-S-E") . [?\C-e])
                                                        ([?\M-v] . [prior])
                                                        ([?\C-v] . [next])
							([?\C-d] . [delete])
                                                        ([?\C-k] . [S-end delete])
                                                        (,(kbd "C-y") . ,(kbd "C-v"))
                                                        (,(kbd "C-x C-x") . ,(kbd "C-x"))
                                                        (,(kbd "C-c C-c") . ,(kbd "C-c")))))))

  (defmacro my/window-switch (direction)
    "Creates a function for changing the focused window but falls
back to switching frames."
    (let ((fn (intern (concat "windmove-" (symbol-name direction)))))
      `(lambda (&optional arg) (interactive)
         (condition-case nil
             (funcall #',fn 1)
           (error (other-frame 1))))))

  (defmacro my/window-swap (direction)
    "Creates a function for changing the focused window but falls
back to switching frames."
    (let ((fn (intern (concat "windmove-swap-states-" (symbol-name direction)))))
      `(lambda (&optional arg) (interactive)
         (condition-case nil
             (funcall #',fn)
           (error (other-frame 1))))))

  (defmacro my/exwm-run (command)
    "Returns a function that calls the given command"
    `(lambda (&optional arg)
       (interactive)
       (start-process-shell-command ,command nil ,command)))
  (cl-defmacro exwm-bind (&rest pairs)
    (cl-loop for (key . func) in pairs
             collect `(cons (kbd ,key) . (quote ,func))))

  (setq exwm-input-global-keys
        ;; Window Managment
        `((,(kbd "s-SPC") . ,(my/exwm-run "cabl -c"))
          ([?\s-h] . ,(my/window-switch left))
          ([?\s-l] . ,(my/window-switch right))
          ([?\s-j] . windmove-down)
          ([?\s-k] . windmove-up)
          (,(kbd "s-H") . windmove-swap-states-left)
          (,(kbd "s-L") . ,(my/window-swap right))
          (,(kbd "s-J") . ,(my/window-swap down))
          (,(kbd "s-K") . ,(my/window-swap up))
          (,(kbd "<s-tab>") . other-window)
          ([?\s-v] . crux-swap-windows)
          ([?\s-o] . other-frame)
          ([?\s-f] . exwm-layout-set-fullscreen)
          ([?\s-c] . inferior-octave)
          ([?\s-C] . kill-this-buffer)
          ;; tile exwm
          ([?\s-t] . exwm-reset)

          ;; open a terminal
          (,(kbd "<s-return>") . vterm)
          ;; launch any program
          ([?\s-d] . (lambda (command)
                       (interactive (list (read-shell-command "λ ")))
                       (start-process-shell-command command nil command)))
          ;; Screen And Audio Controls
          (,(kbd "C-s-f")   . ,(my/exwm-run "cm up 5"))
          (,(kbd "C-s-a")   . ,(my/exwm-run "cm down 5"))
          (,(kbd "C-s-d")   . ,(my/exwm-run "xbacklight -inc 10"))
          (,(kbd "C-s-S-d") . ,(my/exwm-run "xbacklight -inc 5"))
          (,(kbd "C-s-s")   . ,(my/exwm-run  "xbacklight -dec 10"))
          (,(kbd "C-s-S-s") . ,(my/exwm-run  "xbacklight -dec 5"))
          ;; Web Browser
          ([?\s-w] . ,(my/exwm-run "ducksearch"))
          ;;Power Manager
          ([?\s-x] . ,(my/exwm-run  "power_menu.sh"))
          ([?\s-m] . (defun remind-timer (reminder)
                       (interactive "reminder?")
                       (egg-timer-do-schedule 3 reminder)))
          ([?\s-=] . ,(my/exwm-run "menu_connection_manager.sh"))
          ([?\s-p] . ,(my/exwm-run "clipmenu"))
          ;; Workspaces
          ([?\s-g] . exwm-workspace-switch)))
  (define-key exwm-mode-map (kbd "C-q") 'exwm-input-send-next-key)
  (define-key exwm-mode-map (kbd "<s-escape>") 'exwm-input-release-keyboard)

  (require 'exwm)
;;;; Start EXWM
;;;; Start Programs For EXWM
  (exwm-enable))

;; Broken on current version of emacs
;; (use-package exwm-systemtray
;;   :ensure nil
;;   :after exwm
;;   :config
;;   (exwm-systemtray-enable)
;;   (start-process-shell-command "blueman-applet" nil "blueman-applet")
;;   (start-process-shell-command "nm-applet" nil "nm-applet")
;;   (start-process-shell-command "kdeconnect-indicator " nil "kdeconnect-indicator")
;;   (setq exwm-systemtray-height 23))

(use-package exwm-randr
  :ensure nil
  ;; :after exwm
  :demand t
  :config
  (setq exwm-randr-workspace-output-plist '(1 "DP2"))
  (add-hook 'exwm-randr-screen-change-hook
            (lambda ()
              (start-process-shell-command
               "xrandr" nil "xrandr --output eDP1 --primary --auto --right-of DP2 --auto")))
  (exwm-randr-enable))

;;; Streaming
;; Needs OBS-Websockets Plugin
;;   https://obsproject.com/forum/resources/obs-websocket-remote-control-obs-studio-from-websockets.466/
;; Also will need this emacs package
;;   https://github.com/sachac/obs-websocket-el


;;; Override Pinentry For Pass To Avoid Locking Up Emacs
(use-package pinentry
  :ensure t
  :init
  :config
  ;; let's get encryption established
  (setenv "GPG_AGENT_INFO" nil)  ;; use emacs pinentry
  (setq auth-source-debug t)

  (setq epg-gpg-program "gpg2")  ;; not necessary
  (require 'epa-file)
  (epa-file-enable)
  (setq epa-pinentry-mode 'loopback)
  (setq epg-pinentry-mode 'loopback)
  (pinentry-start)

  (require 'org-crypt)
  (org-crypt-use-before-save-magic))
