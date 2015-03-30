#!/bin/bash
set -eu
git pull
git submodule foreach 'git pull'
