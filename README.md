# installscripts

## usage

curl -sfL http://localhost:8000/ansible | sh 

## installer files
structure for installer files if the source does not provide one

1. install required dependencies
ex: sudo apt update
sudo apt install ... -y

2. download the file
ex: wget --progress=bar:force -O /tmp/<filename>.deb <link>

3. install
ex: sudo dpkg -i /tmp/<filename>.deb