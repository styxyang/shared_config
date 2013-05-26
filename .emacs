;; General settings
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(setq tool-bar-mode nil)
;; (menu-bar-mode -1)
(show-paren-mode t)
(setq display-time-day-and-date t)
(setq display-time-24hr-format t)
(display-time)

;; smooth scrolling
(setq scroll-margin 10)
(setq scroll-step 1)

(setq read-file-name-completion-ignore-case t) ; Set find-file to be case insensitive

(setq initial-frame-alist
      `((height . 60)
	(width . 150)
	(top . 50)
	(left . 400)))
(add-to-list 'default-frame-alist
	     '(font . "Inconsolata-14"))
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
(setq backup-by-copyting t
      backup-directory-alist
      '(("." . "~/.saves"))
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

;; append perlbrew path to environment variable
(setenv "PATH"
	(concat "~/.pb/perls/perl-5.16-thread/bin:"
		(getenv "PATH")))
(setq exec-path (split-string (getenv "PATH") ":"))

;; elpa settings
;; (add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
;; (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
			 ("marmalade" . "http://marmalade-repo.org/packages/")
			 ("melpa" . "http://melpa.milkbox.net/packages/")))

(add-to-list 'load-path "~/.emacs.d/elpa/")
(let ((default-directory "~/.emacs.d/elpa/"))
  (normal-top-level-add-subdirs-to-load-path))

;; git.el - official git package
;; (add-to-list 'load-path "/usr/local/share/git-core/contrib/emacs")
;; (require 'git)

;; ;; bookmark+
;; (add-to-list 'load-path "~/.emacs.d/elpa/bookmark+-20130317.1522")
;; (require 'bookmark+)

;; VIM-like powerline
(add-to-list 'load-path "~/.emacs.d/powerline")
(require 'powerline)
(when window-system
  (set-face-attribute 'mode-line nil
  		      :background "OliveDrab3")
  (powerline-default-theme))

;; hl-line-mode
(require 'hl-line)
(when window-system
  (global-hl-line-mode t))

;; ido-mode
(require 'ido)
(ido-mode t)
(setq ido-decorations (quote ("\n-> " "" "\n   " "\n   ..." "[" "]" " [No match]" " [Matched]" " [Not readable]" " [Too big]" " [Confirm]"))) ; Display ido results vertically, rather than horizontally
(defun ido-disable-line-truncation () (set (make-local-variable 'truncate-lines) nil))
(add-hook 'ido-minibuffer-setup-hook 'ido-disable-line-truncation)
(global-set-key (kbd "M-i") 'ido-goto-symbol)
(global-set-key (kbd "C-x C-b") 'ido-switch-buffer)
(global-set-key (kbd "C-x b") 'list-buffers)
;; (global-set-key (kbd "C-x C-b") 'list-buffers)
;; (global-set-key (kbd "C-x b") 'ido-switch-buffer)
(defun ido-goto-symbol (&optional symbol-list)
  "Refresh imenu and jump to a place in the buffer using Ido."
  (interactive)
  (unless (featurep 'imenu)
	  (require 'imenu nil t))
  (cond
   ((not symbol-list)
    (let ((ido-mode ido-mode)
	  (ido-enable-flex-matching
	   (if (boundp 'ido-enable-flex-matching)
	       ido-enable-flex-matching t))
	  name-and-pos symbol-names position)
      (unless ido-mode
	      (ido-mode 1)
	      (setq ido-enable-flex-matching t))
      (while (progn
	      (imenu--cleanup)
	      (setq imenu--index-alist nil)
	      (ido-goto-symbol (imenu--make-index-alist))
	      (setq selected-symbol
		    (ido-completing-read "Symbol? " symbol-names))
	      (string= (car imenu--rescan-item) selected-symbol)))
      (unless (and (boundp 'mark-active) mark-active)
	      (push-mark nil t nil))
      (setq position (cdr (assoc selected-symbol name-and-pos)))
      (cond
       ((overlayp position)
	(goto-char (overlay-start position)))
       (t
	(goto-char position)))))
   ((listp symbol-list)
    (dolist (symbol symbol-list)
	    (let (name position)
	      (cond
	       ((and (listp symbol) (imenu--subalist-p symbol))
		(ido-goto-symbol symbol))
	       ((listp symbol)
		(setq name (car symbol))
		(setq position (cdr symbol)))
	       ((stringp symbol)
		(setq name symbol)
		(setq position
		      (get-text-property 1 'org-imenu-marker symbol))))
	      (unless (or (null position) (null name)
			  (string= (car imenu--rescan-item) name))
		      (add-to-list 'symbol-names name)
		      (add-to-list 'name-and-pos (cons name position))))))))

(defvar smart-use-extended-syntax nil
  "If t the smart symbol functionality will consider extended
syntax in finding matches, if such matches exist.")

(defvar smart-last-symbol-name ""
  "Contains the current symbol name.

This is only refreshed when `last-command' does not contain
either `smart-symbol-go-forward' or `smart-symbol-go-backward'")

(make-local-variable 'smart-use-extended-syntax)

(defvar smart-symbol-old-pt nil
  "Contains the location of the old point")

(defun smart-symbol-goto (name direction)
  "Jumps to the next NAME in DIRECTION in the current buffer.

DIRECTION must be either `forward' or `backward'; no other option
is valid."

  ;; if `last-command' did not contain
  ;; `smart-symbol-go-forward/backward' then we assume it's a
  ;; brand-new command and we re-set the search term.
  (unless (memq last-command '(smart-symbol-go-forward
                               smart-symbol-go-backward))
    (setq smart-last-symbol-name name))
  (setq smart-symbol-old-pt (point))
  (message (format "%s scan for symbol \"%s\""
                   (capitalize (symbol-name direction))
                   smart-last-symbol-name))
  (unless (catch 'done
            (while (funcall (cond
                             ((eq direction 'forward) ; forward
                              'search-forward)
                             ((eq direction 'backward) ; backward
                              'search-backward)
                             (t (error "Invalid direction"))) ; all others
                            smart-last-symbol-name nil t)
              (unless (memq (syntax-ppss-context
                             (syntax-ppss (point))) '(string comment))
                (throw 'done t))))
    (goto-char smart-symbol-old-pt)))

(defun smart-symbol-go-forward ()
  "Jumps forward to the next symbol at point"
  (interactive)
  (smart-symbol-goto (smart-symbol-at-pt 'end) 'forward))

(defun smart-symbol-go-backward ()
  "Jumps backward to the previous symbol at point"
  (interactive)
  (smart-symbol-goto (smart-symbol-at-pt 'beginning) 'backward))

(defun smart-symbol-at-pt (&optional dir)
  "Returns the symbol at point and moves point to DIR (either `beginning' or `end') of the symbol.

If `smart-use-extended-syntax' is t then that symbol is returned
instead."
  (with-syntax-table (make-syntax-table)
    (if smart-use-extended-syntax
        (modify-syntax-entry ?. "w"))
    (modify-syntax-entry ?_ "w")
    (modify-syntax-entry ?- "w")
    ;; grab the word and return it
    (let ((word (thing-at-point 'word))
          (bounds (bounds-of-thing-at-point 'word)))
      (if word
          (progn
            (cond
             ((eq dir 'beginning) (goto-char (car bounds)))
             ((eq dir 'end) (goto-char (cdr bounds)))
             (t (error "Invalid direction")))
            word)
        (error "No symbol found")))))

(global-set-key (kbd "M-n") 'smart-symbol-go-forward)
(global-set-key (kbd "M-p") 'smart-symbol-go-backward)

;; speedbar
;; (when window-system
;;   (require 'sr-speedbar))
;; (setq speedbar-show-unknown-files t)
;; (setq sr-speedbar-right-side nil)
;; ;; (custom-set-variables '(sr-speedbar-right-side nil) '(sr-speedbar-skip-other-window-p t) '(sr-speedbar-max-width 30) '(sr-speedbar-width-x 30))
;; (setq sr-speedbar-width 16)
;; (setq sr-speedbar-width-x 16)
;; (setq sr-speedbar-skip-other-window-p t)
;; (setq speedbar-frame-parameters (quote
;; 				 ((minibuffer)
;; 				  (width . 20)
;; 				  (border-width . 0)
;; 				  (menu-bar-lines . 0)
;; 				  (tool-bar-lines . 0)
;; 				  (unsplittable . t)
;; 				  (left-fringe . 0))))
;; (sr-speedbar-open);

;; tmtheme & themes
;; (require 'tmtheme)
;; (setq tmtheme-directory "~/.emacs.d/tmthemes")
;; (tmtheme-scan)
;; (when window-system
;;   (tmtheme-Monokai))

(add-to-list 'custom-theme-load-path "~/.emacs.d/elpa/monokai-theme-0.0.10")
(load-theme 'monokai t)

;; yasnippet
;; (require 'yasnippet)
;; (yas-global-mode 1)
;; (defun yas-ido-expand ()
;;   "Lets you select (and expand) a yasnippet key"
;;   (interactive)
;;     (let ((original-point (point)))
;;       (while (and
;;               (not (= (point) (point-min) ))
;;               (not
;;                (string-match "[[:space:]\n]" (char-to-string (char-before)))))
;;         (backward-word 1))
;;     (let* ((init-word (point))
;;            (word (buffer-substring init-word original-point))
;;            (list (yas-active-keys)))
;;       (goto-char original-point)
;;       (let ((key (remove-if-not
;;                   (lambda (s) (string-match (concat "^" word) s)) list)))
;;         (if (= (length key) 1)
;;             (setq key (pop key))
;;           (setq key (ido-completing-read "key: " list nil nil word)))
;;         (delete-char (- init-word original-point))
;;         (insert key)
;;         (yas-expand)))))
;; (define-key yas-minor-mode-map (kbd "<C-tab>") 'yas-ido-expand)


;; (add-to-list 'load-path "~/.emacs.d/tomorrow-theme/GNU Emacs")
;; (add-to-list 'custom-theme-load-path "~/.emacs.d/tomorrow-theme/GNU Emacs/")
;; (require 'color-theme-tomorrow)
;; (load-theme 'tomorrow- t)

;; (when window-system
;;   (require 'solarized)
;;   (load-theme 'solarized-dark t))


;; (font-lock-add-keywords 'c-mode '(("\\(\\w+\\)\\s-*\(" . font-lock-function-name-face)))
;; (font-lock-add-keywords 'c-mode '(("if" . font-lock-keyword-face)))
;; (font-lock-add-keywords 'c-mode '(("for" . font-lock-keyword-face)))
;; (font-lock-add-keywords 'c-mode '(("while" . font-lock-keyword-face)))
(global-font-lock-mode t)

;; (when (and (fboundp 'semantic-mode)
;;            (not (locate-library "semantic-ctxt"))) ; can't found offical cedet
;;       (setq semantic-default-submodes '(global-semantic-idle-scheduler-mode
;; 					global-semanticdb-minor-mode
;; 					global-semantic-idle-summary-mode
;; 					global-semantic-mru-bookmark-mode)))
;; (semantic-mode 1)
;; (require 'semantic/ctxt)
;; (add-to-list 'load-path "~/.emacs.d/elpa/highlight-21.0")
;; (require 'zjl-hl)
;; ;
;;(zjl-hl-enable-global-all-modes)

;; (zjl-hl-enable-global 'c-mode);; (zjl-hl-disable-global 'c-mode)

;; (zjl-hl-enable-global 'emacs-lisp-mode);; (zjl-hl-disable-global 'emacs-lisp-mode)


;; auto-complete
(add-to-list 'load-path "~/.emacs.d/auto-complete")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/auto-complete/ac-dict")
(ac-config-default)

;; cursor-mode
;; (setq-default cursor-type 'hbar)
(blink-cursor-mode -1)
;; (require 'cursor-chg)
;; (change-cursor-mode t)
;; (toggle-cursor-type-when-idle t)

;; xcscope
(add-to-list 'load-path "~/.emacs.d/xcscope")
(require 'xcscope)

;; eshell
(setq eshell-cmpl-ignore-case t)
(add-hook 'eshell-mode-hook
	  (lambda ()
	    (define-key eshell-mode-map (kbd "C-g") 'delete-window)))


;; Key bindings
;; (setq mac-command-modifier 'meta)
;; (setq mac-option-modifier nil)
;; (global-set-key [f1] 'term) ;; instead of shell
(global-set-key [f1] 'eshell)
(global-set-key (kbd "C-,") 'beginning-of-buffer)
(global-set-key (kbd "C-.") 'end-of-buffer)
(global-set-key [f5] 'revert-buffer)
(global-set-key [f8] 'sr-speedbar-toggle)
(global-set-key [f11] 'ns-toggle-fullscreen)
(defun my-fullscreen ()
  (interactive)
  (x-send-client-message
   nil 0 nil "_NET_WM_STATE" 32
   '(2 "_NET_WM_STATE_FULLSCREEN" 0))
)

(defun push-mark-no-activate ()
  "Pushes `point' to `mark-ring' and does not activate the region
Equivalent to \\[set-mark-command] when \\[transient-mark-mode] is disabled"
  (interactive)
  (push-mark (point) t nil)
  (message "Pushed mark to ring"))
(global-set-key (kbd "C-`") 'push-mark-no-activate)

(defun jump-to-mark ()
  "Jumps to the local mark, respecting the `mark-ring' order.
This is the same as using \\[set-mark-command] with the prefix argument."
  (interactive)
  (set-mark-command 1))
(global-set-key (kbd "M-`") 'jump-to-mark)


;; markdown-mode
(add-to-list 'load-path "~/.emacs.d/markdown-mode")
(require 'markdown-mode)
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-hook 'markdown-mode-hook
          (function
           (lambda ()
             (setq tab-width 4
		   indent-tabs-mode nil)
	     )))
(add-hook 'markdown-mode-hook
          (function
           (lambda ()
	     (local-set-key (kbd "<tab>") 'markdown-insert-pre)
	     )))

(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(require 'org-install)
(setq org-todo-keywords
       '((sequence "TODO(t)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELED(c@)")))
(defun org-summary-todo (n-done n-not-done)
       "Switch entry to DONE when all subentries are done, to TODO otherwise."
       (let (org-log-done org-log-states)   ; turn off logging
         (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

;; linum-mode
(global-linum-mode 1)
;; seperate line numbers from text
(setq linum-format
      (lambda (line)
	(propertize (format
		     (let ((w (length (number-to-string
				       (count-lines (point-min) (point-max))))))
		       (concat " %" (number-to-string w) "d ")) line) 'face 'linum)))
(column-number-mode 1)

;; slime-mode
;; (setq inferior-lisp-program "/opt/sbcl/bin/sbcl") ; your Lisp system
;; (require 'slime)
;; (slime-setup)

;; gambit - emacs interface
;; (autoload 'gambit-inferior-mode "gambit" "Hook Gambit mode into cmuscheme.")
;; (autoload 'gambit-mode "gambit" "Hook Gambit mode into scheme.")
;; (add-hook 'inferior-scheme-mode-hook (function gambit-inferior-mode))
;; (add-hook 'scheme-mode-hook (function gambit-mode))
(setq scheme-program-name "/usr/local/bin/scheme --emacs")

;; (require 'gambit)

(add-to-list 'load-path "~/.emacs.d/zencoding")
(require 'zencoding-mode)
(add-hook 'sgml-mode-hook 'zencoding-mode)

;; emacs -nw:  emacs in terminal
;; map RET to [return] in terminal mode, fix `ret` in cscope jumping
(let ((map (if (boundp 'input-decode-map)
	       input-decode-map function-key-map)))
  (define-key map (kbd "RET") [return]))


(require 'google-c-style)
(add-hook 'c-mode-common-hook 'google-set-c-style)
(add-hook 'c-mode-common-hook 'google-make-newline-indent)
;; Linux Kernel Coding Style
;; (defun c-lineup-arglist-tabs-only (ignored)
;;   "Line up argument lists by tabs, not spaces"
;;   (let* ((anchor (c-langelem-pos c-syntactic-element))
;; 	 (column (c-langelem-2nd-pos c-syntactic-element))
;; 	 (offset (- (1+ column) anchor))
;; 	 (steps (floor offset c-basic-offset)))
;;     (* (max steps 1)
;;        c-basic-offset)))

;; cperl-mode
(defalias 'perl-mode 'cperl-mode)

(when window-system
  ;; (setq server-host "styx-mbp")
  ;; (setq server-use-tcp t)
  (server-start))
;; (add-hook 'c-mode-common-hook
;;           (lambda ()
;;             ;; Add kernel style
;;             (c-add-style
;;              "linux-tabs-only"
;;              '("linux" (c-offsets-alist
;;                         (arglist-cont-nonempty
;;                          c-lineup-gcc-asm-reg
;;                          c-lineup-arglist-tabs-only))))))

;; (add-hook 'c-mode-hook
;;           (lambda ()
;;             (let ((filename (buffer-file-name)))
;;               ;; Enable kernel mode for the appropriate files
;;               (when (and filename
;;                          (string-match (expand-file-name "~/asgard/summerpj")
;;                                        filename))
;;                 (setq indent-tabs-mode t)
;;                 (c-set-style "linux-tabs-only")))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ido-max-window-height 15)
 '(split-height-threshold 120)
 '(tool-bar-mode nil))
