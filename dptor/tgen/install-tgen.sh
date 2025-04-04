cd  /app/

git clone https://github.com/shadow/tgen.git 

cd tgen 

mkdir build && cd build 

cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local 

make install

