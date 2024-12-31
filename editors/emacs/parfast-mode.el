(defconst parfast-mode-syntax-table
  (with-syntax-table (copy-syntax-table)
	(modify-syntax-entry ?/ ". 124b")
	(modify-syntax-entry ?* ". 23")
	(modify-syntax-entry ?\n "> b")
    (modify-syntax-entry ?' "\"")
    (syntax-table))
  "Syntax table for `parfast-mode'")

(eval-and-compile
  (defconst parfast-keys
    '("if" "else" "while" "do" "include" "end" "macro" "endm" "call" "extern" "then" "elseif")))

(defconst parfast-h
  `((,(regexp-opt parfast-keys 'symbols) . font-lock-keyword-face)))

(define-derived-mode parfast-mode fundamental-mode "parfast"
  "major mode for editing parfast code"
  :syntax-table parfast-mode-syntax-table
  (setq font-lock-defaults '(parfast-h))
  (setq-local comment-start "// "))
(add-to-list 'auto-mode-alist '("\\.parfast\\'" . parfast-mode))
(provide 'parfast-mode)