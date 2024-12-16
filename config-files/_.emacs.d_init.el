;;;;MELPA Packages
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;(package-initialize)


;;;;SLIME
;;;Multiple Lisps
(setq slime-lisp-implementations
      '((sbcl ("/usr/bin/sbcl"))
	(ccl  ("/home/ly/git-repository/ccl/lx86cl64"))))
(setq inferior-lisp-program "/home/ly/git-repository/ccl/lx86cl64")
;(setq slime-default-lisp 'ccl)

;;;Load
;(dolist (package '(slime))
;  (unless (package-installed-p package)
;    (package-install package)))
(require 'slime)
(slime-setup '(slime-fancy slime-quicklisp slime-asdf slime-mrepl))

;;;Fixed Fuzzy Completions don't close new window
(defun slime-fuzzy-window-configuration-change () nil)


;;;;COMPANY
(add-hook 'after-init-hook 'global-company-mode)


;;;;
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(company slime)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

