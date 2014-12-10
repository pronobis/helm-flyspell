helm-flyspell
=============

Helm extension for correcting words with Flyspell.

To use, just put your cursor on or after the misspelled word and run `helm-flyspell-correct`. You can of course bind it to a key as well by adding this to your `~/.emacs` file:
```
(define-key flyspell-mode-map (kbd "C-;") 'helm-flyspell-correct)
```

Thanks
------

Thanks go to [Michael Markert](https://github.com/cofi) for the inspiration and his original [helm-flyspell-correct](https://gist.github.com/cofi/3013327) code.
