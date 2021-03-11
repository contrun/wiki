# Build instructions

```bash
emacs --batch -l publish.el --eval "(publish-all)"
git submodule update --recursive --init
hugo
```
