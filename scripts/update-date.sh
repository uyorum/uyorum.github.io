#!/bin/bash

git ls-files --others --exclude-standard | grep -P '.*\.md$' | xargs sed -i "s/^date = .*/date = \"$(date --iso-8601=seconds)\"/"
