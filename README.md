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
