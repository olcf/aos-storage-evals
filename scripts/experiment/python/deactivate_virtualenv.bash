# source this
if [ -n "$AOS_PYTHON_VIRTUAL_ENV_DIR" ]; then
    [[ $(type -t deactivate) == "function" ]] && deactivate
fi