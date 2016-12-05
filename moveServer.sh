c156="25.103.223.51"
c173="25.84.93.115"
c180="25.6.210.235"

#!/bin/bash
            if [ $1 = "c173" ]; then
               ip=$c173
            else
               ip=$c156
            fi


echo $ip

jsonFrom=$1.json
jsonTo=$3.json

echo $jsonFrom
echo -e $jsonTo '\n'

serverFrom=$2
serverTo=$3

#echo "Load $1 json:" $jsonFrom
echo "Move from: " $1
echo "Move to: " $3
echo -e "VM to move: " $2 '\n'

echo -e "\033[4mConnect to OpenStack systems.\033[0m"

curl --silent  -d '{"auth":{"passwordCredentials":{"username": "demo","password":"pass"},"tenantName":"demo"}}' -H "Content-Type: application/json" http://25$
echo "Get token c156"
curl --silent -d '{"auth":{"passwordCredentials":{"username": "demo","password":"pass"},"tenantName":"demo"}}' -H "Content-Type: application/json" http://25.$
echo "Get token c173"
curl --silent -d '{"auth":{"passwordCredentials":{"username": "demo","password":"pass"},"tenantName":"demo"}}' -H "Content-Type: application/json" http://25.$
echo "Get token c180"

echo "---------------------------------------------"

echo -e "\033[4mTokens.\033[0m"

v1=($(jq --raw-output '.access.token.id' c156.json))
v2=($(jq --raw-output '.access.token.id' c173.json))
v3=($(jq --raw-output '.access.token.id' c180.json))

t1=($(jq --raw-output '.access.token.tenant.id' c156.json))
t2=($(jq --raw-output '.access.token.tenant.id' c173.json))
t3=($(jq --raw-output '.access.token.tenant.id' c180.json))

token=($(jq --raw-output '.access.token.id' $jsonFrom))
tokenTo=($(jq --raw-output '.access.token.id' $jsonTo))
tenant=($(jq --raw-output '.access.token.tenant.id' $jsonFrom))

echo -e "---------------------------------------------" '\n'

echo -e "\033[4mCreate snapshot of VM.\033[0m"

clone="clone_image"
curl -s \
 -H "X-Auth-Token: $token" \
 -H "Content-Type: application/json" \
 -d '
{
"createImage": {
        "name": "clone_image",
        "metadata": {
            "meta_var": "meta_val"
        }
    }
}'\
 http://$ip:8774/v2.1/$tenant/servers/$2/action | python -mjson.tool


curl --silent -H "X-Auth-Token:$v1" http://142.150.234.156:8774/v2/2847f22c137248faab1dfdac98ced71d/images | python -m json.tool > c156_images.json
curl --silent -H "X-Auth-Token:$v2" http://25.84.93.115:8774/v2/59d05486b16b45139487bf81b50013a8/images | python -m json.tool > c173_images.json
curl --silent -H "X-Auth-Token:$v3" http://25.6.210.235:8774/v2/1cdce55a603f4059bd412700c2cf716a/images | python -m json.tool > c180_images.json

echo -e "\033[4mAvailable images.\033[0m"

#jq --raw-output '.images[].name' c156_images.json
#jq --raw-output '.images[].id' c156_images.json
#jq --raw-output '.images[].name' c173_images.json
#jq --raw-output '.images[].id' c173_images.json
#jq --raw-output '.images[].name' c180_images.json
#jq --raw-output '.images[].id' c180_images.json

#jq --raw-output '.[0].images[].name' $1_images.json
jq --raw-output '.images[].id' $1_images.json
image_id=($(jq --raw-output '.images[] | select(.name=="clone_image") | .id' $1_images.json))

#echo "Image id: "
#read image_id

echo "---------------------------------------------"
read
echo -e "\033[4mDownload VM.\033[0m"

#echo "Image id: " $image_id
#echo $ip
image_name="clone_image"

#!/bin/bash
#            if [ $1 = "c173" ]; then
#                ssh stelios@$ip 'source openrc.sh; glance image-download --file ./clone_image' $image_id
#		echo "c173"
#            else
                ssh stelios@$ip 'source openrc.sh; glance image-download --file ./'$image_name $image_id
		echo "c156"
#            fi



echo "---------------------------------------------"


echo -e "\033[4mCreate image container.\033[0m"

#echo "Delete"
#curl -X DELETE -H "X-Auth-Token: $tokenTo" http://25.6.210.235:9292/v2/images/c2173dd3-7ad6-4362-baa6-a68bce3565cf

a=($(shuf -i 10000-99999 -n 1))
ts="aadeb3c5-0bc0-4079-8d21-8d82fa9"$a
echo $ts

curl -s \
 -H "X-Auth-Token: $tokenTo" \
 -H "Content-Type: application/json" \
 -d '
{
    "container_format": "bare",
    "disk_format": "raw",
    "name":"clone-container",
    "id":"'$ts'"
}
'\
 http://25.6.210.235:9292/v2/images
echo "---------------------------------------------"
read
echo -e "\033[4mUpload VM to target OpenStack.\033[0m"

curl -i -X PUT -H "X-Auth-Token: $tokenTo" \
   -H "Content-Type: application/octet-stream" \
   -d @/home/stelios/cirros-0.3.4-x86_64-uec \
   http://25.6.210.235:9292/v2/images/$ts/file

echo "Upload done!"
read
echo "---------------------------------------------"

echo -e "\033[4mCreate new VM.\033[0m"
read

curl -s \
 -H "X-Auth-Token: $tokenTo" \
 -H "Content-Type: application/json" \
 -d '
{
    "server": {
        "name": "Clone_VM'$2'",
        "imageRef": "82deee83-e3ec-4fde-a08f-da68b7b01ae1",
        "flavorRef": "2",
        "metadata": {
            "My Server Name": "toronto",
            "key_name": "stelios"
        }
    }
}'\
 http://25.6.210.235:8774/v2.1/1cdce55a603f4059bd412700c2cf716a/servers | python -mjson.tool

