#!/bin/sh

echo ""
echo "Loading azd .env file from current environment"
echo ""

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

if [ $? -ne 0 ]; then
    echo "Failed to load environment variables from azd environment"
    exit $?
fi

cd ../
echo 'Creating python virtual environment ".venv"'
python3 -m venv .venv

echo ""
echo "Restoring python packages"
echo ""

./.venv/bin/python -m pip install -r app/requirements.txt

if [ $? -ne 0 ]; then
    echo "Failed to restore backend python packages"
    exit $?
fi

cd app

../.venv/bin/python -m streamlit run app.py

if [ $? -ne 0 ]; then
    echo "Failed to start backend"
    exit $?
fi