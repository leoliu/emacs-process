Update - 2011/04/04
----------

Yidong Chong (maintainer of Emacs) has posted a patch here:
[list-processes reimplementation, and list/menu buffers](http://article.gmane.org/gmane.emacs.devel/138093)
So list-processes will be implemented in elisp in Emacs >= 24 and thus
this package is not needed for Emacs >= 24.

Why?
----------

When M-x list-processes, I usually want to kill a stuck process. It'd
be easier to add features to list-processes if it were implemented in
elisp. See the discussion in
[emacs-devel](http://thread.gmane.org/gmane.emacs.devel/133200).

Usage:
----------

(require 'emacs-process)

NB: after loading this package the C version of list-processes is
renamed to list-processes-primitive.
