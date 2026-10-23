# USAGE: set AOS_PYTHON_VIRTUAL_ENV_DIR and then source this script
if [ -n "$AOS_PYTHON_VIRTUAL_ENV_DIR" ]; then
    if [ -f $AOS_PYTHON_VIRTUAL_ENV_DIR/bin/activate ]; then
        source $AOS_PYTHON_VIRTUAL_ENV_DIR/bin/activate
    fi
fi