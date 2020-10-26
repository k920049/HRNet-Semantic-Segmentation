USER_DATA=`base64 user_data_script.sh -w0`
sed -i '' "s|base64_encoded_bash_script|$USER_DATA|g" spot_fleet_config.json
